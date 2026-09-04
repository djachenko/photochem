import ActivityKit
import Foundation

nonisolated struct DevelopmentActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        let stageIndex: Int
        let stageName: String
        let phase: String
        let endDate: Date?
    }

    let processName: String
    let totalStages: Int
}

enum DevelopmentActivityPhase {
    static let preparing = "preparing"
    static let running = "running"
}
