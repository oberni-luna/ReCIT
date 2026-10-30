//
//  UserInventoryTab.swift
//  ReCIT_iOS
//
//  A reader's books, under the Inventaire tab of their profile — the list the profile has
//  always shown, on a card of its own: the first-sync bar while their books arrive, the books
//  as they come, and « Emprunter à … » on a long press. The header that named it went: the tab
//  above says what it is.
//

import SwiftUI

struct UserInventoryTab: View {
    @Environment(UserModel.self) private var userModel
    @Environment(InventoryModel.self) private var inventoryModel

    let user: User
    @Binding var path: NavigationPath
    /// Asks the screen for the borrowing form, which it presents as a sheet.
    let onBorrow: (InventoryItem) -> Void

    var body: some View {
        let syncState: InventoryFirstSyncState = inventoryModel.firstSyncState(for: user)
        VStack(spacing: .medium) {
            // The same bar as their cell in the Profil, and the books already received under
            // it: a friend's inventory is read as it arrives, not after.
            if syncState != .synced {
                InventorySyncBanner(
                    title: "sync.inventory.friend.title \(user.username)",
                    state: syncState
                )
                .padding(.all, .medium)
                .background(DesignSystem.Color.backgroundFormCell.color)
                .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium.rawValue))
                .padding(.horizontal, .medium)
            }

            if syncState == .synced && user.items.isEmpty {
                Text("inventory.empty")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .padding(.top, .large)
            } else {
                CardRows(data: user.items) { item in
                    Button {
                        path.append(NavigationDestination.book(anchor: .item(item)))
                    } label: {
                        InventoryCell(item: item, filterParameter: .userInventory)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        borrowActions(for: item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func borrowActions(for item: InventoryItem) -> some View {
        if item.ownerId != userModel.myUser?._id {
            if item.transaction == .inventorying {
                Button("community.owner_not_lending \(user.username)", systemImage: "hand.raised.slash") { }
                    .disabled(true)
            } else {
                Button("action.borrow_from_user \(user.username)", systemImage: "hand.wave") {
                    onBorrow(item)
                }
            }
        }
    }
}
