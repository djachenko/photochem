import Foundation
import PhotochemCore

protocol ConfigService: AnyObject {
    var config: ProcessConfig { get }

    func process(id: String) -> DevelopmentProcess?
    func availableProcesses() -> [DevelopmentProcess]
    func refreshFromRemote() async -> ConfigRefreshResult
    func resetToBundled()
}

enum ConfigRefreshResult: Equatable {
    case upToDate
    case updated(updatedAt: String)
    case rejected(reason: String)
    case serverError(statusCode: Int)
    case unreachable
    case insecureURL
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

    func refreshFromRemote() async -> ConfigRefreshResult {
        guard let url = URL(string: settings.remoteURL), url.scheme == "https" else {
            return .insecureURL
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        if let etag = settings.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse else {
            return .unreachable
        }

        switch httpResponse.statusCode {
        case 304:
            settings.lastFetchAt = .now
            return .upToDate
        case 200:
            return apply(downloaded: data, response: httpResponse)
        default:
            return .serverError(statusCode: httpResponse.statusCode)
        }
    }

    func resetToBundled() {
        try? FileManager.default.removeItem(at: ConfigCache.fileURL)
        settings.etag = nil
        config = Self.bundledConfig()
    }

    private func apply(downloaded data: Data, response: HTTPURLResponse) -> ConfigRefreshResult {
        let parsed: ProcessConfig
        do {
            parsed = try ConfigParser.parse(data)
        } catch {
            return .rejected(reason: String(describing: error))
        }

        writeCache(data)
        settings.etag = response.value(forHTTPHeaderField: "ETag")
        settings.lastFetchAt = .now
        config = parsed
        return .updated(updatedAt: parsed.updatedAt)
    }

    private func writeCache(_ data: Data) {
        let directory = ConfigCache.fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: ConfigCache.fileURL)
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
