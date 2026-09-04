import ActivityKit
import SwiftUI
import WidgetKit

struct DevelopmentActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DevelopmentActivityAttributes.self) { context in
            lockScreenView(context: context)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    lockScreenView(context: context)
                }
            } compactLeading: {
                Text("\(context.state.stageIndex + 1)/\(context.attributes.totalStages)")
            } compactTrailing: {
                countdown(context: context)
            } minimal: {
                Text("\(context.state.stageIndex + 1)")
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<DevelopmentActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.attributes.processName)
                .font(.headline)
            Text("Этап \(context.state.stageIndex + 1) из \(context.attributes.totalStages) · \(context.state.stageName)")
                .font(.subheadline)
            countdown(context: context)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func countdown(context: ActivityViewContext<DevelopmentActivityAttributes>) -> some View {
        if let endDate = context.state.endDate, context.state.phase == DevelopmentActivityPhase.running {
            Text(timerInterval: Date.now...endDate, countsDown: true)
        } else {
            Text("Жми Старт")
        }
    }
}
