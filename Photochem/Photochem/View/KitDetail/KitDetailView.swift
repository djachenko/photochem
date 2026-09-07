import ParaMap
import PhotochemCore
import SwiftData
import SwiftUI
import Swinject
import SwinjectAutoregistration

struct KitDetailView: View {
    let viewModel: KitDetailViewModel

    private let resolver: Resolver

    private var kit: ChemistryKit {
        viewModel.kit
    }

    @State private var isStartingSession = false
    @State private var runningSession: DevelopmentSession?

    init(viewModel: KitDetailViewModel, resolver: Resolver) {
        self.viewModel = viewModel
        self.resolver = resolver
    }

    var body: some View {
        content(viewModel: viewModel)
            .navigationTitle(kit.processName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isStartingSession) {
                if let process = viewModel.process {
                    let onStart: (DevelopmentSession) -> Void = { session in
                        runningSession = session
                    }

                    resolver ~> (NewSessionSheet.self, with: kit, process, onStart)
                }
            }
            .fullScreenCover(item: $runningSession) { session in
                resolver ~> (RunnerView.self, with: session)
            }
    }

    private func content(viewModel: KitDetailViewModel) -> some View {
        List {
            Section {
                LabeledContent(
                    String(localized: .kitDetailMixedAt),
                    value: String(localized: .kitDetailMixedAtValue(kit.mixedAt.formatted(.dateOnly), kit.ageDays))
                )
                LabeledContent(String(localized: .kitDetailMileage)) {
                    if viewModel.process == nil {
                        Text(String(localized: .kitDetailMileageWithoutProcess(viewModel.mileageText)))
                            .foregroundStyle(.red)
                    } else {
                        Text(viewModel.mileageText)
                    }
                }
                if let remainingFilms = viewModel.remainingFilms {
                    LabeledContent(String(localized: .kitDetailRemaining), value: String(localized: .kitDetailRemainingValue(remainingFilms)))
                }
                if let process = viewModel.process {
                    NavigationLink {
                        ProcessSpecView(process: process)
                    } label: {
                        LabeledContent(String(localized: .kitDetailProcess), value: process.name)
                    }
                }
                if let expiryWarning = viewModel.expiryWarning {
                    Text(expiryWarning)
                        .font(.subheadline)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.yellow.opacity(0.25), in: .rect(cornerRadius: 8))
                }
            }

            Section {
                Button(String(localized: .kitDetailNewSession)) {
                    isStartingSession = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.startBlockReason != nil)
                .listRowBackground(Color.clear)
                if let startBlockReason = viewModel.startBlockReason {
                    Text(startBlockReason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }

            sessionsSection(viewModel: viewModel)
        }
        .toolbar {
            Menu(String(localized: .kitDetailMore), systemImage: "ellipsis.circle") {
                Button(kit.isArchived ? String(localized: .kitDetailUnarchive) : String(localized: .kitDetailArchive)) {
                    viewModel.toggleArchived()
                }
            }
        }
    }

    private func sessionsSection(viewModel: KitDetailViewModel) -> some View {
        Section(String(localized: .kitDetailSessionsSection)) {
            if viewModel.sessions.isEmpty {
                Text(String(localized: .kitDetailNoSessions))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.sessions) { session in
                    NavigationLink {
                        SessionHistoryView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: .kitDetailSessionRow(session.startedAt.formatted(.dateAndTime), session.films.count)))
                            Label(session.status.title, systemImage: session.status.iconName)
                                .font(.caption)
                                .foregroundStyle(session.status == .aborted ? .orange : .secondary)
                        }
                    }
                }
            }
        }
    }
}

extension SessionStatus {
    var iconName: String {
        switch self {
        case .completed: "checkmark.circle"
        case .aborted: "xmark.circle"
        case .inProgress: "clock"
        }
    }

    var title: String {
        switch self {
        case .completed: String(localized: .sessionStatusCompleted)
        case .aborted: String(localized: .sessionStatusAborted)
        case .inProgress: String(localized: .sessionStatusInProgress)
        }
    }
}

extension FormatStyle where Self == Date.FormatStyle {
    static var dateOnly: Date.FormatStyle {
        .dateTime.day(.twoDigits).month(.twoDigits).year()
    }

    static var dateAndTime: Date.FormatStyle {
        .dateTime.day(.twoDigits).month(.twoDigits).year().hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
    }
}
