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
                .navigationTitle("Химия")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Новый комплект", systemImage: "plus") {
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
                ContentUnavailableView("Нет комплектов", systemImage: "flask", description: Text("Нажми «+» и добавь первый"))
            } else {
                kitList(viewModel: viewModel)
            }
        }
    }

    private func kitList(viewModel: KitListViewModel) -> some View {
        List {
            Section("Активные") {
                ForEach(activeKits) { kit in
                    row(kit, viewModel: viewModel)
                        .swipeActions {
                            Button("В архив") {
                                viewModel.archive(kit)
                            }
                        }
                }
            }
            if !archivedKits.isEmpty {
                Section("Архив") {
                    ForEach(archivedKits) { kit in
                        row(kit, viewModel: viewModel)
                            .foregroundStyle(.secondary)
                            .swipeActions {
                                Button("Удалить", role: .destructive) {
                                    viewModel.kitPendingDeletion = kit
                                }
                                Button("Вернуть") {
                                    viewModel.unarchive(kit)
                                }
                            }
                    }
                }
            }
        }
        .confirmationDialog(
            "Удалить комплект и всю его историю?",
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
            Button("Удалить", role: .destructive) {
                viewModel.confirmDeletion()
            }
            Button("Отмена", role: .cancel) {
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
                        Text("⚠️")
                            .font(.subheadline)
                    }
                    if viewModel.isExhausted(kit) {
                        Text("Исчерпан")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
