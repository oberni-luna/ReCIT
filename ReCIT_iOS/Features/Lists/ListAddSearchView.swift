//
//  ListAddSearchView.swift
//  ReCIT_iOS
//
//  The sheet « Rechercher » opens over a list: one field, and what answers it — the books on this
//  device first (« Dans mes livres et chez mes amis »), then the works inventaire.io knows. A list of
//  authors asks inventaire.io for authors and nothing else: the books I hold are not authors.
//
//  **One book at a time.** The « + » of a result adds it and closes the sheet, and the list is
//  shown on the book just added. A book of mine or of a friend's is added as its work — a list holds
//  works, not copies — read from its edition, which is fetched again when the store has not met its
//  works yet. An edition that holds several works asks which, with « Toutes les œuvres » last.
//
//  The remote call follows `FindGroupsView`: `.task(id:)` on the query, a short wait so that a word
//  typed makes one request, and the same key cancelling a call whose query has moved on. Under three
//  characters nothing is asked, as in Recherche (`SearchPhase`).
//
//  See PRD 0029 and the `R1`–`R3` frames of the `Liste détails` section in the Figma file.
//

import SwiftData
import SwiftUI

struct ListAddSearchView: View {
    let list: EntityList
    /// The uris the list holds, which arrive with a check rather than a « + ».
    let existingURIs: Set<String>
    /// Adds these uris and selects the first; called just before the sheet goes.
    let onAdd: ([String]) -> Void
    /// Selects a uri the list already holds; called just before the sheet goes.
    let onShow: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SearchModel.self) private var searchModel
    @Environment(EntityModel.self) private var entityModel
    @Environment(UserModel.self) private var userModel

    @Query(sort: \InventoryItem.created, order: .reverse) private var items: [InventoryItem]

    @State private var query: String = ""
    @State private var remoteResults: [SearchResult] = []
    @State private var isSearching: Bool = false
    @State private var hasFailed: Bool = false
    @State private var resolvingItemId: String?
    @State private var workChoice: ListWorkChoice?

    /// Matches past this many characters, as in Recherche.
    private static let threshold: Int = 3
    /// How many of my books and my friends' are shown above inventaire.io's answer.
    private static let localLimit: Int = 5

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAuthorList: Bool {
        list.type == .author
    }

    private var localItems: [InventoryItem] {
        guard isAuthorList == false, trimmedQuery.count >= Self.threshold, let ownerId = userModel.myUser?._id else {
            return []
        }

        return InventorySearchRanking.rankItems(
            items,
            matching: trimmedQuery,
            ownerId: ownerId,
            limit: Self.localLimit
        ).items
    }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    if trimmedQuery.count < Self.threshold {
                        EmptyStateView(
                            glyph: "magnifyingglass",
                            title: isAuthorList ? "list.add.search.title.author" : "list.add.search.title.work",
                            message: isAuthorList ? "list.add.search.explanation.author" : "list.add.search.explanation.work"
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        if localItems.isEmpty == false {
                            Section {
                                ForEach(localItems, id: \._id) { item in
                                    localRow(item)
                                }
                            } header: {
                                sectionHeader("list.add.search.local")
                            }
                        }

                        Section {
                            remoteSection
                        } header: {
                            sectionHeader(isAuthorList ? "list.add.search.humans" : "list.add.search.works")
                        }
                    }
                }
                .textCase(nil)
            }
            .applyListBackground(.backgroundForm)
            .navigationTitle(Text("list.add.title \(list.name)"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(isAuthorList ? "list.add.search.prompt.author" : "list.add.search.prompt.work")
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .task(id: trimmedQuery) {
                await search()
            }
            .confirmationDialog(
                Text("list.add.choose.title"),
                isPresented: isChoosing,
                titleVisibility: .visible,
                presenting: workChoice
            ) { choice in
                ForEach(choice.works) { work in
                    Button(work.title) {
                        finish([work.uri])
                    }
                }

                Button("list.add.choose.all") {
                    finish(choice.works.map(\.uri))
                }
            } message: { _ in
                Text("list.add.choose.message \(list.name)")
            }
        }
    }

    private var isChoosing: Binding<Bool> {
        .init(
            get: { workChoice != nil },
            set: { isPresented in
                if isPresented == false {
                    workChoice = nil
                }
            }
        )
    }

    @ViewBuilder
    private var remoteSection: some View {
        if isSearching && remoteResults.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if hasFailed {
            Text("list.add.search.error")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
        } else if remoteResults.isEmpty {
            Text("list.add.search.empty")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
        } else {
            ForEach(remoteResults) { result in
                ListAddResultRow(
                    imageUrl: result.imageUrl,
                    title: result.title,
                    subtitle: result.description,
                    isRound: isAuthorList,
                    isInList: existingURIs.contains(result.uri),
                    isBusy: false
                ) {
                    finish([result.uri])
                }
            }
        }
    }

    private func localRow(_ item: InventoryItem) -> some View {
        ListAddResultRow(
            imageUrl: item.edition?.image,
            title: item.edition?.title ?? "",
            subtitle: ownerLine(item),
            isRound: false,
            isInList: item.workUris.contains { existingURIs.contains($0) },
            isBusy: resolvingItemId == item._id
        ) {
            Task {
                await add(item)
            }
        }
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .textStyle(.action200)
            .foregroundStyle(.foregroundSecondary)
    }

    /// « Dans mes livres », or whose shelf the copy is on.
    private func ownerLine(_ item: InventoryItem) -> String {
        if item.ownerId == userModel.myUser?._id {
            String(localized: "list.add.mine")
        } else {
            String(localized: "list.add.owner \(item.owner?.username ?? "")")
        }
    }

    /// Adds a copy's work — asking which, when its edition holds several. The edition is read
    /// again when the store does not know its works yet: a copy synced from a snapshot often
    /// arrives without them.
    private func add(_ item: InventoryItem) async {
        guard let edition = item.edition else { return }

        var works: [Work] = edition.works
        if works.isEmpty {
            resolvingItemId = item._id
            defer { resolvingItemId = nil }
            let editionUri: String = edition.uri
            works = (try? await entityModel.refreshEdition(modelContext: modelContext, uri: editionUri))?.works ?? []
        }

        let options: [ListWorkOption] = works.map { .init(uri: $0.uri, title: $0.title) }
        if options.count > 1 {
            workChoice = .init(works: options)
        } else {
            finish(options.map(\.uri))
        }
    }

    private func finish(_ uris: [String]) {
        switch ListAdditionPlan.plan(chosen: uris, existing: existingURIs) {
        case .add(let missing):
            onAdd(missing)
            dismiss()
        case .alreadyInList(let uri):
            onShow(uri)
            dismiss()
        case .nothing:
            break
        }
    }

    /// `.task(id:)` cancels the previous run, so a word typed makes one request.
    private func search() async {
        guard trimmedQuery.count >= Self.threshold else {
            remoteResults = []
            hasFailed = false
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }

        isSearching = true
        defer { isSearching = false }
        do {
            remoteResults = try await searchModel.searchEntity(
                query: trimmedQuery,
                entityTypes: [isAuthorList ? .humans : .works]
            )
            hasFailed = false
        } catch is CancellationError {
            return
        } catch {
            remoteResults = []
            hasFailed = true
        }
    }
}
