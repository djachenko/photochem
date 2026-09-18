import JustKitDI
import Swinject
import SwinjectAutoregistration

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(SettingsStore.init)
            .inObjectScope(.container)

        container.autoregister(ConfigServiceImpl.init)
            .implements(ConfigService.self)
            .inObjectScope(.container)

        container.autoregister(SoundServiceImpl.init)
            .implements(SoundService.self)
            .inObjectScope(.container)

        container.autoregister(NotificationServiceImpl.init)
            .implements(NotificationService.self)
            .inObjectScope(.container)

        container.autoregister(LiveActivityServiceImpl.init)
            .implements(LiveActivityService.self)
            .inObjectScope(.container)
    }
}
