import Foundation
import PhotochemCore
import SwiftData

enum RunnerState: Equatable {
    case preparing(stageIndex: Int)
    case running(stageIndex: Int, startedAt: Date, endDate: Date, preAlertFired: Bool, nextTickAt: Date?)
    case finished
}

@MainActor
@Observable
final class SessionRunner {
    private(set) var state: RunnerState = .preparing(stageIndex: 0)

    let session: DevelopmentSession

    private let stages: [StageSnapshot]
    private let geigerCurve: GeigerCurve
    private let alertService: AlertService
    private let notificationService: NotificationService
    private let liveActivityService: LiveActivityService
    private let modelContext: ModelContext

    init(
        session: DevelopmentSession,
        geigerCurve: GeigerCurve,
        alertService: AlertService,
        notificationService: NotificationService,
        liveActivityService: LiveActivityService,
        modelContext: ModelContext
    ) {
        self.session = session
        self.stages = session.orderedStages
        self.geigerCurve = geigerCurve
        self.alertService = alertService
        self.notificationService = notificationService
        self.liveActivityService = liveActivityService
        self.modelContext = modelContext
    }

    func startLiveActivity() async {
        guard let stage = stage(at: 0) else {
            return
        }

        await liveActivityService.start(
            processName: session.kit?.processName ?? "",
            totalStages: stages.count,
            state: DevelopmentActivityAttributes.ContentState(
                stageIndex: 0,
                stageName: stage.name,
                phase: DevelopmentActivityPhase.preparing,
                endDate: nil
            )
        )
    }

    var stageCount: Int {
        stages.count
    }

    func stage(at index: Int) -> StageSnapshot? {
        stages.indices.contains(index) ? stages[index] : nil
    }

    var currentStageIndex: Int? {
        switch state {
            case .preparing(let stageIndex): stageIndex
            case .running(let stageIndex, _, _, _, _): stageIndex
            case .finished: nil
        }
    }

    func start(now: Date = .now) {
        guard case .preparing(let stageIndex) = state, let stage = stage(at: stageIndex) else {
            return
        }
        let endDate = now.addingTimeInterval(TimeInterval(stage.plannedSeconds))
        state = .running(stageIndex: stageIndex, startedAt: now, endDate: endDate, preAlertFired: false, nextTickAt: nil)
        notificationService.scheduleStageAlerts(
            sessionID: session.id,
            stageIndex: stageIndex,
            stageName: stage.name,
            preAlertAt: isPreAlertApplicable(stage) ? endDate.addingTimeInterval(-TimeInterval(stage.preAlertSeconds)) : nil,
            endAt: endDate
        )
        publishActivityState(stageIndex: stageIndex, phase: DevelopmentActivityPhase.running, endDate: endDate)
    }

    func tick(now: Date) {
        guard case .running(let stageIndex, let startedAt, let endDate, let preAlertFired, let nextTickAt) = state,
              let stage = stage(at: stageIndex) else {
            return
        }

        if now >= endDate {
            if now.timeIntervalSince(endDate) <= 3 {
                alertService.playStageEnd()
            }
            notificationService.cancelStageAlerts(sessionID: session.id, stageIndex: stageIndex)
            state = stageIndex + 1 < stages.count ? .preparing(stageIndex: stageIndex + 1) : .finished
            if case .preparing(let nextIndex) = state {
                publishActivityState(stageIndex: nextIndex, phase: DevelopmentActivityPhase.preparing, endDate: nil)
            } else {
                Task { await liveActivityService.stop() }
            }
            return
        }

        let windowStart = endDate.addingTimeInterval(-TimeInterval(stage.preAlertSeconds))
        guard isPreAlertApplicable(stage), now >= windowStart else {
            return
        }

        // Не больше одного сигнала за тик: сначала предупик, пики — со следующего.
        if !preAlertFired {
            alertService.playPreAlert()
        } else if let nextTickAt, now >= nextTickAt {
            alertService.playTick()
        } else {
            return
        }

        let remaining = endDate.timeIntervalSince(now)
        state = .running(
            stageIndex: stageIndex,
            startedAt: startedAt,
            endDate: endDate,
            preAlertFired: true,
            nextTickAt: now.addingTimeInterval(geigerCurve.interval(remaining: remaining))
        )
    }

    func remainingSeconds(now: Date) -> Int {
        guard case .running(_, _, let endDate, _, _) = state else {
            return 0
        }
        return max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
    }

    func abort() {
        notificationService.cancelAll(sessionID: session.id, stageCount: stages.count)
        Task { await liveActivityService.stop() }
        finish(status: .aborted)
    }

    func complete() {
        finish(status: .completed)
    }

    private func finish(status: SessionStatus) {
        session.status = status
        session.finishedAt = .now
        try? modelContext.save()
    }

    private func publishActivityState(stageIndex: Int, phase: String, endDate: Date?) {
        guard let stage = stage(at: stageIndex) else {
            return
        }
        let state = DevelopmentActivityAttributes.ContentState(
            stageIndex: stageIndex,
            stageName: stage.name,
            phase: phase,
            endDate: endDate
        )
        Task { await liveActivityService.update(state: state) }
    }

    private func isPreAlertApplicable(_ stage: StageSnapshot) -> Bool {
        stage.plannedSeconds > stage.preAlertSeconds + 2
    }
}
