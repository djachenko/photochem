import Swinject
import SwinjectAutoregistration

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        // Экранам, которые открывают другие экраны, резолвер приходит через init —
        // как AppCoordinatorView в Cullen, только без координатора.
        container.register(Resolver.self) { $0 }

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
