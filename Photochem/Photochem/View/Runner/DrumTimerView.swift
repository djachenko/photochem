import SwiftUI

/// Таймер барабанами: каждый разряд — бесконечная лента цифр, которая доворачивается
/// на границе разряда. Лента склеена из трёх одинаковых циклов, поэтому переход
/// 0 → 9 (скачок ровно на период) в кадре неотличим от продолжения вращения.
struct DrumTimerView: View {
    let remaining: TimeInterval

    private let digitHeight: CGFloat = 68

    var body: some View {
        HStack(spacing: 2) {
            drum(value: remaining / 60, period: 10)
            separator
            drum(value: remaining / 10, period: 6)
            drum(value: remaining, period: 10)
        }
    }

    private var separator: some View {
        Text(verbatim: ":")
            .font(font)
            .frame(height: digitHeight)
    }

    private var font: Font {
        .system(size: digitHeight * 0.82, weight: .bold, design: .monospaced)
    }

    private func drum(value: Double, period: Int) -> some View {
        DrumColumn(value: value, period: period, digitHeight: digitHeight, font: font)
    }
}

private struct DrumColumn: View {
    let value: Double
    let period: Int
    let digitHeight: CGFloat
    let font: Font

    /// Окно выше одной цифры — из-за него видны края соседних, за счёт чего лента
    /// читается как колесо, а не как подменяющийся текст.
    private var windowHeight: CGFloat {
        digitHeight * 1.7
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<(period * 3), id: \.self) { index in
                Text(verbatim: "\(index % period)")
                    .font(font)
                    .frame(height: digitHeight)
            }
        }
        .offset(y: offset)
        .frame(width: digitHeight * 0.62, height: windowHeight, alignment: .top)
        .clipped()
        .mask {
            LinearGradient(
                colors: [.clear, .black, .black, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var offset: CGFloat {
        let position = snapped(value).truncatingRemainder(dividingBy: Double(period))

        return -(position + Double(period)) * digitHeight + (windowHeight - digitHeight) / 2
    }

    /// Барабан почти всю долю разряда стоит и доворачивается на последней пятой —
    /// иначе цифры ползут непрерывно и время не прочитать.
    private func snapped(_ value: Double) -> Double {
        let whole = value.rounded(.down)
        let fraction = value - whole
        let threshold = 0.8

        guard fraction > threshold else {
            return whole
        }

        let progress = (fraction - threshold) / (1 - threshold)

        return whole + progress * progress * (3 - 2 * progress)
    }
}

#Preview {
    CountdownView(endDate: .now.addingTimeInterval(125)) { remaining in
        DrumTimerView(remaining: remaining)
    }
}
