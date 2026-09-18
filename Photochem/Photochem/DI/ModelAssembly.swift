import JustKitDI
import SwiftData
import Swinject
import SwinjectAutoregistration

struct ModelAssembly: Assembly {
    var isStoredInMemoryOnly = false

    func assemble(container: Container) {
        container.register(ModelContainer.self) { _ in
            do {
                return try ModelContainer(
                    for: ChemistryKit.self,
                    DevelopmentSession.self,
                    FilmRecord.self,
                    StageSnapshot.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
                )
            } catch {
                fatalError(String(describing: error))
            }
        }
        .inObjectScope(.container)

        container.registerOnMain(ModelContext.self) { resolver in
            (resolver ~> ModelContainer.self).mainContext
        }
    }
}
