import PhotochemCore
import SwiftData
import SwiftUI
import SwinjectAutoregistration

struct NewSessionSheet: View {
    let kit: ChemistryKit
    let process: DevelopmentProcess
    let onStart: (DevelopmentSession) -> Void

    @Environment(\.diContainer) private var diContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: NewSessionViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    form(viewModel: viewModel)
                } else {
                    Color.clear
                }
            }
            .navigationTitle(String(localized: .newSessionTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: .newSessionCancel)) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = NewSessionViewModel(
                    kit: kit,
                    process: process,
                    settings: diContainer ~> SettingsStore.self,
                    modelContext: modelContext
                )
            }
            _ = await (diContainer ~> NotificationService.self).requestAuthorization()
        }
    }

    private func form(viewModel: NewSessionViewModel) -> some View {
        Form {
            Section {
                Stepper(
                    String(localized: .newSessionFilmsInTank(viewModel.filmsInTank)),
                    value: Binding(get: { viewModel.filmsInTank }, set: { viewModel.filmsInTank = $0 }),
                    in: 1...max(1, viewModel.maximumFilms)
                )
            }

            Section {
                ForEach(viewModel.stageTimes, id: \.stage.id) { stageTime in
                    LabeledContent(stageTime.stage.name, value: TimeFormatting.format(seconds: stageTime.seconds))
                }
            } header: {
                Text(String(localized: .newSessionStageTimesSection))
            } footer: {
                Text(viewModel.filmNumbersText)
            }

            Section {
                Button(String(localized: .newSessionStart)) {
                    if let session = viewModel.createSession() {
                        onStart(session)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
    }
}
