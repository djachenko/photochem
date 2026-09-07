import JustKitDI
import SwiftData
import Swinject
import SwinjectAutoregistration

struct ModelAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ModelContainer.self) { _ in
            try! ModelContainer(
                for: ChemistryKit.self, DevelopmentSession.self, FilmRecord.self, StageSnapshot.self
            )
        }
        .inObjectScope(.container)

        container.registerOnMain(ModelContext.self) { resolver in
            (resolver ~> ModelContainer.self).mainContext
        }
    }
}
