import Foundation
import PhotochemCore
import SwiftData

@MainActor
@Observable
final class KitListViewModel {
    private let configService: ConfigService
    private let modelContext: ModelContext

    var kitPendingDeletion: ChemistryKit?

    init(configService: ConfigService, modelContext: ModelContext) {
        self.configService = configService
        self.modelContext = modelContext
    }

    func subtitle(for kit: ChemistryKit) -> String {
        guard let process = configService.process(id: kit.processID) else {
            return "Пробег \(kit.mileage) · процесс не найден"
        }
        return "Пробег \(kit.mileage) из \(process.capacityFilms) · возраст \(kit.ageDays) дн"
    }

    func isExpired(_ kit: ChemistryKit) -> Bool {
        guard let process = configService.process(id: kit.processID) else {
            return false
        }
        return kit.ageDays >= process.shelfLifeDays
    }

    func isExhausted(_ kit: ChemistryKit) -> Bool {
        guard let process = configService.process(id: kit.processID) else {
            return false
        }
        return kit.mileage >= process.capacityFilms
    }

    func archive(_ kit: ChemistryKit) {
        kit.archivedAt = .now
        save()
    }

    func unarchive(_ kit: ChemistryKit) {
        kit.archivedAt = nil
        save()
    }

    func confirmDeletion() {
        guard let kit = kitPendingDeletion else {
            return
        }
        modelContext.delete(kit)
        kitPendingDeletion = nil
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}
