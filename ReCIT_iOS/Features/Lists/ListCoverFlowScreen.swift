//
//  ListCoverFlowScreen.swift
//  ReCIT_iOS
//
//  A list of works or of authors, as one screen in two halves: the cover flow on top, the
//  element facing the reader below, and — in place of the tab bar — the bar to add one more.
//
//  **The swap between two books is a cross-fade.** Every row that speaks of the selected book is
//  keyed on its uri (`ListCrossFade`) and replaced as a whole, under one short ease, while the
//  covers above follow the finger at every frame. The text never jumps from one book to the next:
//  it dissolves into it.
//
//  An inset grouped list, the forms' (`DesignSystem.FormList`): the cover flow and the title are
//  a first row on the screen's ground, edge to edge, and the comment, the way to the book's page and the
//  way out of the list are rows with the system's own corners.
//
//  **The selection survives the list changing under it.** It is a uri, so an element whose
//  optimistic id is replaced by the server's stays selected; an element removed hands the
//  selection to the one that took its place, or to the last one; and a uri asked for by an add
//  (`selectAfterAdd`) is selected as soon as the list holds it.
//
//  The whole screen is one list: with the comment field focused, the keyboard pushes it up and
//  the cover flow goes under the navigation bar, and the add bar steps aside so that the keyboard
//  is not topped with two buttons that have nothing to do with typing.
//
//  See PRD 0029 and the `Liste détails` section of the Figma file (`843:12721`).
//

import SwiftData
import SwiftUI

struct ListCoverFlowScreen: View {
    let list: EntityList
    @Binding var path: NavigationPath

    @Environment(EntityModel.self) private var entityModel
    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext

    @Query private var items: [EntityListItem]

    @State private var selectedURI: String?
    /// The uri an add has just asked for, selected as soon as the list holds it.
    @State private var selectAfterAdd: String?
    @State private var isPresentingSearch: Bool = false
    @State private var isPresentingScanner: Bool = false
    @FocusState private var isCommentFocused: Bool

    init(list: EntityList, path: Binding<NavigationPath>) {
        self.list = list
        self._path = path
        let listId: String = list._id
        _items = Query(
            filter: #Predicate<EntityListItem> { item in
                item.list?._id == listId
            },
            sort: \EntityListItem.ordinal
        )
    }

    private var liveItems: [EntityListItem] {
        items.filter(\.isStillInTheStore)
    }

    private var uris: [String] {
        liveItems.map(\.uri)
    }

    private var selectedItem: EntityListItem? {
        liveItems.first { $0.uri == selectedURI }
    }

    private var openLabel: LocalizedStringKey {
        list.type == .author ? "list.detail.open.author" : "list.detail.open.work"
    }

    var body: some View {
        DesignSystem.FormList {
            if liveItems.isEmpty {
                Section {
                    Text("list.empty")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            } else {
                // The cover flow and the title, edge to edge on the screen's own ground: a row
                // dressed as a header. A real section header lays its horizontal scroll view out
                // before it has a width, and the strip came up empty.
                Section {
                    VStack(spacing: .zero) {
                        ListCoverFlowView(
                            uris: uris,
                            listType: list.type,
                            selectedURI: $selectedURI,
                            onOpen: open
                        )

                        if let selectedURI {
                            ListCrossFade(id: selectedURI) {
                                ListSelectedTitle(uri: selectedURI, listType: list.type)
                            }
                            .padding(.horizontal, .medium)
                        }
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                // Edge to edge from iOS 26, so the turned covers are not cut at the section's
                // margin; before it the section keeps the list's margins.
                .listSectionHorizontalMargins(0)

                Section {
                    if let selectedItem {
                        ListCrossFade(id: selectedItem.uri) {
                            ListCommentRow(
                                item: selectedItem,
                                listType: list.type,
                                isFocused: $isCommentFocused
                            )
                        }

                        Button(openLabel) {
                            open(selectedItem.uri)
                        }
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundTinted)
                    }
                }

                if let selectedItem {
                    Section {
                        Button("list.detail.remove", role: .destructive) {
                            remove(selectedItem)
                        }
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundError)
                    } footer: {
                        ListCrossFade(id: selectedItem.uri) {
                            Text("list.detail.added \(selectedItem.created.formatted(.dateTime.day().month(.wide).year()))")
                                .textStyle(.footnote200)
                                .foregroundStyle(.foregroundSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .formActionBar(isPresented: isCommentFocused == false) {
            ListAddBar(
                listType: list.type,
                onScan: { isPresentingScanner = true },
                onSearch: { isPresentingSearch = true }
            )
        }
        .fullScreenCover(isPresented: $isPresentingScanner) {
            ListScanView(
                list: list,
                existingURIs: Set(uris),
                onAdd: add,
                onShow: show
            )
        }
        .sheet(isPresented: $isPresentingSearch) {
            ListAddSearchView(
                list: list,
                existingURIs: Set(uris),
                onAdd: add,
                onShow: show
            )
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            // The comment spans lines, so the return key starts a new one: this is the way to
            // say the comment is done, and leaving the field is what writes it.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("action.ok") {
                    isCommentFocused = false
                }
            }
        }
        .onAppear {
            if selectedURI == nil {
                selectedURI = uris.first
            }
        }
        .onChange(of: uris) { oldURIs, newURIs in
            keepSelection(from: oldURIs, to: newURIs)
        }
        .task(id: uris) {
            switch list.type {
            case .work:
                _ = try? await entityModel.getOrFetchWorks(modelContext: modelContext, uris: uris)
            case .author:
                _ = try? await entityModel.getOrFetchAuthors(modelContext: modelContext, uris: uris)
            case .publisher:
                break
            }
        }
    }

    /// Where the selection goes when the list changes: to the uri an add asked for, else it
    /// stays where it is, else it takes the place of the element that left.
    private func keepSelection(from oldURIs: [String], to newURIs: [String]) {
        if let selectAfterAdd, newURIs.contains(selectAfterAdd) {
            selectedURI = selectAfterAdd
            self.selectAfterAdd = nil
            return
        }

        guard let selectedURI, newURIs.contains(selectedURI) == false else {
            if self.selectedURI == nil {
                self.selectedURI = newURIs.first
            }
            return
        }

        let formerIndex: Int = oldURIs.firstIndex(of: selectedURI) ?? 0
        self.selectedURI = newURIs.isEmpty ? nil : newURIs[min(formerIndex, newURIs.count - 1)]
    }

    /// Adds what the scanner or the search chose, and has the list land on the first of it as
    /// soon as it holds it — which, the add being optimistic, is at once.
    private func add(_ addedURIs: [String]) {
        guard let first = addedURIs.first else { return }

        selectAfterAdd = first
        listModel.addEntitiesToList(
            modelContext: modelContext,
            list: list,
            entityUris: addedURIs
        )
    }

    /// Lands on an element the list already holds.
    private func show(_ uri: String) {
        withAnimation(.snappy) {
            selectedURI = uri
        }
    }

    private func open(_ uri: String) {
        switch list.type {
        case .author:
            path.append(NavigationDestination.author(uri: uri))
        case .work, .publisher:
            path.append(NavigationDestination.work(uri: uri))
        }
    }

    private func remove(_ item: EntityListItem) {
        let listId: String = list._id
        let uri: String = item.uri
        Task {
            try? await listModel.deleteElementsInList(
                modelContext: modelContext,
                listId: listId,
                elementIds: [uri]
            )
        }
    }
}
