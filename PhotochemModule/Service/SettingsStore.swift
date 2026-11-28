import Foundation

@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var tankSize: Int {
        get { defaults.object(forKey: Key.tankSize) as? Int ?? Constants.tankSize }
        set { defaults.set(newValue, forKey: Key.tankSize) }
    }

    /// nil — пользователь ничего не выставлял, окно берётся из конфига.
    var preAlertSeconds: Int? {
        get { defaults.object(forKey: Key.preAlertSeconds) as? Int }
        set { defaults.set(newValue, forKey: Key.preAlertSeconds) }
    }

    var remoteURL: String {
        get { defaults.string(forKey: Key.remoteURL) ?? Constants.remoteConfigURL }
        set { defaults.set(newValue, forKey: Key.remoteURL) }
    }

    /// ETag по имени файла конфига — remote отдаёт процессы пофайлово.
    var etags: [String: String] {
        get { defaults.dictionary(forKey: Key.etags) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Key.etags) }
    }

    var lastFetchAt: Date? {
        get { defaults.object(forKey: Key.lastFetchAt) as? Date }
        set { defaults.set(newValue, forKey: Key.lastFetchAt) }
    }

    private enum Key {
        static let tankSize = "settings.tankSize"
        static let preAlertSeconds = "settings.preAlertSeconds"
        static let remoteURL = "config.remoteURL"
        static let etags = "config.etags"
        static let lastFetchAt = "config.lastFetchAt"
    }
}
