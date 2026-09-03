import SwiftUI
import Swinject

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: Resolver = Container()
}

extension EnvironmentValues {
    var diContainer: Resolver {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
