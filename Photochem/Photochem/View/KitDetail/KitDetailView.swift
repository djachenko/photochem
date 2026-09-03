import SwiftData
import SwiftUI
import SwinjectAutoregistration

struct KitDetailView: View {
    let kit: ChemistryKit

    @Environment(\.diContainer) private var diContainer
    @Environment(\.modelContext) private var modelContext

    private var viewModel: KitDetailViewModel {
        KitDetailViewModel(
            kit: kit,
            configService: diContainer ~> ConfigService.self,
            modelContext: modelContext
        )
    }

    var body: some View {
        content(viewModel: viewModel)
            .navigationTitle(kit.processName)
            .navigationBarTitleDisplayMode(.inline)
    }

    private func content(viewModel: KitDetailViewModel) -> some View {
        List {
            Section {
                LabeledContent("Развёл", value: "\(kit.mixedAt.formatted(.dateOnly)) (\(kit.ageDays) дн назад)")
                LabeledContent("Пробег") {
                    if viewModel.process == nil {
                        Text("\(viewModel.mileageText) · Процесс не найден в конфиге")
                            .foregroundStyle(.red)
                    } else {
                        Text(viewModel.mileageText)
                    }
                }
                if let remainingFilms = viewModel.remainingFilms {
                    LabeledContent("Осталось", value: "\(remainingFilms) плёнок")
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
                Button("Новая проявка") {
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(true)
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
            Menu("Ещё", systemImage: "ellipsis.circle") {
                Button(kit.isArchived ? "Вернуть" : "В архив") {
                    viewModel.toggleArchived()
                }
            }
        }
    }

    private func sessionsSection(viewModel: KitDetailViewModel) -> some View {
        Section("Проявки") {
            if viewModel.sessions.isEmpty {
                Text("Проявок ещё не было")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.sessions) { session in
                    NavigationLink {
                        SessionHistoryView(session: session)
                    } label: {
                        LabeledContent(
                            "\(session.startedAt.formatted(.dateAndTime)) · \(session.films.count) плёнок"
                        ) {
                            Image(systemName: session.status.iconName)
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
        case .completed: "checkmark"
        case .aborted: "xmark"
        case .inProgress: "clock"
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
