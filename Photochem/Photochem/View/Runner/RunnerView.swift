import Combine
import PhotochemCore
import SwiftData
import SwiftUI
import SwinjectAutoregistration

struct RunnerView: View {
    let session: DevelopmentSession

    @Environment(\.diContainer) private var diContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var runner: SessionRunner?
    @State private var now = Date.now
    @State private var isConfirmingAbort = false

    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if let runner {
                    content(runner: runner)
                } else {
                    Color.clear
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if runner?.state != .finished {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(String(localized: .runnerAbort), role: .destructive) {
                            isConfirmingAbort = true
                        }
                    }
                }
            }
            .confirmationDialog(String(localized: .runnerAbortConfirmation), isPresented: $isConfirmingAbort, titleVisibility: .visible) {
                Button(String(localized: .runnerAbort), role: .destructive) {
                    runner?.abort()
                    dismiss()
                }
                Button(String(localized: .runnerResume), role: .cancel) {}
            } message: {
                Text(String(localized: .runnerAbortWarning))
            }
        }
        .interactiveDismissDisabled(true)
        .task {
            if runner == nil {
                let newRunner = SessionRunner(
                    session: session,
                    soundService: diContainer ~> SoundService.self,
                    notificationService: diContainer ~> NotificationService.self,
                    liveActivityService: diContainer ~> LiveActivityService.self,
                    modelContext: modelContext
                )
                runner = newRunner
                await newRunner.startLiveActivity()
            }
            (diContainer ~> SoundService.self).activate()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            (diContainer ~> SoundService.self).deactivate()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(tick) { date in
            now = date
            runner?.tick(now: date)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                runner?.tick(now: .now)
            }
        }
    }

    @ViewBuilder
    private func content(runner: SessionRunner) -> some View {
        switch runner.state {
        case .preparing(let stageIndex):
            preparing(runner: runner, stageIndex: stageIndex)
        case .running(let stageIndex, _, _, let preAlertFired):
            running(runner: runner, stageIndex: stageIndex, preAlertFired: preAlertFired)
        case .finished:
            SummaryView(session: session) {
                runner.complete()
                dismiss()
            }
        }
    }

    private func preparing(runner: SessionRunner, stageIndex: Int) -> some View {
        VStack(spacing: 24) {
            progressLabel(runner: runner, stageIndex: stageIndex)
            if let stage = runner.stage(at: stageIndex) {
                Text(stage.name)
                    .font(.largeTitle.bold())
                if let prepare = stage.prepare {
                    Text(prepare)
                        .multilineTextAlignment(.center)
                }
                if let tempC = stage.tempC {
                    Text(String(localized: .runnerTemperature(tempC.formatted(.number.precision(.fractionLength(1))))))
                        .foregroundStyle(.secondary)
                }
                Text(TimeFormatting.format(seconds: stage.plannedSeconds))
                    .font(.title.monospacedDigit())
                Spacer()
                Button(String(localized: .runnerStart)) {
                    runner.start()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .frame(maxWidth: .infinity, minHeight: 60)
                if let next = runner.stage(at: stageIndex + 1) {
                    Text(String(localized: .runnerNextStage(next.name)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private func running(runner: SessionRunner, stageIndex: Int, preAlertFired: Bool) -> some View {
        VStack(spacing: 24) {
            progressLabel(runner: runner, stageIndex: stageIndex)
            if let stage = runner.stage(at: stageIndex) {
                CircleTimerView(
                    progress: progress(runner: runner, stage: stage),
                    timeText: TimeFormatting.format(seconds: runner.remainingSeconds(now: now)),
                    tint: preAlertFired ? .orange : .accentColor
                )
                Text(stage.name)
                    .font(.title2)
                if let tempC = stage.tempC {
                    Text(String(localized: .runnerTemperature(tempC.formatted(.number.precision(.fractionLength(1))))))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let next = runner.stage(at: stageIndex + 1) {
                    Text(String(localized: .runnerNextStageWithPrepare(next.name, next.prepare ?? "")))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }

    private func progressLabel(runner: SessionRunner, stageIndex: Int) -> some View {
        Text(String(localized: .runnerStageProgress(stageIndex + 1, runner.stageCount)))
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private func progress(runner: SessionRunner, stage: StageSnapshot) -> Double {
        guard stage.plannedSeconds > 0 else {
            return 0
        }
        return Double(runner.remainingSeconds(now: now)) / Double(stage.plannedSeconds)
    }
}
