public struct ProcessConfig: Sendable, Equatable {
    public let schemaVersion: Int
    public let updatedAt: String
    public let processes: [DevelopmentProcess]
}

public struct DevelopmentProcess: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let capacityFilms: Int
    public let shelfLifeDays: Int
    public let stages: [ProcessStage]
}

public struct ProcessStage: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let prepare: String?
    public let tempC: Double?
    public let timing: StageTiming
    public let preAlertOverrideSeconds: Int?
}

public enum StageTiming: Sendable, Equatable {
    case fixed(seconds: Int)
    case byFilm(ranges: [FilmRange])
}

public struct FilmRange: Sendable, Equatable {
    public let lower: Int
    public let upper: Int
    public let seconds: Int
}
