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
            Text(timeText)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
        }
        .frame(width: 240, height: 240)
    }
}
