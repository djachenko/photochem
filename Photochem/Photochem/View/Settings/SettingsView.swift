import PhotochemCore
import SwiftUI
import SwinjectAutoregistration

struct SettingsView: View {
    @Environment(\.diContainer) private var diContainer

    @State private var tankSize = 5
    @State private var preAlertSeconds = 10
    @State private var remoteURL = ""
    @State private var isRefreshing = false
    @State private var statusMessage: String?
    @State private var failureMessage: String?

    private var settings: SettingsStore {
        diContainer ~> SettingsStore.self
    }

    private var configService: ConfigService {
        diContainer ~> ConfigService.self
    }

    var body: some View {
        Form {
            Section("Проявка") {
                Stepper("Бачок, плёнок: \(tankSize)", value: $tankSize, in: 1...10)
                Picker("Предупик, сек", selection: $preAlertSeconds) {
                    ForEach([5, 10, 15, 20], id: \.self) { seconds in
                        Text("\(seconds)").tag(seconds)
                    }
                }
            }

            Section {
                LabeledContent("Версия от", value: configService.config.updatedAt)
                LabeledContent("Обновлён", value: lastFetchText)
                TextField("URL", text: $remoteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Обновить сейчас") {
                    refresh()
                }
                .disabled(isRefreshing)
                Button("Сбросить на встроенный") {
                    configService.resetToBundled()
                    statusMessage = "Встроенный конфиг применён"
                }
            } header: {
                Text("Конфиг")
            } footer: {
                if let statusMessage {
                    Text(statusMessage)
                }
            }
        }
        .navigationTitle("Настройки")
        .alert("Конфиг не обновлён", isPresented: .constant(failureMessage != nil)) {
            Button("Ок") {
                failureMessage = nil
            }
        } message: {
            if let failureMessage {
                Text(failureMessage)
            }
        }
        .onAppear {
            tankSize = settings.tankSize
            preAlertSeconds = settings.preAlertSeconds
            remoteURL = settings.remoteURL
        }
        .onChange(of: tankSize) { _, newValue in
            settings.tankSize = newValue
        }
        .onChange(of: preAlertSeconds) { _, newValue in
            settings.preAlertSeconds = newValue
        }
        .onChange(of: remoteURL) { _, newValue in
            settings.remoteURL = newValue
            settings.etag = nil
        }
    }

    private var lastFetchText: String {
        settings.lastFetchAt.map { $0.formatted(.dateAndTime) } ?? "—"
    }

    private func refresh() {
        isRefreshing = true
        Task {
            let result = await configService.refreshFromRemote()
            isRefreshing = false
            switch result {
            case .upToDate:
                statusMessage = "Конфиг актуален"
            case .updated(let updatedAt):
                statusMessage = "Конфиг обновлён (от \(updatedAt))"
            case .rejected(let reason):
                failureMessage = "Конфиг отклонён: \(reason)"
            case .serverError(let statusCode):
                failureMessage = "Ошибка сервера: \(statusCode)"
            case .unreachable:
                failureMessage = "Нет сети или сервер недоступен"
            case .insecureURL:
                failureMessage = "Только https"
            }
        }
    }
}
