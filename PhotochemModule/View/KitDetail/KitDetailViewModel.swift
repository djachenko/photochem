import Foundation
import PhotochemCore
import SwiftData

@MainActor
@Observable
final class KitDetailViewModel {
    let kit: ChemistryKit

    private let configService: ConfigService
    private let modelContext: ModelContext

    init(kit: ChemistryKit, configService: ConfigService, modelContext: ModelContext) {
        self.kit = kit
        self.configService = configService
        self.modelContext = modelContext
    }

    var process: DevelopmentProcess? {
        configService.process(id: kit.processID)
    }

    var mileageText: String {
        guard let process else {
            return "\(kit.mileage)"
        }
        return "\(kit.mileage) из \(process.capacityFilms)"
    }

    var remainingFilms: Int? {
        process.map { $0.capacityFilms - kit.mileage }
    }

    var expiryWarning: String? {
        guard let process,
              kit.ageDays >= process.shelfLifeDays else {
            return nil
        }

        return String(localized: .kitDetailExpiryWarning(kit.ageDays, process.shelfLifeDays))
    }

    var startBlockReason: String? {
        guard let process else {
            return String(localized: .kitDetailProcessMissing)
        }
        if kit.isArchived {
            return String(localized: .kitDetailKitArchived)
        }
        if kit.mileage >= process.capacityFilms {
            return String(localized: .kitDetailKitExhausted)
        }
        return nil
    }

    var sessions: [DevelopmentSession] {
        kit.sessions.sorted { $0.startedAt > $1.startedAt }
    }

    func toggleArchived() {
        kit.archivedAt = kit.isArchived ? nil : .now
        try? modelContext.save()
    }
}
