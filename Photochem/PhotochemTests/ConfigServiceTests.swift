import Foundation
@testable import Photochem
import PhotochemCore
import Testing

// Стаб ответов и кэш на диске общие — тесты не должны идти параллельно.
@Suite(.serialized)
struct ConfigServiceTests {
    @Test("C1: битый файл откатывается, остальные применяются")
    func appliesValidFilesAndKeepsPreviousVersionOfBrokenOne() async throws {
        let (service, settings) = try makeService()
        defer { service.resetToBundled() }

        StubURLProtocol.responses = [
            "index.json": .ok(#"["c41_generic.json", "extra.json"]"#),
            "c41_generic.json": .ok(processJSON(id: "c41_generic", name: "C-41 remote")),
            "extra.json": .ok(processJSON(id: "extra", name: "Extra v1")),
        ]
        #expect(await service.refreshFromRemote() == .updated(updatedAt: "2026-09-19"))
        #expect(service.process(id: "c41_generic")?.name == "C-41 remote")
        #expect(service.process(id: "extra")?.name == "Extra v1")
        #expect(settings.etags.keys.sorted() == ["c41_generic.json", "extra.json"])

        StubURLProtocol.responses["extra.json"] = .ok("{ not json")
        StubURLProtocol.responses["c41_generic.json"] = .notModified

        let result = await service.refreshFromRemote()
        guard case .rejected(let reason) = result else {
            Issue.record("ожидался rejected, получен \(result)")
            return
        }
        #expect(reason.hasPrefix("extra.json"))
        #expect(service.process(id: "extra")?.name == "Extra v1")
        #expect(service.process(id: "c41_generic")?.name == "C-41 remote")
    }

    @Test("C2: файл, пропавший из индекса, уходит из набора")
    func dropsFileMissingFromIndex() async throws {
        let (service, settings) = try makeService()
        defer { service.resetToBundled() }

        StubURLProtocol.responses = [
            "index.json": .ok(#"["extra.json"]"#),
            "extra.json": .ok(processJSON(id: "extra", name: "Extra")),
        ]
        _ = await service.refreshFromRemote()
        #expect(service.process(id: "extra") != nil)

        StubURLProtocol.responses = ["index.json": .ok("[]")]
        #expect(await service.refreshFromRemote() == .upToDate)
        #expect(service.process(id: "extra") == nil)
        #expect(settings.etags.isEmpty)
        #expect(service.process(id: "c41_generic") != nil)
    }

    private func makeService() throws -> (ConfigServiceImpl, SettingsStore) {
        let defaults = try #require(UserDefaults(suiteName: "ConfigServiceTests.\(UUID().uuidString)"))
        let settings = SettingsStore(defaults: defaults)
        settings.remoteURL = "https://config.test/"

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]

        let service = ConfigServiceImpl(settings: settings, urlSession: URLSession(configuration: configuration))
        service.resetToBundled()
        return (service, settings)
    }

    private func processJSON(id: String, name: String) -> String {
        """
        {
          "schema_version": 2,
          "updated_at": "2026-09-19",
          "id": "\(id)",
          "name": "\(name)",
          "capacity_films": 10,
          "shelf_life_days": 28,
          "stages": [{ "id": "dev", "name": "Проявитель", "time": "3:15" }]
        }
        """
    }
}

enum StubResponse {
    case ok(String)
    case notModified
}

nonisolated class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [String: StubResponse] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let name = url.lastPathComponent
        let statusCode: Int
        var body = Data()
        var headers: [String: String] = [:]

        switch Self.responses[name] {
            case .ok(let text):
                statusCode = 200
                body = Data(text.utf8)
                headers["ETag"] = "\"\(name)-\(text.count)\""
            case .notModified:
                statusCode = 304
            case nil:
                statusCode = 404
        }

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
