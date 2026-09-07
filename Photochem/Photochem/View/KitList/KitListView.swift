import JustKitDI
import SwiftData
import SwiftUI
import SwinjectAutoregistration

struct KitListView: View {
    @Environment(\.diContainer) private var diContainer
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<ChemistryKit> { $0.archivedAt == nil }, sort: \ChemistryKit.mixedAt, order: .reverse)
    private var activeKits: [ChemistryKit]

    @Query(filter: #Predicate<ChemistryKit> { $0.archivedAt != nil }, sort: \ChemistryKit.archivedAt, order: .reverse)
    private var archivedKits: [ChemistryKit]

    @State private var viewModel: KitListViewModel?
    @State private var isCreatingKit = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(String(localized: .kitListTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label(String(localized: .kitListSettings), systemImage: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: .kitListNewKit), systemImage: "plus") {
                            isCreatingKit = true
                        }
                    }
                }
                .sheet(isPresented: $isCreatingKit) {
                    NewKitSheet()
                }
        }
        .task {
            if viewModel == nil {
                viewModel = KitListViewModel(
                    configService: diContainer ~> ConfigService.self,
                    modelContext: modelContext
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if activeKits.isEmpty, archivedKits.isEmpty {
                ContentUnavailableView(
                    String(localized: .kitListEmptyTitle),
                    systemImage: "flask",
                    description: Text(String(localized: .kitListEmptyDescription))
                )
            } else {
                kitList(viewModel: viewModel)
            }
        }
    }

    private func kitList(viewModel: KitListViewModel) -> some View {
        List {
            Section(String(localized: .kitListActiveSection)) {
                ForEach(activeKits) { kit in
                    row(kit, viewModel: viewModel)
                        .swipeActions {
                            Button(String(localized: .kitListArchive)) {
                                viewModel.archive(kit)
                            }
                        }
                }
            }

            if !archivedKits.isEmpty {
                Section(String(localized: .kitListArchiveSection)) {
                    ForEach(archivedKits) { kit in
                        row(kit, viewModel: viewModel)
                            .foregroundStyle(.secondary)
                            .swipeActions {
                                Button(String(localized: .kitListDelete), role: .destructive) {
                                    viewModel.kitPendingDeletion = kit
                                }

                                Button(String(localized: .kitListUnarchive)) {
                                    viewModel.unarchive(kit)
                                }
                            }
                    }
                }
            }
        }
        .confirmationDialog(
            String(localized: .kitListDeleteConfirmation),
            isPresented: Binding(
                get: { viewModel.kitPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.kitPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: .kitListDelete), role: .destructive) {
                viewModel.confirmDeletion()
            }

            Button(String(localized: .kitListCancel), role: .cancel) {
                viewModel.kitPendingDeletion = nil
            }
        }
    }

    private func row(_ kit: ChemistryKit, viewModel: KitListViewModel) -> some View {
        NavigationLink {
            KitDetailView(kit: kit)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(kit.processName)
                    .fontWeight(.bold)

                HStack(spacing: 6) {
                    Text(viewModel.subtitle(for: kit))
                        .font(.subheadline)
                        .foregroundStyle(viewModel.isExpired(kit) ? .orange : .secondary)

                    if viewModel.isExpired(kit) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }

                    if viewModel.isExhausted(kit) {
                        Text(String(localized: .kitListExhausted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
