import Foundation
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
            .deletingLastPathComponent()   // PhotochemTests
            .deletingLastPathComponent()   // Photochem
            .appendingPathComponent("Strings/Localizable.xcstrings")
    }
}
