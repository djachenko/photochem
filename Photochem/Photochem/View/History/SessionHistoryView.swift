import PhotochemCore
import SwiftUI

struct SessionHistoryView: View {
    let session: DevelopmentSession

    var body: some View {
        List {
            Section {
                LabeledContent(String(localized: .historyStatus), value: session.status.title)
                LabeledContent(String(localized: .historyFilms), value: "\(session.films.count)")
            }
            Section(String(localized: .historyStagesSection)) {
                ForEach(session.orderedStages) { stage in
                    LabeledContent(stage.name, value: TimeFormatting.format(seconds: stage.plannedSeconds))
                }
            }
        }
        .navigationTitle(session.startedAt.formatted(.dateAndTime))
        .navigationBarTitleDisplayMode(.inline)
    }
}
