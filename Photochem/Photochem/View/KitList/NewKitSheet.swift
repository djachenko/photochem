import PhotochemCore
import SwiftData
import SwiftUI
import SwinjectAutoregistration

struct NewKitSheet: View {
    @Environment(\.diContainer) private var diContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProcessID: String?
    @State private var mixedAt = Date.now

    private var processes: [DevelopmentProcess] {
        (diContainer ~> ConfigService.self).availableProcesses()
    }

    var body: some View {
        NavigationStack {
            form
                .navigationTitle("Новый комплект")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Создать") {
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
            ContentUnavailableView("В конфиге нет процессов", systemImage: "exclamationmark.triangle")
        } else {
            Form {
                Picker("Процесс", selection: $selectedProcessID) {
                    ForEach(processes) { process in
                        Text(process.name).tag(process.id as String?)
                    }
                }
                DatePicker("Развёл", selection: $mixedAt, displayedComponents: .date)
                if let selectedProcess {
                    NavigationLink("Времена процесса") {
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
            ChemistryKit(processID: process.id, processName: process.name, mixedAt: mixedAt)
        )
        try? modelContext.save()
        dismiss()
    }
}
