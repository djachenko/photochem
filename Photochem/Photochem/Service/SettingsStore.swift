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
