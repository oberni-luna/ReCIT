//
//  UserDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/02/2026.
//

import SwiftUI
import SwiftData

/// A reader's profile, shaped like the Contacts card of Messages: a header held at the top —
/// their picture, their name, their book count and the Inventaire | Listes tabs — that folds into
/// the navigation bar as the page scrolls, and never stays half folded. Their bio and étagères
/// scroll away under it; the tab's content follows. See PRD 0031 and the « Détail d'un amis »
/// section of the Figma file (`865:17783`).
///
/// Each tab is a page of its own (`UserProfilePage`), an inset grouped `List` whose first row is
/// as tall as the unfolded header, which lies over both. The pages sit in a pager: a tab is
/// changed by a swipe as well as by its name.
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
    /// The pages' scroll and the pager's position — never read by this body, so a scroll
    /// redraws the header alone.
    @State private var scrollOffset: ProfileScrollOffset = .init()
    /// The header's height unfolded — what the pages are pushed down by.
    @State private var expandedHeaderHeight: CGFloat = 0
    /// Where the header starts on screen at rest, read only while the page on screen is settled
    /// (see `UserProfilePage.firstRowTop`).
    @State private var headerTop: CGFloat?
    /// The screen's safe area and the whole screen, on screen: the pages are as tall as the
    /// screen, and the room at the foot of the safe area is the tab bar's, which they run under.
    /// Inside the pager, a page is told neither — it would be as tall as the safe area, and stop
    /// at the tab bar's top.
    @State private var safeFrame: CGRect = .zero
    @State private var screenFrame: CGRect = .zero

    private var bottomSafeArea: CGFloat {
        max(screenFrame.maxY - safeFrame.maxY, 0)
    }

    /// The tab as the pager's scroll position: a swipe that settles on a page selects its tab,
    /// and a tab chosen by its name scrolls the pager to it.
    private var pagerSelection: Binding<UserProfileTab?> {
        .init(
            get: { tab },
            set: { page in
                if let page {
                    tab = page
                }
            }
        )
    }

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

    private var metrics: UserProfileStickyHeader.Metrics {
        .init(dynamicTypeSize: dynamicTypeSize)
    }

    private var collapse: ProfileHeaderCollapse {
        metrics.collapse
    }

    var body: some View {
        // The safe area, as what the pages are measured against: a horizontal scroll view takes
        // the height of what it holds, so it cannot be what the pages are sized from.
        Color.clear
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                safeFrame = frame
            }
            .background {
                // Measured inside `ignoresSafeArea`, where the frame is the screen's.
                Color.clear
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                        screenFrame = frame
                    }
                    .ignoresSafeArea()
            }
            .overlay {
                pages
            }
            .overlay(alignment: .top) {
                header
            }
            // The header draws its own backdrop under the bar, once the page passes under it.
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .background {
                DesignSystem.Color.backgroundForm.color
                    .ignoresSafeArea()
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

    /// Inventaire and Listes side by side, a swipe or a tab's name apart. Someone whose books are
    /// closed to me has no tabs, and a single page.
    @ViewBuilder
    private var pages: some View {
        if showsInventory {
            ScrollView(.horizontal) {
                HStack(spacing: .zero) {
                    ForEach(UserProfileTab.allCases, id: \.self) { page in
                        profilePage(page, showsShelves: true, bottomMargin: bottomSafeArea) {
                            tabContent(page)
                        }
                        .frame(width: screenFrame.width, height: screenFrame.height)
                        .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: pagerSelection)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.x / max(geometry.containerSize.width, 1)
            } action: { _, position in
                scrollOffset.pagePosition = position
            }
            // Edge to edge, so the pages run under the bars as a list does: within the safe
            // area, the pager would clip them at the tab bar's top. The header's room is the
            // pages' first row, and the tab bar's a margin each page is given.
            .ignoresSafeArea()
            // Frozen while a book is being picked off an étagère, like the pages' own scroll.
            .scrollDisabled(shelfFocus.isArmed)
        } else {
            profilePage(.inventory, showsShelves: false, bottomMargin: 0) {
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

    private func profilePage(
        _ page: UserProfileTab,
        showsShelves: Bool,
        bottomMargin: CGFloat,
        @ViewBuilder content: () -> some View
    ) -> some View {
        UserProfilePage(
            user: user,
            page: page,
            showsShelves: showsShelves,
            expandedHeaderHeight: expandedHeaderHeight,
            headerTop: headerTop,
            bottomMargin: bottomMargin,
            collapse: collapse,
            scrollOffset: scrollOffset,
            path: $path,
            content: content
        )
    }

    @ViewBuilder
    private func tabContent(_ page: UserProfileTab) -> some View {
        switch page {
        case .inventory:
            UserInventoryTab(user: user, path: $path) { item in
                borrowFromItem = item
            }
        case .lists:
            UserListsTab(user: user, load: listsLoad, path: $path)
        }
    }

    /// Under the navigation bar: an overlay of the safe area, over the pages that run past it.
    private var header: some View {
        UserProfileStickyHeader(
            user: user,
            tab: showsInventory ? $tab : nil,
            metrics: metrics,
            collapse: collapse,
            scrollOffset: scrollOffset
        )
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            guard scrollOffset.isSettled(tab) else { return }
            headerTop = frame.minY
            expandedHeaderHeight = frame.height
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
        if user.relation == .friend {
            Button("network.remove", systemImage: "person.badge.minus") {
                isConfirmingRemoval = true
            }
            .accessibilityIdentifier("e2e.user.removeFromNetwork")
        }

        ReportButton(
            draft: .init(
                reportedUsername: user.username,
                reportedUserId: user._id,
                reporterUsername: userModel.myUser?.username
            )
        )
        .accessibilityIdentifier("e2e.user.report")
    }

    /// A "…" holding what one can do *about* someone rather than with them.
    /// Hidden on my own profile: there is nobody to report, and nobody to remove.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if user._id != userModel.myUser?._id {
                Menu {
                    // Same neutral menu as a book's « … »: glyphs in the label colour rather
                    // than the app's green, and no red line of its own — the confirmation
                    // behind « Retirer du réseau » is what guards it. See `BookDetailView`.
                    menuContent
                        .tint(.foregroundDefault)
                } label: {
                    Label("action.more", systemImage: "ellipsis")
                }
                .accessibilityIdentifier("e2e.user.menu")
            }
        }
    }
}

#Preview {
//    UserDetailView()
}
