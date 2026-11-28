import Foundation
import SwiftData

@Model
final class FilmRecord {
    @Attribute(.unique)
    var id: UUID

    var orderIndex: Int
    var session: DevelopmentSession?

    init(orderIndex: Int) {
        self.id = UUID()

        self.orderIndex = orderIndex
    }
}
