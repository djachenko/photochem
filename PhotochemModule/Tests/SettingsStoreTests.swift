import Foundation
@testable import PhotochemModule
import Testing

@MainActor
struct SettingsStoreTests {
    @Test("Пустые настройки используют URL конфигов модуля")
    func emptySettingsUseModuleConfigURL() throws {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)

        #expect(settings.remoteURL ==
            "https://raw.githubusercontent.com/djachenko/photochem/master/PhotochemModule/Resources/Config/")
        #expect(defaults.object(forKey: "config.remoteURL") == nil)
    }

    @Test("Сохранённый URL сохраняется при повторном создании настроек", arguments: [
        "https://example.org/custom/processes/",
        "https://raw.githubusercontent.com/djachenko/photochem/master/config/",
    ])
    func preservesStoredRemoteURL(url: String) throws {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(url, forKey: "config.remoteURL")

        #expect(SettingsStore(defaults: defaults).remoteURL == url)
        let reopenedDefaults = try #require(UserDefaults(suiteName: suiteName))
        #expect(SettingsStore(defaults: reopenedDefaults).remoteURL == url)
        #expect(reopenedDefaults.string(forKey: "config.remoteURL") == url)
    }
}
