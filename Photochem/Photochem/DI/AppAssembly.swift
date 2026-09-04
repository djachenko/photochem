import Swinject
import SwinjectAutoregistration

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(SettingsStore.self, initializer: SettingsStore.init)
            .inObjectScope(.container)
        container.autoregister(ConfigService.self, initializer: ConfigServiceImpl.init)
            .inObjectScope(.container)
        container.autoregister(SoundService.self, initializer: SoundServiceImpl.init)
            .inObjectScope(.container)
        container.autoregister(NotificationService.self, initializer: NotificationServiceImpl.init)
            .inObjectScope(.container)
        container.autoregister(LiveActivityService.self, initializer: LiveActivityServiceImpl.init)
            .inObjectScope(.container)
    }
}
