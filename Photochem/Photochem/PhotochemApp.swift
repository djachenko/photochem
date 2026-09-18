import SwiftData
import SwiftUI
import Swinject
import SwinjectAutoregistration

@main
struct PhotochemApp: App {
    var body: some Scene {
        WindowGroup {
            (Self.resolver ~> KitListView.self)
                .sessionRecoveryDialog()
        }
        .modelContainer(Self.resolver ~> ModelContainer.self)
    }
}

extension PhotochemApp {
    static let resolver = Assembler([
        SystemAssembly(),
        AppAssembly(),
        ModelAssembly(),
        KitListAssembly(),
        KitDetailAssembly(),
        NewSessionAssembly(),
        RunnerAssembly(),
        SettingsAssembly(),
    ]).resolver
}
