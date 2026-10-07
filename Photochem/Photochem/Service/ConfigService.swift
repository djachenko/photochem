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

/// Набор процессов собирается из файлов: bundled из `config/` в бандле, поверх — кэш
/// скачанных с remote. Файл с тем же именем из кэша заменяет bundled; файл с другим
/// именем, но тем же id процесса — отбрасывается, bundled побеждает.
@Observable
final class ConfigServiceImpl: ConfigService {
    private(set) var config: ProcessConfig

    private let settings: SettingsStore
    private let urlSession: URLSession

    init(settings: SettingsStore, urlSession: URLSession) {
        self.settings = settings
        self.urlSession = urlSession
        self.config = Self.assemble(bundled: Self.bundledFiles(), cached: Self.cachedFiles())
    }

    func process(id: String) -> DevelopmentProcess? {
        config.processes.first { $0.id == id }
    }

    func availableProcesses() -> [DevelopmentProcess] {
        #if DEBUG
        config.processes
        #else
        config.processes.filter { !$0.id.hasPrefix("test_") }
        #endif
    }

    func refreshFromRemote() async -> ConfigRefreshResult {
        guard let baseURL = URL(string: settings.remoteURL), baseURL.scheme == "https" else {
            return .insecureURL
        }

        let names: [String]
        switch await fetchIndex(baseURL) {
            case .names(let parsed):
                names = parsed
            case .failed(let result):
                return result
        }

        let outcome = await download(names, from: baseURL)

        // Файл, пропавший из индекса, пропадает и из кэша — иначе процесс живёт вечно.
        for name in Self.cachedFiles().keys where !names.contains(name) {
            Self.removeCache(name: name)
            settings.etags[name] = nil
        }

        settings.lastFetchAt = .now
        config = Self.assemble(bundled: Self.bundledFiles(), cached: Self.cachedFiles())

        if outcome.updated > 0 {
            return .updated(updatedAt: config.updatedAt)
        }
        if let reason = outcome.rejected.first {
            return .rejected(reason: reason)
        }
        return .upToDate
    }

    func resetToBundled() {
        try? FileManager.default.removeItem(at: Self.cacheDirectory)
        settings.etags = [:]
        config = Self.assemble(bundled: Self.bundledFiles(), cached: [:])
    }

    // MARK: - Remote

    private enum IndexOutcome {
        case names([String])
        case failed(ConfigRefreshResult)
    }

    private func fetchIndex(_ baseURL: URL) async -> IndexOutcome {
        switch await fetch(baseURL.appending(path: "index.json"), etag: nil) {
            case .success(let data, _):
                do {
                    return .names(try ConfigParser.parseIndex(data))
                } catch {
                    return .failed(.rejected(reason: String(describing: error)))
                }
            case .notModified:
                return .names(Array(settings.etags.keys))
            case .failed(let statusCode):
                return .failed(.serverError(statusCode: statusCode))
            case .unreachable:
                return .failed(.unreachable)
        }
    }

    /// Пофайлово: валидный — в кэш и ETag, битый или недоступный — в `rejected`,
    /// прежняя версия остаётся.
    private func download(_ names: [String], from baseURL: URL) async -> (updated: Int, rejected: [String]) {
        var updated = 0
        var rejected: [String] = []

        for name in names {
            switch await fetch(baseURL.appending(path: name), etag: settings.etags[name]) {
                case .success(let data, let etag):
                    do {
                        _ = try ConfigParser.parseProcess(data)
                    } catch {
                        rejected.append("\(name): \(error)")
                        continue
                    }
                    Self.writeCache(data, name: name)
                    settings.etags[name] = etag
                    updated += 1
                case .notModified:
                    continue
                case .failed, .unreachable:
                    rejected.append(name)
            }
        }

        return (updated, rejected)
    }

    private enum FetchResult {
        case success(Data, etag: String?)
        case notModified
        case failed(statusCode: Int)
        case unreachable
    }

    private func fetch(_ url: URL, etag: String?) async -> FetchResult {
        var request = URLRequest(url: url, timeoutInterval: 15)

        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        guard let (data, response) = try? await urlSession.data(for: request),
              let httpResponse = response as? HTTPURLResponse else {
            return .unreachable
        }

        switch httpResponse.statusCode {
            case 200:
                return .success(data, etag: httpResponse.value(forHTTPHeaderField: "ETag"))
            case 304:
                return .notModified
            default:
                return .failed(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Files

    private static func assemble(
        bundled: [String: DevelopmentProcess],
        cached: [String: DevelopmentProcess]
    ) -> ProcessConfig {
        let files = bundled.merging(cached) { _, cached in cached }
        let orderedNames = bundled.keys.sorted() + cached.keys.filter { bundled[$0] == nil }.sorted()

        var seen: Set<String> = []
        let processes = orderedNames.compactMap { name -> DevelopmentProcess? in
            guard let process = files[name], seen.insert(process.id).inserted else {
                return nil
            }
            return process
        }

        return ProcessConfig(processes: processes)
    }

    private static func bundledFiles() -> [String: DevelopmentProcess] {
        guard let directory = Bundle.main.url(forResource: "config", withExtension: nil) else {
            fatalError(String(localized: .configBundledMissing))
        }

        do {
            let names = try ConfigParser.parseIndex(try Data(contentsOf: directory.appending(path: "index.json")))

            return try Dictionary(uniqueKeysWithValues: names.map { name in
                (name, try ConfigParser.parseProcess(try Data(contentsOf: directory.appending(path: name))))
            })
        } catch {
            fatalError(String(localized: .configBundledUnparsable(String(describing: error))))
        }
    }

    private static func cachedFiles() -> [String: DevelopmentProcess] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )) ?? []

        return Dictionary(uniqueKeysWithValues: urls.compactMap { url -> (String, DevelopmentProcess)? in
            guard let data = try? Data(contentsOf: url), let process = try? ConfigParser.parseProcess(data) else {
                // Битый кэш — не наш файл или устаревшая схема; следующий refresh перекачает.
                try? FileManager.default.removeItem(at: url)
                return nil
            }
            return (url.lastPathComponent, process)
        })
    }

    private static func writeCache(_ data: Data, name: String) {
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? data.write(to: cacheDirectory.appending(path: name))
    }

    private static func removeCache(name: String) {
        try? FileManager.default.removeItem(at: cacheDirectory.appending(path: name))
    }

    private static var cacheDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "config", directoryHint: .isDirectory)
    }
}
