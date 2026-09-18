import Foundation
import PhotochemCore
import SwiftData

@MainActor
@Observable
final class NewSessionViewModel {
    var filmsInTank = 1

    let kit: ChemistryKit
    let process: DevelopmentProcess

    private let settings: SettingsStore
    private let modelContext: ModelContext

    init(kit: ChemistryKit, process: DevelopmentProcess, settings: SettingsStore, modelContext: ModelContext) {
        self.kit = kit
        self.process = process
        self.settings = settings
        self.modelContext = modelContext
    }

    var maximumFilms: Int {
        min(settings.tankSize, process.capacityFilms - kit.mileage)
    }

    var stageTimes: [StageTime] {
        (try? TimeCalculator.stageTimes(
            process: process,
            currentMileage: kit.mileage,
            filmsInTank: filmsInTank
        )) ?? []
    }

    var filmNumbersText: String {
        let first = kit.mileage + 1
        let last = kit.mileage + filmsInTank
        return first == last
            ? String(localized: .newSessionFilmNumber(first))
            : String(localized: .newSessionFilmNumbers(first, last))
    }

    func createSession() -> DevelopmentSession? {
        let times = stageTimes
        guard !times.isEmpty else {
            return nil
        }

        let session = DevelopmentSession(startedAt: .now, status: .inProgress)
        session.kit = kit
        session.films = (0..<filmsInTank).map(FilmRecord.init(orderIndex:))
        session.stages = times.enumerated().map { index, stageTime in
            StageSnapshot(
                orderIndex: index,
                stageID: stageTime.stage.id,
                name: stageTime.stage.name,
                prepare: stageTime.stage.prepare,
                tempC: stageTime.stage.tempC,
                plannedSeconds: stageTime.seconds,
                preAlertSeconds: settings.preAlertSeconds ?? stageTime.stage.preAlertOverrideSeconds ?? Constants.preAlertSeconds
            )
        }
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }
}
