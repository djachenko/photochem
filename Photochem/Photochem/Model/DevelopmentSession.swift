import Foundation
import SwiftData

@Model
final class DevelopmentSession {
    @Attribute(.unique) var id: UUID
    var kit: ChemistryKit?
    var startedAt: Date
    var finishedAt: Date?
    var statusRaw: String

    @Relationship(deleteRule: .cascade, inverse: \FilmRecord.session)
    var films: [FilmRecord]

    @Relationship(deleteRule: .cascade, inverse: \StageSnapshot.session)
    var stages: [StageSnapshot]

    init(startedAt: Date, status: SessionStatus) {
        self.id = UUID()
        self.startedAt = startedAt
        self.finishedAt = nil
        self.statusRaw = status.rawValue
        self.films = []
        self.stages = []
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var orderedStages: [StageSnapshot] {
        stages.sorted { $0.orderIndex < $1.orderIndex }
    }
}
