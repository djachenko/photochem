import PhotochemCore
import SwiftUI

struct ProcessSpecView: View {
    let process: DevelopmentProcess

    var body: some View {
        List {
            Section("Комплект") {
                LabeledContent("Ёмкость", value: "\(process.capacityFilms) плёнок")
                LabeledContent("Срок годности", value: "\(process.shelfLifeDays) дн")
            }

            ForEach(process.stages) { stage in
                Section {
                    switch stage.timing {
                    case .fixed(let seconds):
                        LabeledContent("Время", value: TimeFormatting.format(seconds: seconds))
                    case .byFilm(let ranges):
                        ForEach(ranges, id: \.lower) { range in
                            LabeledContent(filmsText(range), value: TimeFormatting.format(seconds: range.seconds))
                        }
                    }
                    if let tempC = stage.tempC {
                        LabeledContent("Температура", value: "\(tempC.formatted(.number.precision(.fractionLength(1))))°C")
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
        range.lower == range.upper ? "Плёнка \(range.lower)" : "Плёнки \(range.lower)–\(range.upper)"
    }
}
