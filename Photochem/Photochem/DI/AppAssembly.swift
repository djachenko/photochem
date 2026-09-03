import Swinject
import SwinjectAutoregistration

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(SettingsStore.self, initializer: SettingsStore.init)
            .inObjectScope(.container)
        container.autoregister(ConfigService.self, initializer: ConfigServiceImpl.init)
            .inObjectScope(.container)
    }
}
