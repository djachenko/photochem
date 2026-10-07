import Foundation

/// Конфиг v2: файл на процесс плюс `index.json` со списком файлов.
/// Парсер работает по одному файлу; сборка набора и уникальность id — на стороне приложения.
public enum ConfigParser {
    public static let schemaVersion = 2

    public static func parseIndex(_ data: Data) throws -> [String] {
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            throw CoreError.malformedJSON(String(describing: error))
        }
    }

    public static func parseProcess(_ data: Data) throws -> DevelopmentProcess {
        let raw: RawProcess

        do {
            raw = try JSONDecoder().decode(RawProcess.self, from: data)
        } catch {
            throw CoreError.malformedJSON(String(describing: error))
        }

        guard raw.schemaVersion == schemaVersion else {
            throw CoreError.unsupportedSchemaVersion(raw.schemaVersion)
        }

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

        if let preAlertSeconds = raw.preAlertSeconds, preAlertSeconds < 1 {
            throw CoreError.validationFailed(
                rule: "V12",
                detail: "Процесс \(raw.id): окно предупика должно быть не меньше 1 секунды"
            )
        }

        return DevelopmentProcess(
            id: raw.id,
            name: raw.name,
            updatedAt: raw.updatedAt,
            capacityFilms: raw.capacityFilms,
            shelfLifeDays: raw.shelfLifeDays,
            preAlertSeconds: raw.preAlertSeconds,
            stages: try raw.stages.map {
                try stage(from: $0, capacityFilms: raw.capacityFilms)
            }
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
                return .fixed(seconds: try seconds(from: time, stageId: raw.id))
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
        from table: [RawRange],
        stageId: String,
        capacityFilms: Int
    ) throws -> [FilmRange] {
        let ranges = try table
            .map { try range(from: $0, stageId: stageId) }
            .sorted { $0.lower < $1.lower }

        var previous: FilmRange?
        for range in ranges {
            let expectedLower = previous.map { $0.upper + 1 } ?? 1

            guard range.lower == expectedLower else {
                throw CoreError.validationFailed(
                    rule: "V10",
                    detail: "Этап \(stageId): диапазоны \(describe(previous)) и \(describe(range)) "
                        + "не стыкуются — нужен сплошной ряд от 1"
                )
            }

            previous = range
        }

        guard let last = previous,
              last.upper == capacityFilms else {
            throw CoreError.validationFailed(
                rule: "V10",
                detail: "Этап \(stageId): последний диапазон \(describe(previous)) "
                    + "не доходит до capacity_films = \(capacityFilms)"
            )
        }

        return ranges
    }

    private static func range(from raw: RawRange, stageId: String) throws -> FilmRange {
        guard raw.from >= 1, raw.from <= raw.to else {
            throw CoreError.validationFailed(
                rule: "V9",
                detail: "Этап \(stageId): диапазон \(raw.from)–\(raw.to) невалиден — нужно 1 ≤ from ≤ to"
            )
        }
        return FilmRange(lower: raw.from, upper: raw.to, seconds: try seconds(from: raw.time, stageId: stageId))
    }

    private static func seconds(from time: String, stageId: String) throws -> Int {
        guard let seconds = TimeFormatting.parse(time) else {
            throw CoreError.validationFailed(rule: "V8", detail: "Этап \(stageId): время «\(time)» не в формате M:SS")
        }
        return seconds
    }

    private static func describe(_ range: FilmRange?) -> String {
        range.map { "\($0.lower)–\($0.upper)" } ?? "—"
    }
}

private struct RawProcess: Decodable {
    let schemaVersion: Int
    let updatedAt: String
    let id: String
    let name: String
    let capacityFilms: Int
    let shelfLifeDays: Int
    let preAlertSeconds: Int?
    let stages: [RawStage]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
        case id
        case name
        case capacityFilms = "capacity_films"
        case shelfLifeDays = "shelf_life_days"
        case preAlertSeconds = "pre_alert_seconds"
        case stages
    }
}

private struct RawStage: Decodable {
    let id: String
    let name: String
    let prepare: String?
    let tempC: Double?
    let time: String?
    let timeByFilm: [RawRange]?
    let preAlertSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case prepare
        case tempC = "temp_c"
        case time
        case timeByFilm = "time_by_film"
        case preAlertSeconds = "pre_alert_seconds"
    }
}

private struct RawRange: Decodable {
    let from: Int
    let to: Int
    let time: String
}
