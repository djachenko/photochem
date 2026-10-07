import Foundation
import Testing
@testable import PhotochemCore

struct ConfigParserTests {
    @Test("Канонические файлы репозитория")
    func parsesCanonicalFiles() throws {
        let files = try FileManager.default.contentsOfDirectory(at: Self.configDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" && $0.lastPathComponent != "index.json" }

        #expect(!files.isEmpty)
        for file in files {
            let process = try ConfigParser.parseProcess(try Data(contentsOf: file))
            #expect(process.id + ".json" == file.lastPathComponent)
        }
    }

    @Test("Индекс — массив имён файлов")
    func parsesIndex() throws {
        let names = try ConfigParser.parseIndex(Data(#"["a.json", "b.json"]"#.utf8))
        #expect(names == ["a.json", "b.json"])
    }

    private static var configDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // PhotochemCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // PhotochemCore
            .deletingLastPathComponent()   // Photochem
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("config")
    }

    @Test("V1")
    func rejectsUnsupportedSchemaVersion() {
        #expect(throws: CoreError.unsupportedSchemaVersion(1)) {
            try parse(process(overrides: ["schema_version": 1]))
        }
    }

    @Test("V4", arguments: [("capacity_films", 0), ("shelf_life_days", 0)])
    func rejectsNonPositiveLimits(field: String, value: Int) {
        expectValidationFailure(rule: "V4") {
            try parse(process(overrides: [field: value]))
        }
    }

    @Test("V5")
    func rejectsProcessWithoutStages() {
        expectValidationFailure(rule: "V5") {
            try parse(process(stages: []))
        }
    }

    @Test("V6")
    func rejectsDuplicateStageIds() {
        expectValidationFailure(rule: "V6") {
            try parse(process(stages: [fixedStage(), fixedStage()]))
        }
    }

    @Test("V7: оба тайминга сразу")
    func rejectsBothTimings() {
        expectValidationFailure(rule: "V7") {
            try parse(process(stages: [
                stage(id: "developer", overrides: ["time": "3:00", "time_by_film": [range(1, 10, "3:00")]]),
            ]))
        }
    }

    @Test("V7: ни одного тайминга")
    func rejectsMissingTiming() {
        expectValidationFailure(rule: "V7") {
            try parse(process(stages: [stage(id: "developer")]))
        }
    }

    @Test("V8", arguments: ["3:5", "3:60", "195"])
    func rejectsMalformedTime(time: String) {
        expectValidationFailure(rule: "V8") {
            try parse(process(stages: [fixedStage(time: time)]))
        }
    }

    @Test("V9: from > to")
    func rejectsInvertedRange() {
        expectValidationFailure(rule: "V9") {
            try parse(process(stages: [byFilmStage([range(5, 1, "3:00")])]))
        }
    }

    @Test("V9: from < 1")
    func rejectsRangeBelowOne() {
        expectValidationFailure(rule: "V9") {
            try parse(process(stages: [byFilmStage([range(0, 10, "3:00")])]))
        }
    }

    @Test("V10: дыра")
    func rejectsRangeGap() {
        expectValidationFailure(rule: "V10") {
            try parse(process(stages: [byFilmStage([range(1, 5, "3:00"), range(7, 10, "3:30")])]))
        }
    }

    @Test("V10: наложение")
    func rejectsRangeOverlap() {
        expectValidationFailure(rule: "V10") {
            try parse(process(stages: [byFilmStage([range(1, 5, "3:00"), range(5, 10, "3:30")])]))
        }
    }

    @Test("V10: не доходит до capacity")
    func rejectsRangeShortOfCapacity() {
        expectValidationFailure(rule: "V10") {
            try parse(process(stages: [byFilmStage([range(1, 9, "3:00")])]))
        }
    }

    @Test("V10: выход за capacity")
    func rejectsRangeBeyondCapacity() {
        expectValidationFailure(rule: "V10") {
            try parse(process(stages: [byFilmStage([range(1, 12, "3:00")])]))
        }
    }

    @Test("V11")
    func rejectsNonPositiveStagePreAlert() {
        expectValidationFailure(rule: "V11") {
            try parse(process(stages: [fixedStage(overrides: ["pre_alert_seconds": 0])]))
        }
    }

    @Test("V12")
    func rejectsNonPositiveProcessPreAlert() {
        expectValidationFailure(rule: "V12") {
            try parse(process(overrides: ["pre_alert_seconds": 0]))
        }
    }

    @Test("Битый JSON")
    func rejectsMalformedJSON() {
        #expect(throws: CoreError.self) {
            try ConfigParser.parseProcess(Data("{ not json".utf8))
        }
    }

    @Test("Один диапазон на всю ёмкость")
    func acceptsSingleFullRange() throws {
        let parsed = try parse(process(stages: [byFilmStage([range(1, 10, "3:00")])]))
        #expect(parsed.stages[0].timing == .byFilm(ranges: [FilmRange(lower: 1, upper: 10, seconds: 180)]))
    }

    @Test("Неотсортированный массив сортируется")
    func sortsRangesByLowerBound() throws {
        let parsed = try parse(process(stages: [
            byFilmStage([range(9, 10, "3:45"), range(1, 5, "3:15"), range(6, 8, "3:30")]),
        ]))
        #expect(parsed.stages[0].timing == .byFilm(ranges: [
            FilmRange(lower: 1, upper: 5, seconds: 195),
            FilmRange(lower: 6, upper: 8, seconds: 210),
            FilmRange(lower: 9, upper: 10, seconds: 225),
        ]))
    }

    @Test("Окно предупика процесса читается")
    func readsProcessPreAlert() throws {
        let parsed = try parse(process(overrides: ["pre_alert_seconds": 45]))
        #expect(parsed.preAlertSeconds == 45)
    }

    private func parse(_ json: [String: Any]) throws -> DevelopmentProcess {
        try ConfigParser.parseProcess(try JSONSerialization.data(withJSONObject: json))
    }

    private func expectValidationFailure(
        rule: String,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ body: () throws -> DevelopmentProcess
    ) {
        #expect(sourceLocation: sourceLocation) {
            try body()
        } throws: { error in
            guard case .validationFailed(let failedRule, _) = error as? CoreError else {
                return false
            }
            return failedRule == rule
        }
    }

    private func process(
        stages: [[String: Any]]? = nil,
        overrides: [String: Any] = [:]
    ) -> [String: Any] {
        var process: [String: Any] = [
            "schema_version": 2,
            "updated_at": "2026-07-04",
            "id": "c41",
            "name": "C-41",
            "capacity_films": 10,
            "shelf_life_days": 42,
            "stages": stages ?? [fixedStage()],
        ]
        process.merge(overrides) { _, override in override }
        return process
    }

    private func stage(id: String, overrides: [String: Any] = [:]) -> [String: Any] {
        var stage: [String: Any] = ["id": id, "name": "Этап"]
        stage.merge(overrides) { _, override in override }
        return stage
    }

    private func fixedStage(time: String = "3:00", overrides: [String: Any] = [:]) -> [String: Any] {
        stage(id: "wash", overrides: ["time": time].merging(overrides) { _, override in override })
    }

    private func byFilmStage(_ table: [[String: Any]]) -> [String: Any] {
        stage(id: "developer", overrides: ["time_by_film": table])
    }

    private func range(_ from: Int, _ to: Int, _ time: String) -> [String: Any] {
        ["from": from, "to": to, "time": time]
    }
}
