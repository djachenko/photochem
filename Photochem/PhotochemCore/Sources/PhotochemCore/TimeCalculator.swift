public struct StageTime: Sendable, Equatable {
    public let stage: ProcessStage
    public let seconds: Int
}

public enum TimeCalculator {
    public static func stageTimes(
        process: DevelopmentProcess,
        currentMileage: Int,
        filmsInTank: Int
    ) throws -> [StageTime] {
        guard filmsInTank >= 1 else {
            throw CoreError.invalidFilmCount(filmsInTank)
        }

        guard currentMileage >= 0 else {
            throw CoreError.invalidFilmCount(currentMileage)
        }

        guard currentMileage + filmsInTank <= process.capacityFilms else {
            throw CoreError.capacityExceeded(
                mileage: currentMileage,
                films: filmsInTank,
                capacity: process.capacityFilms
            )
        }

        let filmNumbers = (currentMileage + 1)...(currentMileage + filmsInTank)

        return process.stages.map { stage in
            StageTime(stage: stage, seconds: seconds(for: stage.timing, filmNumbers: filmNumbers))
        }
    }

    private static func seconds(for timing: StageTiming, filmNumbers: ClosedRange<Int>) -> Int {
        switch timing {
            case .fixed(let seconds):
                return seconds
            case .byFilm(let ranges):
                let sum = filmNumbers.reduce(0) { total, filmNumber in
                    total + (ranges.first { $0.films.contains(filmNumber) }?.seconds ?? 0)
                }

                let average = Double(sum) / Double(filmNumbers.count)

                return Int((average / 5.0).rounded() * 5.0)
        }
    }
}
