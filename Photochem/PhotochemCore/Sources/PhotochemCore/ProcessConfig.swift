public struct ProcessConfig: Sendable, Equatable {
    public let processes: [DevelopmentProcess]

    public init(processes: [DevelopmentProcess]) {
        self.processes = processes
    }

    /// Самая свежая дата среди файлов — «версия» набора для экрана настроек.
    public var updatedAt: String {
        processes.map(\.updatedAt).max() ?? ""
    }
}

public struct DevelopmentProcess: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let updatedAt: String
    public let capacityFilms: Int
    public let shelfLifeDays: Int
    public let preAlertSeconds: Int?
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
    public let films: ClosedRange<Int>
    public let seconds: Int
}
