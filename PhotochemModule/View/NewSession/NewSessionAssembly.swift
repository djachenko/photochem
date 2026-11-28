import JustKitDI
import Swinject
import SwinjectAutoregistration

struct NewSessionAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregisterOnMain(NewSessionViewModel.init)

        // Не autoregister: swift-frontend падает на parameter pack, в элементах
        // которого есть функциональный тип — здесь это колбэк onStart.
        container.register(NewSessionSheet.self) { resolver in
            NewSessionSheet(
                viewModel: resolver ~> NewSessionViewModel.self,
                onStart: resolver ~> ((DevelopmentSession) -> Void).self,
                notificationService: resolver ~> NotificationService.self
            )
        }
    }
}
