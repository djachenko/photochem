import JustKitDI
import Swinject
import SwinjectAutoregistration

struct RunnerAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(RunnerView.init)
        container.autoregisterOnMain(SessionRunner.init)

        // Не autoregister: см. NewSessionAssembly — колбэк onFinish в parameter pack
        // роняет компилятор.
        container.register(SummaryView.self) { resolver in
            SummaryView(
                session: resolver ~> DevelopmentSession.self,
                onFinish: resolver ~> (() -> Void).self,
                configService: resolver ~> ConfigService.self
            )
        }
    }
}
