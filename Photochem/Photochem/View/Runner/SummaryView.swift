import ParaMap
import PhotochemCore
import SwiftUI

struct SummaryView: View {
    let session: DevelopmentSession

    private let onFinish: () -> Void
    private let configService: ConfigService

    init(session: DevelopmentSession, onFinish: @escaping () -> Void, configService: ConfigService) {
        self.session = session
        self.onFinish = onFinish
        self.configService = configService
    }

    var body: some View {
        List {
            Section {
                Text(String(localized: .summaryFilmsDeveloped(session.films.count)))
                if let mileageText {
                    Text(String(localized: .summaryMileageNow(mileageText)))
                }
            }
            Section(String(localized: .summaryStagesSection)) {
                ForEach(session.orderedStages) { stage in
                    LabeledContent(stage.name, value: TimeFormatting.format(seconds: stage.plannedSeconds))
                }
            }
            Section {
                Button(String(localized: .summaryFinish)) {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(String(localized: .summaryTitle))
    }

    private var mileageText: String? {
        guard let kit = session.kit else {
            return nil
        }
        guard let process = configService.process(id: kit.processID) else {
            return "\(kit.mileage)"
        }
        return "\(kit.mileage) из \(process.capacityFilms)"
    }
}

#if DEBUG
#Preview {
    let onFinish: () -> Void = {}

    NavigationStack {
        PreviewEnvironment.resolver ~> (SummaryView.self, with: PreviewEnvironment.session, onFinish)
    }
}
#endif
