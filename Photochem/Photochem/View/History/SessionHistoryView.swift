import PhotochemCore
import SwiftUI

struct SessionHistoryView: View {
    let session: DevelopmentSession

    var body: some View {
        List {
            Section {
                LabeledContent("Статус", value: statusText)
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

    private var statusText: String {
        switch session.status {
        case .completed: "Завершена"
        case .aborted: "Прервана"
        case .inProgress: "Не завершена"
        }
    }
}
