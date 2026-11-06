//
//  ShelfDetailV2View.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  The v2 of an étagère's screen, tried side by side with the first (`ShelfDetailView`) from
//  the Inventaire's « Étagères (v2) » section. Built as a list's screen is
//  (`ListCoverFlowScreen`): two pages in a `TabPager`, turned by a swipe or by their tab laid
//  under the navigation bar — « Livres • 12 », the books in an inset grouped list over a pinned
//  « Ajouter des livres » (`ShelfBooksPage`), and « Présentation », the description and what the
//  étagère is (`ShelfPresentationPage`).
//
//  Editing stays behind the navigation bar's pencil, and a deletion from the form pops the
//  screen once the sheet has gone, as on the first screen. A friend's étagère is read-only:
//  no pencil, no swipe, no « Ajouter des livres ». Derived from the shelf's owner.
//

import SwiftData
import SwiftUI

struct ShelfDetailV2View: View {
    let shelfId: String

    @Query private var shelves: [Shelf]

    @State private var tab: ShelfDetailTab = .books
    /// Where the pager stands between the two pages, for the tabs' capsule to follow.
    @State private var pagerPosition: TabPagerPosition = .init()
    /// The tabs' height, which each page leaves room for at its top.
    @State private var tabsHeight: CGFloat = 0
    @State private var isEditing: Bool = false
    @State private var isAddingBooks: Bool = false
    /// Raised by the form when it deletes this screen's étagère, so the pop happens once the
    /// sheet has gone rather than out from under it.
    @State private var shelfWasDeleted: Bool = false

    @Binding var path: NavigationPath

    @Environment(UserModel.self) private var userModel: UserModel

    init(
        shelfId: String,
        path: Binding<NavigationPath>
    ) {
        self.shelfId = shelfId
        self._path = path
        _shelves = Query(filter: #Predicate { $0._id == shelfId })
    }

    private var shelf: Shelf? { shelves.first(where: \.isStillInTheStore) }

    private var isMine: Bool {
        guard let shelf else { return false }
        return shelf.ownerId == userModel.myUser?._id
    }

    /// This étagère's books, newest first, deleted copies dropped first (issue 0065).
    private var books: [InventoryItem] {
        (shelf?.items ?? [])
            .filter(\.isStillInTheStore)
            .sorted { $0.created > $1.created }
    }

    var body: some View {
        // A `ZStack`, not a `Group`: a `Group` hands its modifiers to its children, so once the
        // étagère is deleted it has none, and the edit sheet went with them — its `onDismiss`
        // never ran and the screen stayed, blank, instead of popping.
        ZStack {
            if let shelf {
                ZStack(alignment: .top) {
                    TabPager(
                        selection: $tab,
                        isFrozen: false,
                        position: pagerPosition
                    ) { page in
                        switch page {
                        case .books:
                            ShelfBooksPage(
                                shelf: shelf,
                                books: books,
                                isMine: isMine,
                                tabsHeight: tabsHeight,
                                onAddBooks: { isAddingBooks = true },
                                path: $path
                            )
                        case .presentation:
                            DesignSystem.FormList {
                                ShelfPresentationPage(shelf: shelf)
                            }
                            .listDetailTabsRoom(height: tabsHeight)
                        }
                    }
                    // Edge to edge, so the pages run under the bars as a list does.
                    .ignoresSafeArea()

                    ShelfDetailTabPicker(
                        selection: $tab,
                        position: pagerPosition,
                        count: books.count
                    )
                    .listDetailTabsBar()
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tabsHeight = $0 }
                }
                .sheet(isPresented: $isAddingBooks) {
                    ShelfAddBooksSheet(shelf: shelf)
                }
            }
        }
        .navigationTitle(shelf?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isMine {
                ToolbarItem(placement: .primaryAction) {
                    Button("action.edit", systemImage: "pencil") { isEditing = true }
                        .labelStyle(.titleAndIcon)
                        .accessibilityIdentifier(AccessibilityID.edit)
                }
            }
        }
        .sheet(isPresented: $isEditing, onDismiss: leaveIfShelfWasDeleted) {
            if let shelf {
                ShelfFormView(shelf: shelf) { shelfWasDeleted = true }
            }
        }
    }

    /// Pops this screen once the form that deleted its étagère has closed.
    private func leaveIfShelfWasDeleted() {
        guard shelfWasDeleted, path.isEmpty == false else { return }
        path.removeLast()
    }
}

private extension ShelfDetailV2View {
    enum AccessibilityID {
        static let edit: String = "e2e.shelfV2.edit"
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @State var path: NavigationPath = .init()
    NavigationStack {
        ShelfDetailV2View(shelfId: ShelfPreviewStore.shelfId, path: $path)
    }
}
