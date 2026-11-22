//
//  UserDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/02/2026.
//

import SwiftUI
import SwiftData

/// A reader's profile, shaped like the Contacts card of Messages: a header held at the top —
/// their picture, their name and the Inventaire • 540 | Listes • 4 | Échanges • 2 | Présentation
/// tabs — that folds into the navigation bar as the page scrolls, and never stays half folded.
/// Under Inventaire, their étagères scroll away under it, the books after them; the other tabs
/// open on their content: their lists, the Échanges between us, their bio. Échanges is a
/// friend's alone. See PRD 0031 and the « Détail d'un amis » section of the Figma file
/// (`865:17783`).
///
/// Each tab is a page of its own (`UserProfilePage`), an inset grouped `List` whose first row is
/// as tall as the unfolded header, which lies over both. The pages sit in a `FoldingHeaderPager`:
/// a tab is changed by a swipe as well as by its name.
struct UserDetailView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext
    /// Only so the page can hold still while a book is being picked off an étagère.
    @Environment(ShelfFocusModel.self) private var shelfFocus

    @State private var borrowFromItem: InventoryItem?
    @State private var isConfirmingRemoval: Bool = false
    @State private var tab: UserProfileTab = .inventory
    @State private var listsLoad: UserListsTab.Load = .loading
    /// The pages' width, which says whether their books go on one column or two.
    @State private var pagesWidth: CGFloat = 0

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let user: User
    @Binding var path: NavigationPath

    private var isMe: Bool {
        user._id == userModel.myUser?._id
    }

    /// Mine, or a friend's: the two cases where there are books to show. Everyone else's
    /// inventory is closed until the relation is, which is what the empty state says.
    private var showsInventory: Bool {
        isMe || user.relation == .friend
    }

    /// The pages in their order: a friend's four, mine without Échanges, and the single page of
    /// anyone else.
    private var tabs: [UserProfileTab] {
        showsInventory ? UserProfileTab.pages(isMine: isMe) : [.inventory]
    }

    private var metrics: UserProfileStickyHeader.Metrics {
        .init(dynamicTypeSize: dynamicTypeSize)
    }

    private var collapse: FoldingHeaderCollapse {
        metrics.collapse
    }

    /// Their books side by side past the width where mine are (`ShelvesContent`): the unfolded
    /// iPhone Duo in landscape.
    private var bookColumns: Int {
        ShelvesContent.allBooksColumnCount(containerWidth: pagesWidth)
    }

    var body: some View {
        pages
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                pagesWidth = width
            }
            // The name heads the page; the bar keeps the way back and « … ». The title stays set
            // for what reads it elsewhere — the back button's long-press menu.
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: .title)
            .toolbar { toolbarContent }
            .task(id: user._id) {
                await syncLists()
            }
            // The maquette draws no confirmation, and this adds one: unfriending is the only
            // gesture of the whole flow that loses something — the relation has to be asked for
            // again, and the books go with it. Every other destructive action in the app asks
            // first (« Supprimer de mon inventaire », deleting a shelf), so this one does too.
            .confirmationDialog(
                "network.remove.confirm \(user.username)",
                isPresented: $isConfirmingRemoval,
                titleVisibility: .visible
            ) {
                Button("network.remove", role: .destructive) {
                    userModel.unfriend(user, modelContext: modelContext)
                }
                Button("action.cancel", role: .cancel) {}
            }
            .sheet(item: $borrowFromItem) { item in
                if let owner = item.owner, let me = userModel.myUser {
                    TransactionFormView(
                        transaction: .init(
                            _id: "",
                            _rev: "",
                            item: item,
                            owner: owner,
                            requester: me,
                            type: item.transaction,
                            created: .now,
                            messages: [],
                            state: .requested,
                            actions: [],
                            readStatus: .init(owner: false, requester: true)
                        ),
                        transition: TransactionStateMachine.requestTransition
                    )
                }
            }
    }

    /// The pages side by side, a swipe or a tab's name apart, under the header.
    private var pages: some View {
        FoldingHeaderPager(
            selection: $tab,
            tabs: tabs,
            collapse: collapse
        ) { scrollOffset in
            header(scrollOffset)
        } page: { layout in
            page(layout)
        }
        .frozen(shelfFocus.isArmed)
    }

    private func profilePage(
        _ layout: FoldingHeaderPageLayout<UserProfileTab>,
        showsShelves: Bool,
        showsBio: Bool,
        @ViewBuilder content: () -> some View
    ) -> some View {
        UserProfilePage(
            user: user,
            layout: layout,
            showsShelves: showsShelves,
            showsBio: showsBio,
            holdsReadableWidth: showsInventory == false || layout.page != .inventory || bookColumns == 1,
            path: $path,
            content: content
        )
    }

    @ViewBuilder
    private func tabContent(_ page: UserProfileTab) -> some View {
        switch page {
        case .inventory:
            UserInventoryTab(user: user, columns: bookColumns, path: $path) { item in
                borrowFromItem = item
            }
        case .lists:
            UserListsTab(user: user, load: listsLoad, path: $path)
        case .transactions:
            UserTransactionsTab(user: user)
        case .presentation:
            UserPresentationTab(user: user)
        }
    }

    /// A friend's lists are fetched each time their profile opens — not at launch, where every
    /// friend's would be, for a tab most profiles are never switched to. What the store already
    /// holds shows in the meantime. Mine are synced at launch, with the rest of my data.
    private func syncLists() async {
        guard showsInventory, isMe == false else {
            listsLoad = .loaded
            return
        }

        do {
            try await listModel.syncFriendLists(of: user, modelContext: modelContext)
            listsLoad = .loaded
        } catch {
            listsLoad = .failed
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        Section {
            DeepLinkShareLink(.user(username: user.username), subject: user.username)
                .accessibilityIdentifier(AccessibilityID.share)
        }

        if user.relation == .friend {
            Button("network.remove", systemImage: "person.badge.minus") {
                isConfirmingRemoval = true
            }
            .accessibilityIdentifier("e2e.user.removeFromNetwork")
        }

        if isMe == false {
            ReportButton(
                draft: .init(
                    reportedUsername: user.username,
                    reportedUserId: user._id,
                    reporterUsername: userModel.myUser?.username
                )
            )
            .accessibilityIdentifier(AccessibilityID.report)
        }
    }

    /// A "…" holding what one can do *about* someone rather than with them. On my own profile,
    /// « Partager » alone: there is nobody to report, and nobody to remove — and no "…" at all
    /// when my username makes no link.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isMe == false || DeepLink.user(username: user.username).url != nil {
            ToolbarItem(placement: .confirmationAction) {
                Menu {
                    // Same neutral menu as a book's « … »: glyphs in the label colour rather
                    // than the app's green, and no red line of its own — the confirmation
                    // behind « Retirer du réseau » is what guards it. See `BookDetailView`.
                    menuContent
                        .tint(.foregroundDefault)
                } label: {
                    Label("action.more", systemImage: "ellipsis")
                }
                .accessibilityIdentifier(AccessibilityID.menu)
            }
        }
    }

    /// One page of the pager. Someone whose books are closed to me has no tabs, and a single
    /// page, their bio at its top.
    @ViewBuilder
    private func page(_ layout: FoldingHeaderPageLayout<UserProfileTab>) -> some View {
        if showsInventory {
            // The étagères are part of the library, so they go with the books, not with the
            // lists or the bio.
            profilePage(layout, showsShelves: layout.page == .inventory, showsBio: false) {
                tabContent(layout.page)
            }
        } else {
            profilePage(layout, showsShelves: false, showsBio: true) {
                Section {
                    RelationActionsView(user: user)

                    EmptyStateView(
                        glyph: "person",
                        title: "network.private_inventory.title",
                        message: "network.private_inventory.message \(user.username)"
                    )
                    .padding(.vertical, .large)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    private func header(_ scrollOffset: FoldingHeaderScrollOffset<UserProfileTab>) -> some View {
        UserProfileStickyHeader(
            user: user,
            tab: showsInventory ? $tab : nil,
            tabs: tabs,
            listsLoad: listsLoad,
            metrics: metrics,
            collapse: collapse,
            scrollOffset: scrollOffset
        )
    }
}

private extension UserDetailView {
    enum AccessibilityID {
        static let menu: String = "e2e.user.menu"
        static let share: String = "e2e.user.share"
        static let report: String = "e2e.user.report"
    }
}

#Preview {
//    UserDetailView()
}
