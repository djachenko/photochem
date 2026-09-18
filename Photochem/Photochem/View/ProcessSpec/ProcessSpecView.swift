import PhotochemCore
import SwiftUI

struct ProcessSpecView: View {
    let process: DevelopmentProcess

    var body: some View {
        List {
            Section(String(localized: .processSpecKitSection)) {
                LabeledContent(String(localized: .processSpecCapacity), value: String(localized: .processSpecCapacityValue(process.capacityFilms)))
                LabeledContent(String(localized: .processSpecShelfLife), value: String(localized: .processSpecShelfLifeValue(process.shelfLifeDays)))
            }

            ForEach(process.stages) { stage in
                Section {
                    switch stage.timing {
                    case .fixed(let seconds):
                        LabeledContent(String(localized: .processSpecTime), value: TimeFormatting.format(seconds: seconds))
                    case .byFilm(let ranges):
                        ForEach(ranges, id: \.lower) { range in
                            LabeledContent(filmsText(range), value: TimeFormatting.format(seconds: range.seconds))
                        }
                    }
                    if let tempC = stage.tempC {
                        LabeledContent(
                            String(localized: .processSpecTemperature),
                            value: String(
                                localized: .processSpecTemperatureValue(
                                    tempC.formatted(.number.precision(.fractionLength(1)))
                                )
                            )
                        )
                    }
                } header: {
                    Text(stage.name)
                } footer: {
                    if let prepare = stage.prepare {
                        Text(prepare)
                    }
                }
            }
        }
        .navigationTitle(process.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func filmsText(_ range: FilmRange) -> String {
        range.lower == range.upper
            ? String(localized: .processSpecFilm(range.lower))
            : String(localized: .processSpecFilmRange(range.lower, range.upper))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ProcessSpecView(process: PreviewEnvironment.process)
    }
}
#endif
