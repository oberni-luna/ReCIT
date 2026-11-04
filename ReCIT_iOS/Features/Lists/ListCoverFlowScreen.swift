//
//  ListCoverFlowScreen.swift
//  ReCIT_iOS
//
//  A list of works or of authors, as two pages side by side in a `TabPager`, turned by a swipe or
//  by their tab: « Livres • 8 », the cover flow on top, the element facing the reader below and —
//  in place of the tab bar — the bar to add one more (`ListElementsPage`); and « Présentation »,
//  the list's description and what the list is (`ListPresentationPage`). Each is an inset grouped
//  list of its own (`DesignSystem.FormList`), keeping its own scroll.
//
//  **The tabs are laid over the pages**, pinned under the navigation bar (`listDetailTabsBar`),
//  each page leaving room for them at its top (`listDetailTabsRoom`). A swipe on the covers
//  scrolls the covers; anywhere else on « Livres » it turns the page. While the comment is written
//  the pager holds still, so the field does not leave with the keyboard up.
//
//  **The selection survives the list changing under it.** It is a uri, so an element whose
//  optimistic id is replaced by the server's stays selected; an element removed hands the
//  selection to the one that took its place, or to the last one; and a uri asked for by an add
//  (`selectAfterAdd`) is selected as soon as the list holds it.
//
//  **A friend's list is read, not written.** Opened from their profile, the same screen keeps the
//  covers, the title and their comment, and drops everything that writes: the add bar (the tab
//  bar stays), « Mon commentaire », « Déplacer » and « Retirer de la liste ». Derived from the
//  list's creator, never passed in. See PRD 0031.
//
//  See PRD 0029 and the `Liste détails` section of the Figma file (`843:12721`); the tabs, its
//  `Liste détails · Description de la liste` section (`909:1465`).
//

import SwiftData
import SwiftUI

struct ListCoverFlowScreen: View {
    let list: EntityList
    @Binding var path: NavigationPath

    @Environment(EntityModel.self) private var entityModel
    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext
    @Environment(UserModel.self) private var userModel

    @Query private var items: [EntityListItem]

    @State private var tab: ListDetailTab = .elements
    @State private var selectedURI: String?
    /// The uri an add has just asked for, selected as soon as the list holds it.
    @State private var selectAfterAdd: String?
    @State private var isPresentingSearch: Bool = false
    @State private var isPresentingScanner: Bool = false
    /// Where the pager stands between the two pages, for the tabs' capsule to follow.
    @State private var pagerPosition: TabPagerPosition = .init()
    /// Whether the comment is being written on « Livres », which holds the pager still.
    @State private var isWritingComment: Bool = false
    /// The tabs' height, which each page leaves room for at its top.
    @State private var tabsHeight: CGFloat = 0

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

    /// Whether anything on this screen may write to the list.
    private var isMine: Bool {
        list.isCreated(byMe: userModel.myUser?._id)
    }

    var body: some View {
        if list.isStillInTheStore {
            ZStack(alignment: .top) {
                TabPager(
                    selection: $tab,
                    isFrozen: isWritingComment,
                    position: pagerPosition
                ) { page in
                    switch page {
                    case .elements:
                        ListElementsPage(
                            list: list,
                            items: liveItems,
                            isMine: isMine,
                            selectedURI: $selectedURI,
                            isWritingComment: $isWritingComment,
                            tabsHeight: tabsHeight,
                            onScan: { isPresentingScanner = true },
                            onSearch: { isPresentingSearch = true },
                            onOpen: open,
                            onRemove: remove
                        )
                    case .presentation:
                        DesignSystem.FormList {
                            ListPresentationPage(list: list)
                        }
                        .listDetailTabsRoom(height: tabsHeight)
                    }
                }
                // Edge to edge, so the pages run under the bars as a list does; UIKit hands each
                // page the safe area, which its list keeps its rows clear of.
                .ignoresSafeArea()

                ListDetailTabPicker(
                    selection: $tab,
                    position: pagerPosition,
                    listType: list.type,
                    count: liveItems.count
                )
                .listDetailTabsBar()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tabsHeight = $0 }
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
            // The add bar takes the tab bar's place; a list with nothing to add keeps the tab bar.
            .toolbar(isMine ? .hidden : .automatic, for: .tabBar)
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
