import Testing
@testable import PhotochemCore

struct TimeCalculatorTests {
    private let process = DevelopmentProcess(
        id: "fixture",
        name: "Fixture",
        updatedAt: "2026-07-04",
        capacityFilms: 10,
        shelfLifeDays: 42,
        preAlertSeconds: nil,
        stages: [
            ProcessStage(
                id: "developer",
                name: "Проявитель",
                prepare: nil,
                tempC: nil,
                timing: .byFilm(ranges: [
                    FilmRange(lower: 1, upper: 5, seconds: 195),
                    FilmRange(lower: 6, upper: 8, seconds: 210),
                    FilmRange(lower: 9, upper: 10, seconds: 225)
                ]),
                preAlertOverrideSeconds: nil
            ),
            ProcessStage(
                id: "blix",
                name: "Отбелка-фиксаж",
                prepare: nil,
                tempC: nil,
                timing: .byFilm(ranges: [
                    FilmRange(lower: 1, upper: 6, seconds: 390),
                    FilmRange(lower: 7, upper: 10, seconds: 480)
                ]),
                preAlertOverrideSeconds: nil
            ),
            ProcessStage(
                id: "wash",
                name: "Промывка",
                prepare: nil,
                tempC: nil,
                timing: .fixed(seconds: 180),
                preAlertOverrideSeconds: nil
            )
        ]
    )

    @Test("T1")
    func nominalFirstFilm() throws {
        try #expect(seconds(mileage: 0, films: 1) == [195, 390, 180])
    }

    @Test("T2")
    func fractionalAverageRoundsUp() throws {
        try #expect(seconds(mileage: 4, films: 2) == [205, 390, 180])
    }

    @Test("T3")
    func wholeAverageStays() throws {
        try #expect(seconds(mileage: 6, films: 3) == [215, 480, 180])
    }

    @Test("T4")
    func fractionalAverageRoundsBothWays() throws {
        try #expect(seconds(mileage: 5, films: 5) == [215, 460, 180])
    }

    @Test("T5")
    func lastFilmOfKit() throws {
        try #expect(seconds(mileage: 9, films: 1) == [225, 480, 180])
    }

    @Test("T6")
    func exceedingCapacityThrows() {
        #expect(throws: CoreError.capacityExceeded(mileage: 9, films: 2, capacity: 10)) {
            try TimeCalculator.stageTimes(process: process, currentMileage: 9, filmsInTank: 2)
        }
    }

    @Test("T7")
    func exhaustedKitThrows() {
        #expect(throws: CoreError.capacityExceeded(mileage: 10, films: 1, capacity: 10)) {
            try TimeCalculator.stageTimes(process: process, currentMileage: 10, filmsInTank: 1)
        }
    }

    @Test("T8")
    func zeroFilmsThrows() {
        #expect(throws: CoreError.invalidFilmCount(0)) {
            try TimeCalculator.stageTimes(process: process, currentMileage: 0, filmsInTank: 0)
        }
    }

    @Test("T9")
    func negativeMileageThrows() {
        #expect(throws: CoreError.invalidFilmCount(-1)) {
            try TimeCalculator.stageTimes(process: process, currentMileage: -1, filmsInTank: 1)
        }
    }

    private func seconds(mileage: Int, films: Int) throws -> [Int] {
        try TimeCalculator.stageTimes(process: process, currentMileage: mileage, filmsInTank: films)
            .map(\.seconds)
    }
}
