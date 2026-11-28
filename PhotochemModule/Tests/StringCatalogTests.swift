import AVFoundation
import Foundation
@testable import PhotochemModule
import Testing

/// Интерполированный `Text("\(x)")` компилируется в `LocalizedStringKey`, и Xcode
/// заводит в каталоге ключ вроде `%lld` при каждой сборке. Наши ключи — всегда
/// идентификаторы, так что чужак виден по имени.
struct StringCatalogTests {
    @Test("S1")
    func everyKeyIsAnIdentifier() throws {
        let data = try Data(contentsOf: Self.catalogURL)
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = try #require(catalog?["strings"] as? [String: Any])

        let extracted = strings.keys.filter { key in
            !key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        }

        #expect(extracted.isEmpty, "В каталоге автоизвлечённые ключи: \(extracted.sorted())")
    }

    private static var catalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // PhotochemModule
            .appendingPathComponent("Resources/Strings/Localizable.xcstrings")
    }
}

struct PackageResourceTests {
    @Test("Встроенные процессы доступны без ресурсов оболочки")
    @MainActor
    func bundledProcessesLoadFromPackage() throws {
        let defaults = try #require(UserDefaults(suiteName: "PackageResourceTests.\(UUID().uuidString)"))
        let service = ConfigServiceImpl(
            settings: SettingsStore(defaults: defaults),
            urlSession: .shared,
            fileManager: FileManager()
        )
        #expect(service.process(id: "c41_generic") != nil)
        #expect(service.process(id: "test_fast") != nil)
    }

    @Test("Русские строки загружаются из бандла пакета")
    func localizedStringsResolveFromPackage() {
        #expect(String(localized: .kitListTitle) == "Химия")
    }

    @Test("Сигналы воспроизводятся из пакета", arguments: ["sound_pre", "sound_tick", "sound_end"])
    func audioFilesArePlayable(name: String) throws {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "caf"))
        let player = try AVAudioPlayer(contentsOf: url)
        #expect(player.duration > 0)
        #expect(player.duration <= 3)
    }

    @Test("Звуки уведомлений устанавливаются в Library/Sounds и обновляются")
    func notificationSoundsAreInstalled() throws {
        let library = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let fileManager = FileManager()
        defer { try? fileManager.removeItem(at: library) }

        try NotificationSounds.install(fileManager: fileManager, in: library)
        for name in ["sound_pre", "sound_end"] {
            let source = try #require(Bundle.module.url(forResource: name, withExtension: "caf"))
            let destination = library.appending(path: "Sounds/\(name).caf")
            let expected = try Data(contentsOf: source)
            #expect(try Data(contentsOf: destination) == expected)
            try Data().write(to: destination)
        }
        try NotificationSounds.install(fileManager: fileManager, in: library)
        #expect(try !Data(contentsOf: library.appending(path: "Sounds/sound_end.caf")).isEmpty)
    }
}
