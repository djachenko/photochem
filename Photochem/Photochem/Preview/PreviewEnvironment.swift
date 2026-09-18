#if DEBUG
import Foundation
import ParaMap
import PhotochemCore
import SwiftData
import Swinject
import SwinjectAutoregistration

/// Сборка приложения для превью: те же ассамблеи, что в бою, но хранилище in-memory
/// и засеяно данными. Превью ходят через настоящий контейнер, а не через параллельные заглушки.
@MainActor
enum PreviewEnvironment {
    static let resolver: Resolver = {
        let resolver = Assembler([
            SystemAssembly(),
            AppAssembly(),
            ModelAssembly(isStoredInMemoryOnly: true),
            KitListAssembly(),
            KitDetailAssembly(),
            NewSessionAssembly(),
            RunnerAssembly(),
            SettingsAssembly(),
        ]).resolver

        seed(into: resolver ~> ModelContext.self)

        return resolver
    }()

    static var modelContainer: ModelContainer {
        resolver ~> ModelContainer.self
    }

    static var process: DevelopmentProcess {
        guard let process = (resolver ~> ConfigService.self).availableProcesses().first else {
            fatalError("В бандле нет ни одного процесса")
        }

        return process
    }

    static var kit: ChemistryKit {
        first(ChemistryKit.self)
    }

    /// Незавершённая проявка — её ждут раннер, саммари и история.
    static var session: DevelopmentSession {
        first(DevelopmentSession.self)
    }

    private static func seed(into context: ModelContext) {
        let kit = ChemistryKit(
            processID: process.id,
            processName: process.name,
            mixedAt: .now.addingTimeInterval(-3 * 24 * 60 * 60)
        )

        context.insert(kit)

        let session = DevelopmentSession(startedAt: .now.addingTimeInterval(-30 * 60), status: .inProgress)

        session.kit = kit
        session.films = [FilmRecord(orderIndex: 0), FilmRecord(orderIndex: 1)]
        session.stages = stages(filmsInTank: session.films.count)

        context.insert(session)
    }

    private static func stages(filmsInTank: Int) -> [StageSnapshot] {
        let times = (try? TimeCalculator.stageTimes(
            process: process,
            currentMileage: 0,
            filmsInTank: filmsInTank
        )) ?? []

        return times.enumerated().map { index, time in
            StageSnapshot(
                orderIndex: index,
                stageID: time.stage.id,
                name: time.stage.name,
                prepare: time.stage.prepare,
                tempC: time.stage.tempC,
                plannedSeconds: time.seconds,
                preAlertSeconds: time.stage.preAlertOverrideSeconds ?? Constants.preAlertSeconds
            )
        }
    }

    private static func first<T: PersistentModel>(_ type: T.Type) -> T {
        guard let model = try? (resolver ~> ModelContext.self).fetch(FetchDescriptor<T>()).first else {
            fatalError("Превью-хранилище пустое: нет \(T.self)")
        }

        return model
    }
}
#endif
