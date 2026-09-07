import PhotochemCore
import SwiftData
import SwiftUI

struct NewKitSheet: View {
    private let configService: ConfigService
    private let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss

    @State private var selectedProcessID: String?
    @State private var mixedAt = Date.now

    init(configService: ConfigService, modelContext: ModelContext) {
        self.configService = configService
        self.modelContext = modelContext
    }

    private var processes: [DevelopmentProcess] {
        configService.availableProcesses()
    }

    var body: some View {
        NavigationStack {
            form
                .navigationTitle(String(localized: .newKitTitle))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: .newKitCancel)) {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: .newKitCreate)) {
                            create()
                        }
                        .disabled(selectedProcess == nil)
                    }
                }
        }
    }

    @ViewBuilder
    private var form: some View {
        if processes.isEmpty {
            ContentUnavailableView(String(localized: .newKitNoProcesses), systemImage: "exclamationmark.triangle")
        } else {
            Form {
                Picker(String(localized: .newKitProcess), selection: $selectedProcessID) {
                    ForEach(processes) { process in
                        Text(process.name).tag(process.id as String?)
                    }
                }

                DatePicker(String(localized: .newKitMixedAt), selection: $mixedAt, displayedComponents: .date)

                if let selectedProcess {
                    NavigationLink(String(localized: .newKitProcessTimes)) {
                        ProcessSpecView(process: selectedProcess)
                    }
                }
            }
            .onAppear {
                selectedProcessID = selectedProcessID ?? processes.first?.id
            }
        }
    }

    private var selectedProcess: DevelopmentProcess? {
        processes.first { $0.id == selectedProcessID }
    }

    private func create() {
        guard let process = selectedProcess else {
            return
        }

        modelContext.insert(
            ChemistryKit(
                processID: process.id,
                processName: process.name,
                mixedAt: mixedAt
            )
        )

        try? modelContext.save()

        dismiss()
    }
}
