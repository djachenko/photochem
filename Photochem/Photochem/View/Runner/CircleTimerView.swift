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
                // Прогресс меняется раз в секунду (остаток — целые секунды): дуга
                // дотягивается до нового значения ровно за секунду, без ступенек.
                .animation(.linear(duration: 1), value: progress)
            Text(timeText)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: timeText)
        }
        .frame(width: 240, height: 240)
    }
}

#Preview {
    CircleTimerView(progress: 0.35, timeText: "1:23", tint: .accentColor)
}
