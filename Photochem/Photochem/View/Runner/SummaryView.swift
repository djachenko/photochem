import PhotochemCore
import SwiftUI
import SwinjectAutoregistration

struct SummaryView: View {
    let session: DevelopmentSession
    let onFinish: () -> Void

    @Environment(\.diContainer) private var diContainer

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
        guard let process = (diContainer ~> ConfigService.self).process(id: kit.processID) else {
            return "\(kit.mileage)"
        }
        return "\(kit.mileage) из \(process.capacityFilms)"
    }
}
