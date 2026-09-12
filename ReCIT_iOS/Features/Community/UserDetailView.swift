//
//  UserDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/02/2026.
//

import SwiftUI

struct UserDetailView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    @State private var nextNavigationDestination: NavigationDestination?
    @State private var borrowFromItem: InventoryItem?
    @State private var isConfirmingRemoval: Bool = false

    let user: User
    @Binding var path: NavigationPath

    /// Mine, or a friend's: the two cases where there are books to show. Everyone else's
    /// inventory is closed until the relation is, which is what the empty state says.
    private var showsInventory: Bool {
        user._id == userModel.myUser?._id || user.relation == .friend
    }

    var body: some View {
        List {
            Section {
                UserHeaderView(user: user)
            }

            if showsInventory {
                inventorySection
            } else {
                Section {
                    RelationActionsView(user: user)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
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
        .navigationTitle("nav.user")
        .toolbar { toolbarContent }
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

    @ViewBuilder
    private var inventorySection: some View {
        Section {
            if user.lastInventorySync == nil {
                SyncingInlineRow()
            } else if user.items.isEmpty {
                Text("inventory.empty")
            } else {
                ForEach(user.items) { item in
                    Button {
                        path.append(NavigationDestination.book(anchor: .item(item)))
                    } label: {
                        InventoryCell(item: item, filterParameter: .userInventory)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if item.ownerId != userModel.myUser?._id {
                            if item.transaction == .inventorying {
                                Button("community.owner_not_lending \(user.username)", systemImage: "hand.raised.slash") { }
                                    .disabled(true)
                            } else {
                                Button("action.borrow_from_user \(user.username)", systemImage: "hand.wave") {
                                    borrowFromItem = item
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("user.inventory.header \(user.username)")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
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
