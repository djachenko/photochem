import Foundation

public enum ConfigParser {
    public static func parse(_ data: Data) throws -> ProcessConfig {
        let raw: RawConfig
        do {
            raw = try JSONDecoder().decode(RawConfig.self, from: data)
        } catch {
            throw CoreError.malformedJSON(String(describing: error))
        }

        guard raw.schemaVersion == 1 else {
            throw CoreError.unsupportedSchemaVersion(raw.schemaVersion)
        }
        guard !raw.processes.isEmpty else {
            throw CoreError.validationFailed(rule: "V2", detail: "Список процессов пуст")
        }
        let processIds = raw.processes.map(\.id)
        guard Set(processIds).count == processIds.count else {
            throw CoreError.validationFailed(rule: "V3", detail: "Идентификаторы процессов не уникальны")
        }

        return ProcessConfig(
            schemaVersion: raw.schemaVersion,
            updatedAt: raw.updatedAt,
            processes: try raw.processes.map(process)
        )
    }

    private static func process(from raw: RawProcess) throws -> DevelopmentProcess {
        guard raw.capacityFilms >= 1, raw.shelfLifeDays >= 1 else {
            throw CoreError.validationFailed(
                rule: "V4",
                detail: "Процесс \(raw.id): ёмкость и срок годности должны быть не меньше 1"
            )
        }
        guard !raw.stages.isEmpty else {
            throw CoreError.validationFailed(rule: "V5", detail: "Процесс \(raw.id): нет этапов")
        }
        let stageIds = raw.stages.map(\.id)
        guard Set(stageIds).count == stageIds.count else {
            throw CoreError.validationFailed(
                rule: "V6",
                detail: "Процесс \(raw.id): идентификаторы этапов не уникальны"
            )
        }

        return DevelopmentProcess(
            id: raw.id,
            name: raw.name,
            capacityFilms: raw.capacityFilms,
            shelfLifeDays: raw.shelfLifeDays,
            stages: try raw.stages.map { try stage(from: $0, capacityFilms: raw.capacityFilms) }
        )
    }

    private static func stage(from raw: RawStage, capacityFilms: Int) throws -> ProcessStage {
        if let preAlertSeconds = raw.preAlertSeconds, preAlertSeconds < 1 {
            throw CoreError.validationFailed(
                rule: "V11",
                detail: "Этап \(raw.id): предупик должен быть не меньше 1 секунды"
            )
        }

        return ProcessStage(
            id: raw.id,
            name: raw.name,
            prepare: raw.prepare,
            tempC: raw.tempC,
            timing: try timing(from: raw, capacityFilms: capacityFilms),
            preAlertOverrideSeconds: raw.preAlertSeconds
        )
    }

    private static func timing(from raw: RawStage, capacityFilms: Int) throws -> StageTiming {
        switch (raw.time, raw.timeByFilm) {
        case (let time?, nil):
            guard let seconds = TimeFormatting.parse(time) else {
                throw CoreError.validationFailed(rule: "V8", detail: "Этап \(raw.id): время «\(time)» не в формате M:SS")
            }
            return .fixed(seconds: seconds)
        case (nil, let table?):
            return .byFilm(ranges: try ranges(from: table, stageId: raw.id, capacityFilms: capacityFilms))
        default:
            throw CoreError.validationFailed(
                rule: "V7",
                detail: "Этап \(raw.id): нужно ровно одно из time и time_by_film"
            )
        }
    }

    private static func ranges(
        from table: [String: String],
        stageId: String,
        capacityFilms: Int
    ) throws -> [FilmRange] {
        let ranges = try table
            .map { try range(key: $0.key, value: $0.value, stageId: stageId) }
            .sorted { $0.lower < $1.lower }

        var expectedLower = 1
        for range in ranges {
            guard range.lower == expectedLower else {
                throw CoreError.validationFailed(
                    rule: "V10",
                    detail: "Этап \(stageId): диапазоны не покрывают 1…\(capacityFilms) сплошным рядом"
                )
            }
            expectedLower = range.upper + 1
        }
        guard expectedLower == capacityFilms + 1 else {
            throw CoreError.validationFailed(
                rule: "V10",
                detail: "Этап \(stageId): диапазоны не покрывают 1…\(capacityFilms) сплошным рядом"
            )
        }
        return ranges
    }

    private static func range(key: String, value: String, stageId: String) throws -> FilmRange {
        let bounds = key.split(separator: "-", omittingEmptySubsequences: false)
        guard let lower = bounds.first.flatMap({ Int($0) }), lower >= 1, bounds.count <= 2 else {
            throw CoreError.validationFailed(rule: "V9", detail: "Этап \(stageId): диапазон «\(key)» невалиден")
        }
        let upper: Int
        if bounds.count == 2 {
            guard let parsedUpper = Int(bounds[1]), parsedUpper >= lower else {
                throw CoreError.validationFailed(rule: "V9", detail: "Этап \(stageId): диапазон «\(key)» невалиден")
            }
            upper = parsedUpper
        } else {
            upper = lower
        }
        guard let seconds = TimeFormatting.parse(value) else {
            throw CoreError.validationFailed(rule: "V8", detail: "Этап \(stageId): время «\(value)» не в формате M:SS")
        }
        return FilmRange(lower: lower, upper: upper, seconds: seconds)
    }
}

private struct RawConfig: Decodable {
    let schemaVersion: Int
    let updatedAt: String
    let processes: [RawProcess]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
        case processes
    }
}

private struct RawProcess: Decodable {
    let id: String
    let name: String
    let capacityFilms: Int
    let shelfLifeDays: Int
    let stages: [RawStage]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case capacityFilms = "capacity_films"
        case shelfLifeDays = "shelf_life_days"
        case stages
    }
}

private struct RawStage: Decodable {
    let id: String
    let name: String
    let prepare: String?
    let tempC: Double?
    let time: String?
    let timeByFilm: [String: String]?
    let preAlertSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case prepare
        case tempC = "temp_c"
        case time
        case timeByFilm = "time_by_film"
        case preAlertSeconds = "pre_alert_s"
    }
}
