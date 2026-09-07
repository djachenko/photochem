import Foundation
import SwiftData

@Model
final class StageSnapshot {
    @Attribute(.unique)
    var id: UUID

    var orderIndex: Int
    var stageID: String
    var name: String
    var prepare: String?
    var tempC: Double?
    var plannedSeconds: Int
    var preAlertSeconds: Int
    var session: DevelopmentSession?

    init(
        orderIndex: Int,
        stageID: String,
        name: String,
        prepare: String?,
        tempC: Double?,
        plannedSeconds: Int,
        preAlertSeconds: Int
    ) {
        self.id = UUID()

        self.orderIndex = orderIndex
        self.stageID = stageID
        self.name = name
        self.prepare = prepare
        self.tempC = tempC
        self.plannedSeconds = plannedSeconds
        self.preAlertSeconds = preAlertSeconds
    }
}
