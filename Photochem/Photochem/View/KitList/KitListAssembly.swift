import JustKitDI
import Swinject

struct KitListAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(KitListView.init)
        container.autoregister(NewKitSheet.init)
        container.autoregisterOnMain(KitListViewModel.init)
    }
}
