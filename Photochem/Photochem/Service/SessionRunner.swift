import Foundation
import SwiftData

enum RunnerState: Equatable {
    case preparing(stageIndex: Int)
    case running(stageIndex: Int, startedAt: Date, endDate: Date, preAlertFired: Bool)
    case finished
}

@MainActor
@Observable
final class SessionRunner {
    private(set) var state: RunnerState = .preparing(stageIndex: 0)

    let session: DevelopmentSession

    private let stages: [StageSnapshot]
    private let soundService: SoundService
    private let notificationService: NotificationService
    private let modelContext: ModelContext

    init(
        session: DevelopmentSession,
        soundService: SoundService,
        notificationService: NotificationService,
        modelContext: ModelContext
    ) {
        self.session = session
        self.stages = session.orderedStages
        self.soundService = soundService
        self.notificationService = notificationService
        self.modelContext = modelContext
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
        case .running(let stageIndex, _, _, _): stageIndex
        case .finished: nil
        }
    }

    func start(now: Date = .now) {
        guard case .preparing(let stageIndex) = state, let stage = stage(at: stageIndex) else {
            return
        }
        let endDate = now.addingTimeInterval(TimeInterval(stage.plannedSeconds))
        state = .running(stageIndex: stageIndex, startedAt: now, endDate: endDate, preAlertFired: false)
        notificationService.scheduleStageAlerts(
            sessionID: session.id,
            stageIndex: stageIndex,
            stageName: stage.name,
            preAlertAt: isPreAlertApplicable(stage) ? endDate.addingTimeInterval(-TimeInterval(stage.preAlertSeconds)) : nil,
            endAt: endDate
        )
    }

    func tick(now: Date) {
        guard case .running(let stageIndex, let startedAt, let endDate, let preAlertFired) = state,
              let stage = stage(at: stageIndex) else {
            return
        }

        if now >= endDate {
            if now.timeIntervalSince(endDate) <= 3 {
                soundService.playStageEnd()
            }
            notificationService.cancelStageAlerts(sessionID: session.id, stageIndex: stageIndex)
            state = stageIndex + 1 < stages.count ? .preparing(stageIndex: stageIndex + 1) : .finished
            return
        }

        let preAlertDate = endDate.addingTimeInterval(-TimeInterval(stage.preAlertSeconds))
        if !preAlertFired, isPreAlertApplicable(stage), now >= preAlertDate {
            soundService.playPreAlert()
            state = .running(stageIndex: stageIndex, startedAt: startedAt, endDate: endDate, preAlertFired: true)
        }
    }

    func remainingSeconds(now: Date) -> Int {
        guard case .running(_, _, let endDate, _) = state else {
            return 0
        }
        return max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
    }

    func abort() {
        notificationService.cancelAll(sessionID: session.id, stageCount: stages.count)
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

    private func isPreAlertApplicable(_ stage: StageSnapshot) -> Bool {
        stage.plannedSeconds > stage.preAlertSeconds + 2
    }
}
