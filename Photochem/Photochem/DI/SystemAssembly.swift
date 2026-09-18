import AVFoundation
import Foundation
import Swinject
import UserNotifications

struct SystemAssembly: Assembly {
    func assemble(container: Container) {
        // Экранам, которые открывают другие экраны, резолвер приходит через init —
        // как AppCoordinatorView в Cullen, только без координатора.
        container.register(Resolver.self) { $0 }
            .inObjectScope(.weak)

        container.register(UserDefaults.self) { _ in
            .standard
        }
        .inObjectScope(.weak)

        container.register(AVAudioSession.self) { _ in
            .sharedInstance()
        }
        .inObjectScope(.weak)

        container.register(UNUserNotificationCenter.self) { _ in
            .current()
        }
        .inObjectScope(.weak)
    }
}
