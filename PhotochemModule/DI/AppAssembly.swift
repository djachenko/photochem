import JustKitDI
import PhotochemCore
import Swinject
import SwinjectAutoregistration

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        container.register(GeigerCurve.self) { _ in
            .standard
        }

        container.autoregister(SettingsStore.init)
            .inObjectScope(.container)

        container.autoregister(ConfigServiceImpl.init)
            .implements(ConfigService.self)
            .inObjectScope(.container)

        container.autoregister(AlertServiceImpl.init)
            .implements(AlertService.self)
            .inObjectScope(.container)

        container.autoregister(NotificationServiceImpl.init)
            .implements(NotificationService.self)
            .inObjectScope(.container)

        container.autoregister(LiveActivityServiceImpl.init)
            .implements(LiveActivityService.self)
            .inObjectScope(.container)
    }
}
