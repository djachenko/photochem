import JustKittenDI
import Swinject

struct SettingsAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(SettingsView.init)
    }
}
