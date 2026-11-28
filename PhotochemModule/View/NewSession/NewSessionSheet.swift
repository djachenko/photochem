import ParaMap
import PhotochemCore
import SwiftData
import SwiftUI

struct NewSessionSheet: View {
    @State private var viewModel: NewSessionViewModel

    private let onStart: (DevelopmentSession) -> Void
    private let notificationService: NotificationService

    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: NewSessionViewModel,
        onStart: @escaping (DevelopmentSession) -> Void,
        notificationService: NotificationService
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onStart = onStart
        self.notificationService = notificationService
    }

    var body: some View {
        NavigationStack {
            form
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
            _ = await notificationService.requestAuthorization()
        }
    }

    private var form: some View {
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

#if DEBUG
#Preview {
    let onStart: (DevelopmentSession) -> Void = { _ in }

    PreviewEnvironment.resolver ~> (
        NewSessionSheet.self,
        with: PreviewEnvironment.kit,
        PreviewEnvironment.process,
        onStart
    )
}
#endif
