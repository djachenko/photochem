import Foundation
import PhotochemCore

protocol ConfigService: AnyObject {
    var config: ProcessConfig { get }

    func process(id: String) -> DevelopmentProcess?
    func availableProcesses() -> [DevelopmentProcess]
}

@Observable
final class ConfigServiceImpl: ConfigService {
    private(set) var config: ProcessConfig

    private let settings: SettingsStore

    init(settings: SettingsStore) {
        self.settings = settings
        self.config = Self.loadAtLaunch(settings: settings)
    }

    func process(id: String) -> DevelopmentProcess? {
        config.processes.first { $0.id == id }
    }

    func availableProcesses() -> [DevelopmentProcess] {
        #if DEBUG
        return config.processes
        #else
        return config.processes.filter { !$0.id.hasPrefix("test_") }
        #endif
    }

    private static func loadAtLaunch(settings: SettingsStore) -> ProcessConfig {
        if let cached = try? Data(contentsOf: ConfigCache.fileURL) {
            if let config = try? ConfigParser.parse(cached) {
                return config
            }
            try? FileManager.default.removeItem(at: ConfigCache.fileURL)
            settings.etag = nil
        }
        return bundledConfig()
    }

    private static func bundledConfig() -> ProcessConfig {
        guard let url = Bundle.main.url(forResource: "processes", withExtension: "json", subdirectory: "config") else {
            fatalError("Встроенный конфиг не найден в бандле")
        }
        do {
            return try ConfigParser.parse(try Data(contentsOf: url))
        } catch {
            fatalError("Встроенный конфиг не парсится: \(error)")
        }
    }
}

enum ConfigCache {
    static var fileURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "config", directoryHint: .isDirectory)
            .appending(path: "processes.json")
    }
}
