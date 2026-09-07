import ParaMap
import SwiftData
import SwiftUI
import Swinject
import SwinjectAutoregistration

struct KitListView: View {
    @State private var viewModel: KitListViewModel

    private let resolver: Resolver

    @Query(filter: #Predicate<ChemistryKit> { $0.archivedAt == nil }, sort: \ChemistryKit.mixedAt, order: .reverse)
    private var activeKits: [ChemistryKit]

    @Query(filter: #Predicate<ChemistryKit> { $0.archivedAt != nil }, sort: \ChemistryKit.archivedAt, order: .reverse)
    private var archivedKits: [ChemistryKit]

    @State private var isCreatingKit = false

    init(viewModel: KitListViewModel, resolver: Resolver) {
        _viewModel = State(initialValue: viewModel)
        self.resolver = resolver
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(String(localized: .kitListTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            resolver ~> SettingsView.self
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
                    resolver ~> NewKitSheet.self
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if activeKits.isEmpty, archivedKits.isEmpty {
            ContentUnavailableView(
                String(localized: .kitListEmptyTitle),
                systemImage: "flask",
                description: Text(String(localized: .kitListEmptyDescription))
            )
        } else {
            kitList
        }
    }

    private var kitList: some View {
        List {
            Section(String(localized: .kitListActiveSection)) {
                ForEach(activeKits) { kit in
                    row(kit)
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
                        row(kit)
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

    private func row(_ kit: ChemistryKit) -> some View {
        NavigationLink {
            resolver ~> (KitDetailView.self, with: kit)
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
