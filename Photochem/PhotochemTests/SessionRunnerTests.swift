import Foundation
import PhotochemCore
import SwiftData
import Testing
@testable import Photochem

@MainActor
struct SessionRunnerTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("R1")
    func startsFirstStage() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        #expect(context.runner.state == .running(
            stageIndex: 0,
            startedAt: start,
            endDate: start.addingTimeInterval(100),
            preAlertFired: false,
            nextTickAt: nil
        ))
    }

    @Test("R2")
    func doesNotFirePreAlertTooEarly() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(89))
        #expect(context.sound.preAlertCount == 0)
    }

    @Test("R3")
    func firesPreAlertOnce() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(90))
        context.runner.tick(now: start.addingTimeInterval(91))
        #expect(context.sound.preAlertCount == 1)
    }

    @Test("R4")
    func advancesToNextStageAtEnd() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(100))
        #expect(context.sound.stageEndCount == 1)
        #expect(context.runner.state == .preparing(stageIndex: 1))
        #expect(context.notifications.cancelledStages == [0])
    }

    @Test("R5")
    func skipsLateStageEndSound() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(160))
        #expect(context.runner.state == .preparing(stageIndex: 1))
        #expect(context.sound.stageEndCount == 0)
    }

    @Test("R6")
    func finishesAfterLastStage() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(100))
        let secondStart = start.addingTimeInterval(200)
        context.runner.start(now: secondStart)
        context.runner.tick(now: secondStart.addingTimeInterval(60))
        #expect(context.runner.state == .finished)
    }

    @Test("R7")
    func skipsPreAlertOnShortStage() throws {
        let context = try makeRunner(stageSeconds: [8], preAlertSeconds: 10)
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(7))
        #expect(context.sound.preAlertCount == 0)
    }

    @Test("R8")
    func abortMarksSessionAndCancelsAlerts() throws {
        let context = try makeRunner()
        context.runner.start(now: start)
        context.runner.abort()
        #expect(context.runner.session.status == .aborted)
        #expect(context.runner.session.finishedAt != nil)
        #expect(context.notifications.cancelledAllStageCount == 2)
    }

    @Test("R9")
    func ticksFollowTheCurveInsideTheWindow() throws {
        let context = try makeRunner(stageSeconds: [100], preAlertSeconds: 30)
        context.runner.start(now: start)

        // Прогон тиками раннера по 0.25 с через всё окно: первый сигнал — предупик,
        // дальше пики по кривой; интервал между пиками сокращается.
        var tickMoments: [TimeInterval] = []
        var previousTicks = 0
        for step in stride(from: 70.0, to: 100.0, by: 0.25) {
            context.runner.tick(now: start.addingTimeInterval(step))
            if context.sound.tickCount > previousTicks {
                tickMoments.append(step)
                previousTicks = context.sound.tickCount
            }
        }

        let gaps = zip(tickMoments.dropFirst(), tickMoments).map { $0 - $1 }
        #expect(context.sound.preAlertCount == 1)
        #expect(gaps.count > 10)
        #expect(gaps == gaps.sorted(by: >))
        #expect(gaps.first ?? 0 >= 3)
        #expect(gaps.last ?? 0 <= 0.5)
    }

    @Test("R10")
    func ticksAtMostOncePerCallAfterAJump() throws {
        let context = try makeRunner(stageSeconds: [100], preAlertSeconds: 30)
        context.runner.start(now: start)
        context.runner.tick(now: start.addingTimeInterval(70))
        context.runner.tick(now: start.addingTimeInterval(95))
        #expect(context.sound.preAlertCount == 1)
        #expect(context.sound.tickCount == 1)
    }

    @Test("R11")
    func noTicksOutsideTheWindow() throws {
        let context = try makeRunner(stageSeconds: [100], preAlertSeconds: 30)
        context.runner.start(now: start)
        for step in stride(from: 0.0, to: 70.0, by: 0.25) {
            context.runner.tick(now: start.addingTimeInterval(step))
        }
        #expect(context.sound.tickCount == 0)
        #expect(context.sound.preAlertCount == 0)
    }

    @Test("R12")
    func remainingAtStartEqualsPlannedSeconds() throws {
        let context = try makeRunner()
        context.runner.start(now: start)

        // Момент старта и момент отрисовки — один и тот же: остаток ровно плановый.
        #expect(context.runner.remainingSeconds(now: start) == 100)

        // Отрисовка по устаревшему `now` (тик до нажатия) округлялась вверх до 101 —
        // та самая лишняя секунда, которая промаргивала на экране.
        #expect(context.runner.remainingSeconds(now: start.addingTimeInterval(-0.2)) == 101)
    }

    private func makeRunner(
        stageSeconds: [Int] = [100, 60],
        preAlertSeconds: Int = 10
    ) throws -> RunnerContext {
        let container = try ModelContainer(
            for: ChemistryKit.self, DevelopmentSession.self, FilmRecord.self, StageSnapshot.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let session = DevelopmentSession(startedAt: start, status: .inProgress)
        context.insert(session)
        session.stages = stageSeconds.enumerated().map { index, seconds in
            StageSnapshot(
                orderIndex: index,
                stageID: "stage\(index)",
                name: "Этап \(index)",
                prepare: nil,
                tempC: nil,
                plannedSeconds: seconds,
                preAlertSeconds: preAlertSeconds
            )
        }

        let sound = AlertServiceSpy()
        let notifications = NotificationServiceSpy()
        return RunnerContext(
            runner: SessionRunner(
                session: session,
                geigerCurve: .standard,
                alertService: sound,
                notificationService: notifications,
                liveActivityService: LiveActivityServiceStub(),
                modelContext: context
            ),
            sound: sound,
            notifications: notifications
        )
    }
}

private struct RunnerContext {
    let runner: SessionRunner
    let sound: AlertServiceSpy
    let notifications: NotificationServiceSpy
}

private final class AlertServiceSpy: AlertService {
    private(set) var preAlertCount = 0
    private(set) var tickCount = 0
    private(set) var stageEndCount = 0

    func activate() {}
    func deactivate() {}

    func playPreAlert() {
        preAlertCount += 1
    }

    func playTick() {
        tickCount += 1
    }

    func playStageEnd() {
        stageEndCount += 1
    }
}

@MainActor
private final class LiveActivityServiceStub: LiveActivityService {
    func start(processName: String, totalStages: Int, state: DevelopmentActivityAttributes.ContentState) async {}
    func update(state: DevelopmentActivityAttributes.ContentState) async {}
    func stop() async {}
}

private final class NotificationServiceSpy: NotificationService {
    private(set) var scheduledStages: [Int] = []
    private(set) var cancelledStages: [Int] = []
    private(set) var cancelledAllStageCount: Int?

    func requestAuthorization() async -> Bool {
        true
    }

    func scheduleStageAlerts(
        sessionID: UUID,
        stageIndex: Int,
        stageName: String,
        preAlertAt: Date?,
        endAt: Date
    ) {
        scheduledStages.append(stageIndex)
    }

    func cancelStageAlerts(sessionID: UUID, stageIndex: Int) {
        cancelledStages.append(stageIndex)
    }

    func cancelAll(sessionID: UUID, stageCount: Int) {
        cancelledAllStageCount = stageCount
    }
}
