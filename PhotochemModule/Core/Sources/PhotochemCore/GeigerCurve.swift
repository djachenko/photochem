/// Расписание пиков «счётчика Гейгера» в окне предупика: интервал до следующего пика
/// пропорционален остатку, так что частота растёт гиперболически к концу этапа.
/// Пол снизу не даёт интервалу схлопнуться в ноль у самого финала.
public struct GeigerCurve: Sendable, Equatable {
    public var ratio: Double
    public var minimumInterval: Double

    /// Стартовые параметры: за 30 с — пик каждые ~4 с, за 10 с — ~1.2 с, ближе 2 с — каждые 0.25 с.
    public static let standard = GeigerCurve(ratio: 1 / 8, minimumInterval: 0.25)

    public func interval(remaining: Double) -> Double {
        max(minimumInterval, remaining * ratio)
    }
}
