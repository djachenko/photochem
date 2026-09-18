import Foundation

@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var tankSize: Int {
        get { defaults.object(forKey: Key.tankSize) as? Int ?? 5 }
        set { defaults.set(newValue, forKey: Key.tankSize) }
    }

    var preAlertSeconds: Int {
        get { defaults.object(forKey: Key.preAlertSeconds) as? Int ?? 10 }
        set { defaults.set(newValue, forKey: Key.preAlertSeconds) }
    }

    var remoteURL: String {
        get { defaults.string(forKey: Key.remoteURL) ?? DefaultConfig.remoteURL }
        set { defaults.set(newValue, forKey: Key.remoteURL) }
    }

    var etag: String? {
        get { defaults.string(forKey: Key.etag) }
        set { defaults.set(newValue, forKey: Key.etag) }
    }

    var lastFetchAt: Date? {
        get { defaults.object(forKey: Key.lastFetchAt) as? Date }
        set { defaults.set(newValue, forKey: Key.lastFetchAt) }
    }

    private enum Key {
        static let tankSize = "settings.tankSize"
        static let preAlertSeconds = "settings.preAlertSeconds"
        static let remoteURL = "config.remoteURL"
        static let etag = "config.etag"
        static let lastFetchAt = "config.lastFetchAt"
    }
}

enum DefaultConfig {
    static let remoteURL = "https://raw.githubusercontent.com/djachenko/photochem/master/config/processes.json"
}
