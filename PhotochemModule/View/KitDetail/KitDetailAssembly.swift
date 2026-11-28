import JustKitDI
import Swinject

struct KitDetailAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(KitDetailView.init)
        container.autoregisterOnMain(KitDetailViewModel.init)
    }
}
