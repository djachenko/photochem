import SwiftUI

struct CircleTimerView: View {
    let progress: Double
    let timeText: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.3), lineWidth: 16)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // Тик приходит раз в 0.25 с: без интерполяции дуга идёт ступеньками.
                .animation(.linear(duration: 0.25), value: progress)
            Text(timeText)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: timeText)
        }
        .frame(width: 240, height: 240)
    }
}
