import SwiftData
import SwiftUI
import Swinject
import SwinjectAutoregistration

@MainActor
public final class PhotochemModule {
    public static let title = "Photochem"
    public static let symbol = "flask"

    private let assembler: Assembler

    public init() {
        assembler = Assembler([
            SystemAssembly(),
            AppAssembly(),
            ModelAssembly(),
            KitListAssembly(),
            KitDetailAssembly(),
            NewSessionAssembly(),
            RunnerAssembly(),
            SettingsAssembly(),
        ])
    }

    public func rootView() -> some View {
        (assembler.resolver ~> KitListView.self)
            .sessionRecoveryDialog()
            .modelContainer(assembler.resolver ~> ModelContainer.self)
    }
}
