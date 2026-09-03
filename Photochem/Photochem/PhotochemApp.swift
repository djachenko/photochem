import SwiftData
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
        .modelContainer(for: [ChemistryKit.self, DevelopmentSession.self, FilmRecord.self, StageSnapshot.self])
    }
}
