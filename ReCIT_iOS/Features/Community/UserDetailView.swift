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
/// An inset grouped `List`, so the books and the lists sit in the system's own sections, corners
/// and separators. Its first row is as tall as the unfolded header, which lies over it.
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
    /// The page's scroll, counted from rest — never read by this body, so a scroll redraws the
    /// header alone — and the scroll view's top inset it is counted from, which barely moves.
    @State private var scrollOffset: ProfileScrollOffset = .init()
    @State private var scrollTopInset: CGFloat = 0
    /// The header's height unfolded — what the page is pushed down by.
    @State private var expandedHeaderHeight: CGFloat = 0
    /// Where the header and the list's first row start on screen, at rest: the list puts some
    /// room of its own above its first section, which the first row gives back.
    @State private var headerTop: CGFloat = 0
    @State private var firstRowTop: CGFloat = 0

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
        List {
            Section {
                // The room the unfolded header takes, as the page's first row rather than a
                // content margin: the scroll's insets are then the bars' alone, and the offset
                // counts from the page at rest whatever the header measures.
                Color.clear
                    .frame(height: max(expandedHeaderHeight - (firstRowTop - headerTop), 0))
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
                        guard scrollOffset.isAtRest else { return }
                        firstRowTop = top
                    }

                if let bio = user.bio, bio.isEmpty == false {
                    Text(bio)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, .medium)
                        .padding(.top, .small)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if showsInventory {
                // Their étagères sit between who they are and what they own, which is the
                // order the two are read in: a shelf says how the library is arranged, the
                // tabs say what is in it.
                Section {
                    UserShelvesSection(user: user, path: $path)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                switch tab {
                case .inventory:
                    UserInventoryTab(user: user, path: $path) { item in
                        borrowFromItem = item
                    }
                case .lists:
                    UserListsTab(user: user, load: listsLoad, path: $path)
                }
            } else {
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
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 0)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            scrollOffset.value = offset
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentInsets.top
        } action: { _, inset in
            scrollTopInset = inset
        }
        .scrollTargetBehavior(ProfileHeaderSnapBehavior(collapse: collapse, topInset: scrollTopInset))
        .overlay(alignment: .top) {
            header
        }
        // The header draws its own backdrop under the bar, once the page passes under it.
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .topScrollEdgeEffectHidden()
        .applyListBackground(.backgroundForm)
        // Frozen while a book is being picked off an étagère, so the slide moves the
        // selection and not the page — the same rule the inventory's own carousel follows.
        .scrollDisabled(shelfFocus.isArmed)
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

    /// Under the navigation bar, in the safe area: the overlay of a scroll view lays out where
    /// the page does.
    private var header: some View {
        UserProfileStickyHeader(
            user: user,
            tab: showsInventory ? $tab : nil,
            metrics: metrics,
            collapse: collapse,
            scrollOffset: scrollOffset
        )
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            guard scrollOffset.isAtRest else { return }
            expandedHeaderHeight = frame.height
            headerTop = frame.minY
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
