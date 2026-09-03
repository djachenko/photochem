import Foundation
import SwiftData

@Model
final class ChemistryKit {
    @Attribute(.unique) var id: UUID
    var processID: String
    var processName: String
    var mixedAt: Date
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \DevelopmentSession.kit)
    var sessions: [DevelopmentSession]

    init(processID: String, processName: String, mixedAt: Date) {
        self.id = UUID()
        self.processID = processID
        self.processName = processName
        self.mixedAt = mixedAt
        self.archivedAt = nil
        self.sessions = []
    }

    var mileage: Int {
        sessions.reduce(0) { $0 + $1.films.count }
    }

    var ageDays: Int {
        let calendar = Calendar.current
        let mixedDay = calendar.startOfDay(for: mixedAt)
        let today = calendar.startOfDay(for: .now)
        return calendar.dateComponents([.day], from: mixedDay, to: today).day ?? 0
    }

    var isArchived: Bool {
        archivedAt != nil
    }
}
