import Testing
@testable import PhotochemCore

struct GeigerCurveTests {
    private let curve = GeigerCurve.standard

    @Test("G1")
    func intervalShrinksWithRemaining() {
        let intervals = stride(from: 30.0, through: 0.0, by: -0.5).map(curve.interval(remaining:))

        #expect(intervals == intervals.sorted(by: >))
    }

    @Test("G2")
    func intervalIsProportionalAboveFloor() {
        #expect(curve.interval(remaining: 30) == 30 * curve.ratio)
        #expect(curve.interval(remaining: 16) == 2)
    }

    @Test("G3")
    func intervalHitsFloorNearTheEnd() {
        #expect(curve.interval(remaining: 1) == curve.minimumInterval)
        #expect(curve.interval(remaining: 0) == curve.minimumInterval)
    }
}
