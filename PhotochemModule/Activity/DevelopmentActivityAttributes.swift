import ActivityKit
import Foundation

public nonisolated struct DevelopmentActivityAttributes: ActivityAttributes, Sendable {
    public nonisolated struct ContentState: Codable, Hashable, Sendable {
        public let stageIndex: Int
        public let stageName: String
        public let phase: String
        public let endDate: Date?

        public init(stageIndex: Int, stageName: String, phase: String, endDate: Date?) {
            self.stageIndex = stageIndex
            self.stageName = stageName
            self.phase = phase
            self.endDate = endDate
        }
    }

    public let processName: String
    public let totalStages: Int

    public init(processName: String, totalStages: Int) {
        self.processName = processName
        self.totalStages = totalStages
    }
}

public enum DevelopmentActivityPhase {
    public static let preparing = "preparing"
    public static let running = "running"
}
