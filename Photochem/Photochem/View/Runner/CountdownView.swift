import SwiftUI

/// Источник времени для таймеров: остаток до `endDate` пересчитывается на каждом кадре
/// дисплея, так что содержимому не нужен внешний тик.
struct CountdownView<Content: View>: View {
    let endDate: Date
    @ViewBuilder let content: (_ remaining: TimeInterval) -> Content

    var body: some View {
        TimelineView(.animation) { context in
            content(max(0, endDate.timeIntervalSince(context.date)))
        }
    }
}

#Preview {
    CountdownView(endDate: .now.addingTimeInterval(75)) { remaining in
        Text(remaining.formatted(.number.precision(.fractionLength(2))))
            .font(.largeTitle.monospacedDigit())
    }
}
