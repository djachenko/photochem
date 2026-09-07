import JustKitDI
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
            Section(String(localized: .settingsDevelopmentSection)) {
                Stepper(String(localized: .settingsTankSize(tankSize)), value: $tankSize, in: 1...10)
                Picker(String(localized: .settingsPreAlert), selection: $preAlertSeconds) {
                    ForEach([5, 10, 15, 20], id: \.self) { seconds in
                        Text(seconds.formatted()).tag(seconds)
                    }
                }
            }

            Section(String(localized: .settingsProcessesSection)) {
                ForEach(configService.availableProcesses()) { process in
                    NavigationLink(process.name) {
                        ProcessSpecView(process: process)
                    }
                }
            }

            Section {
                LabeledContent(String(localized: .settingsUpdatedAt), value: configService.config.updatedAt)
                LabeledContent(String(localized: .settingsLastFetch), value: lastFetchText)
                TextField(String(localized: .settingsURL), text: $remoteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(String(localized: .settingsRefresh)) {
                    refresh()
                }
                .disabled(isRefreshing)
                Button(String(localized: .settingsResetToBundled)) {
                    configService.resetToBundled()
                    statusMessage = String(localized: .settingsBundledApplied)
                }
            } header: {
                Text(String(localized: .settingsConfigSection))
            } footer: {
                if let statusMessage {
                    Text(statusMessage)
                }
            }
        }
        .navigationTitle(String(localized: .settingsTitle))
        .alert(String(localized: .settingsFailureTitle), isPresented: .constant(failureMessage != nil)) {
            Button(String(localized: .settingsOk)) {
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
        settings.lastFetchAt.map { $0.formatted(.dateAndTime) } ?? String(localized: .settingsNever)
    }

    private func refresh() {
        isRefreshing = true
        Task {
            let result = await configService.refreshFromRemote()
            isRefreshing = false
            switch result {
            case .upToDate:
                statusMessage = String(localized: .settingsConfigUpToDate)
            case .updated(let updatedAt):
                statusMessage = String(localized: .settingsConfigUpdated(updatedAt))
            case .rejected(let reason):
                failureMessage = String(localized: .settingsConfigRejected(reason))
            case .serverError(let statusCode):
                failureMessage = String(localized: .settingsServerError(statusCode))
            case .unreachable:
                failureMessage = String(localized: .settingsUnreachable)
            case .insecureURL:
                failureMessage = String(localized: .settingsInsecureURL)
            }
        }
    }
}
