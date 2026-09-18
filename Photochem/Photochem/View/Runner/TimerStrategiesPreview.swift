#if DEBUG
import Combine
import PhotochemCore
import SwiftUI

/// Три стратегии рядом, от одного дедлайна — превью только для сравнения,
/// в приложении эта вью не используется, подписи не локализуются.
private struct TimerStrategies: View {
    private static let stageSeconds = 90

    @State private var endDate = Date.now.addingTimeInterval(TimeInterval(stageSeconds))
    @State private var now = Date.now

    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                section("Тик 0.25 с + интерполяция") {
                    CircleTimerView(
                        progress: progress,
                        timeText: TimeFormatting.format(seconds: remainingSeconds),
                        tint: .accentColor
                    )
                }

                section("Кадр дисплея") {
                    CountdownView(endDate: endDate) { remaining in
                        CircleTimerView(
                            progress: remaining / TimeInterval(Self.stageSeconds),
                            timeText: TimeFormatting.format(seconds: Int(remaining.rounded(.up))),
                            tint: .accentColor
                        )
                    }
                }

                section("Барабаны") {
                    CountdownView(endDate: endDate) { remaining in
                        DrumTimerView(remaining: remaining)
                    }
                }

                Button("Заново") {
                    endDate = .now.addingTimeInterval(TimeInterval(Self.stageSeconds))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .onReceive(tick) { date in
            now = date
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private var remaining: TimeInterval {
        max(0, endDate.timeIntervalSince(now))
    }

    private var remainingSeconds: Int {
        Int(remaining.rounded(.up))
    }

    private var progress: Double {
        remaining / TimeInterval(Self.stageSeconds)
    }
}

#Preview {
    TimerStrategies()
}
#endif
