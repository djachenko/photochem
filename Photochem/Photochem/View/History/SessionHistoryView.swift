import PhotochemCore
import SwiftUI

struct SessionHistoryView: View {
    let session: DevelopmentSession

    var body: some View {
        List {
            Section {
                LabeledContent("Статус", value: session.status.title)
                LabeledContent("Плёнок", value: "\(session.films.count)")
            }
            Section("Этапы") {
                ForEach(session.orderedStages) { stage in
                    LabeledContent(stage.name, value: TimeFormatting.format(seconds: stage.plannedSeconds))
                }
            }
        }
        .navigationTitle(session.startedAt.formatted(.dateAndTime))
        .navigationBarTitleDisplayMode(.inline)
    }
}
