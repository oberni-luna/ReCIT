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
//  a first row on the screen's ground, edge to edge, and the comment, the move to another list and the
//  way out of the list are rows with the system's own corners. The way to the book's page is the
//  cover in front.
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
//  **A friend's list is read, not written.** Opened from their profile, the same screen keeps the
//  covers, the title and their comment, and drops everything that writes: the add bar (the tab
//  bar stays), « Mon commentaire », « Déplacer » and « Retirer de la liste ». Derived from the
//  list's creator, never passed in. See PRD 0031.
//
//  **Two tabs, changed by a touch.** « Livres • 8 » is all of the above; « Présentation » is the
//  list's description and what the list is (`ListPresentationPage`), and drops the add bar. The
//  tabs stay pinned under the navigation bar, as on a reader's profile, the list scrolling under
//  them (`listDetailTabsBar`).
//
//  See PRD 0029 and the `Liste détails` section of the Figma file (`843:12721`); the tabs, its
//  `Liste détails · Description de la liste` section (`909:1465`).
//

import SwiftData
import SwiftUI
// The keyboard's frame, which the list keeps to itself.
import UIKit

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
    @FocusState private var isCommentFocused: Bool
    /// Bumped by every edit of the comment and by its focus: what makes the list follow the field
    /// as it grows (`ListKeyboardReveal`).
    @State private var commentEdits: Int = 0
    /// The top of the keyboard on screen, `.infinity` when it is down. Read from UIKit: the list
    /// keeps the keyboard to itself.
    @State private var keyboardTop: CGFloat = .infinity
    /// The keyboard's height, for the room left under the list while the comment is written.
    @State private var keyboardHeight: CGFloat = 0

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

    /// Whether anything on this screen may write to the list.
    private var isMine: Bool {
        list.isCreated(byMe: userModel.myUser?._id)
    }

    /// The room left under the list while the comment is written, when the keyboard's own height
    /// is not known yet.
    private static let minimumKeyboardRoom: CGFloat = 320

    var body: some View {
        rows
        .listDetailTabsBar {
            ListDetailTabPicker(
                selection: $tab,
                listType: list.type,
                count: liveItems.count
            )
        }
        .task {
            for await notification in NotificationCenter.default.notifications(
                named: UIResponder.keyboardWillShowNotification
            ) {
                let frame: CGRect? = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                keyboardTop = frame?.minY ?? .infinity
                keyboardHeight = frame?.height ?? 0
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(
                named: UIResponder.keyboardWillHideNotification
            ) {
                keyboardTop = .infinity
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .formActionBar(isPresented: isMine && tab == .elements && isCommentFocused == false) {
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
        // The add bar takes the tab bar's place; a list with nothing to add keeps the tab bar.
        .toolbar(isMine ? .hidden : .automatic, for: .tabBar)
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
        .onChange(of: isCommentFocused) { _, focused in
            if focused {
                commentEdits += 1
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

    private var rows: some View {
        DesignSystem.FormList {
            switch tab {
            case .elements:
                elementSections
            case .presentation:
                ListPresentationPage(list: list)
            }

            // Room for the comment to rise into. Below the comment the list holds only « Retirer de
            // la liste » and its footer: it was already scrolled as far as it goes, so neither the
            // caret nor `ListKeyboardReveal` could take the growing field any higher, and each new line
            // went under the keyboard. A transparent row as tall as the keyboard, while the
            // comment is being written.
            if isCommentFocused {
                Section {
                    Color.clear
                        // At least a keyboard's worth even before its frame is known: a hardware
                        // keyboard first reports a sliver, and the room has to be there already.
                        .frame(height: max(keyboardHeight, Self.minimumKeyboardRoom))
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }
            }
        }
    }

    /// The cover flow, the selected element and what may be done with it: the « Livres » tab.
    @ViewBuilder
    private var elementSections: some View {
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

            if isMine {
                Section {
                    if let selectedItem {
                        ListCrossFade(id: selectedItem.uri) {
                            ListCommentRow(
                                item: selectedItem,
                                listType: list.type,
                                isFocused: $isCommentFocused,
                                onEdit: { commentEdits += 1 }
                            )
                        }
                        .background {
                            ListKeyboardReveal(trigger: commentEdits, keyboardTop: keyboardTop)
                        }

                        // No way to the element's page here: the cover in front opens it.
                        ListMoveRow(
                            item: selectedItem,
                            list: list,
                            isCommentFocused: isCommentFocused
                        )
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
                        addedFooter(selectedItem)
                    }
                }
            } else if let selectedItem {
                // Their comment when they wrote one, and the day the element was added.
                Section {
                    if selectedItem.comment.isEmpty == false {
                        ListCrossFade(id: selectedItem.uri) {
                            ListReadOnlyCommentRow(comment: selectedItem.comment)
                        }
                    }
                } footer: {
                    addedFooter(selectedItem)
                }
            }
        }
    }

    private func addedFooter(_ item: EntityListItem) -> some View {
        ListCrossFade(id: item.uri) {
            Text("list.detail.added \(item.created.formatted(.dateTime.day().month(.wide).year()))")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity)
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
