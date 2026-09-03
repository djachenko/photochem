import SwiftUI
import Swinject

@main
struct PhotochemApp: App {
    private let container = Assembler([AppAssembly()]).resolver

    var body: some Scene {
        WindowGroup {
            KitListView()
                .environment(\.diContainer, container)
        }
    }
}
