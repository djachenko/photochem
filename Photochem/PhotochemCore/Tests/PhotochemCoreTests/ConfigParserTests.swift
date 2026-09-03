import Foundation
import Testing
@testable import PhotochemCore

struct ConfigParserTests {
    @Test("Канонический конфиг репозитория")
    func parsesCanonicalConfig() throws {
        let config = try ConfigParser.parse(try Data(contentsOf: Self.canonicalConfigURL))
        #expect(config.schemaVersion == 1)
        #expect(!config.processes.isEmpty)
    }

    private static var canonicalConfigURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // PhotochemCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // PhotochemCore
            .deletingLastPathComponent()   // Photochem
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("config/processes.json")
    }

    @Test("V1")
    func rejectsUnsupportedSchemaVersion() {
        #expect(throws: CoreError.unsupportedSchemaVersion(2)) {
            try parse(config(schemaVersion: 2))
        }
    }

    @Test("V2")
    func rejectsEmptyProcesses() {
        expectValidationFailure(rule: "V2") {
            try parse(config(processes: []))
        }
    }

    @Test("V3")
    func rejectsDuplicateProcessIds() {
        expectValidationFailure(rule: "V3") {
            try parse(config(processes: [process(), process()]))
        }
    }

    @Test("V4", arguments: [("capacity_films", 0), ("shelf_life_days", 0)])
    func rejectsNonPositiveLimits(field: String, value: Int) {
        expectValidationFailure(rule: "V4") {
            try parse(config(processes: [process(overrides: [field: value])]))
        }
    }

    @Test("V5")
    func rejectsProcessWithoutStages() {
        expectValidationFailure(rule: "V5") {
            try parse(config(processes: [process(stages: [])]))
        }
    }

    @Test("V6")
    func rejectsDuplicateStageIds() {
        expectValidationFailure(rule: "V6") {
            try parse(config(processes: [process(stages: [fixedStage(), fixedStage()])]))
        }
    }

    @Test("V7: оба тайминга сразу")
    func rejectsBothTimings() {
        expectValidationFailure(rule: "V7") {
            try parse(config(processes: [process(stages: [
                fixedStage(overrides: ["time_by_film": ["1-10": "3:15"]])
            ])]))
        }
    }

    @Test("V7: ни одного тайминга")
    func rejectsMissingTiming() {
        expectValidationFailure(rule: "V7") {
            try parse(config(processes: [process(stages: [stage(id: "wash")])]))
        }
    }

    @Test("V8", arguments: ["3:5", "3:60", "195"])
    func rejectsMalformedTime(time: String) {
        expectValidationFailure(rule: "V8") {
            try parse(config(processes: [process(stages: [fixedStage(time: time)])]))
        }
    }

    @Test("V9", arguments: ["0-5", "5-1", "a-5", "1-5-7"])
    func rejectsMalformedRangeKey(key: String) {
        expectValidationFailure(rule: "V9") {
            try parse(config(processes: [process(stages: [byFilmStage(table: [key: "3:15"])])]))
        }
    }

    @Test("V10: дыра")
    func rejectsRangeGap() {
        expectValidationFailure(rule: "V10") {
            try parse(config(processes: [process(stages: [
                byFilmStage(table: ["1-4": "3:15", "6-10": "3:30"])
            ])]))
        }
    }

    @Test("V10: перекрытие")
    func rejectsRangeOverlap() {
        expectValidationFailure(rule: "V10") {
            try parse(config(processes: [process(stages: [
                byFilmStage(table: ["1-5": "3:15", "5-10": "3:30"])
            ])]))
        }
    }

    @Test("V10: выход за capacity")
    func rejectsRangeBeyondCapacity() {
        expectValidationFailure(rule: "V10") {
            try parse(config(processes: [process(stages: [byFilmStage(table: ["1-12": "3:15"])])]))
        }
    }

    @Test("V11")
    func rejectsNonPositivePreAlert() {
        expectValidationFailure(rule: "V11") {
            try parse(config(processes: [process(stages: [fixedStage(overrides: ["pre_alert_s": 0])])]))
        }
    }

    @Test("Битый JSON")
    func rejectsMalformedJSON() {
        #expect(throws: CoreError.self) {
            try ConfigParser.parse(Data("{ not json".utf8))
        }
    }

    @Test("Ключи в перемешанном порядке сортируются")
    func sortsRangesByLowerBound() throws {
        let parsed = try parse(config(processes: [process(stages: [
            byFilmStage(table: ["6-8": "3:30", "9-10": "3:45", "1-5": "3:15"])
        ])]))
        let timing = try #require(parsed.processes.first?.stages.first?.timing)
        #expect(timing == .byFilm(ranges: [
            FilmRange(lower: 1, upper: 5, seconds: 195),
            FilmRange(lower: 6, upper: 8, seconds: 210),
            FilmRange(lower: 9, upper: 10, seconds: 225)
        ]))
    }

    private func parse(_ json: [String: Any]) throws -> ProcessConfig {
        try ConfigParser.parse(try JSONSerialization.data(withJSONObject: json))
    }

    private func expectValidationFailure(
        rule: String,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ body: () throws -> ProcessConfig
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

    private func config(schemaVersion: Int = 1, processes: [[String: Any]]? = nil) -> [String: Any] {
        [
            "schema_version": schemaVersion,
            "updated_at": "2026-07-04",
            "processes": processes ?? [process()]
        ]
    }

    private func process(
        stages: [[String: Any]]? = nil,
        overrides: [String: Any] = [:]
    ) -> [String: Any] {
        var process: [String: Any] = [
            "id": "c41",
            "name": "C-41",
            "capacity_films": 10,
            "shelf_life_days": 42,
            "stages": stages ?? [fixedStage()]
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

    private func byFilmStage(table: [String: String]) -> [String: Any] {
        stage(id: "developer", overrides: ["time_by_film": table])
    }
}
