//
//  UserInventoryTab.swift
//  ReCIT_iOS
//
//  A reader's books, under the Inventaire tab of their profile — the list the profile has
//  always shown, as a section of the page's inset grouped list: the first-sync bar while their books arrive, the books
//  as they come, and « Emprunter à … » on a long press. The header that named it went: the tab
//  above says what it is.
//

import SwiftUI

struct UserInventoryTab: View {
    @Environment(UserModel.self) private var userModel
    @Environment(InventoryModel.self) private var inventoryModel

    let user: User
    /// One on a phone; two on a screen as wide as the unfolded iPhone Duo in landscape, as my
    /// own « Tous les livres » (`ShelvesContent.allBooksColumnCount`).
    let columns: Int
    @Binding var path: NavigationPath
    /// Asks the screen for the borrowing form, which it presents as a sheet.
    let onBorrow: (InventoryItem) -> Void

    var body: some View {
        let syncState: InventoryFirstSyncState = inventoryModel.firstSyncState(for: user)
        Section {
            // The same bar as their cell in the Profil, and the books already received under
            // it: a friend's inventory is read as it arrives, not after.
            if syncState != .synced {
                InventorySyncBanner(
                    title: "sync.inventory.friend.title \(user.username)",
                    state: syncState
                )
                .padding(.vertical, .xSmall)
            }

            if syncState == .synced && user.items.isEmpty {
                Text("inventory.empty")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            } else if columns > 1 {
                // Keyed on the row's first book by its persistent id, as in `ShelvesContent`.
                ForEach(bookRows, id: \.first?.id) { row in
                    HStack(alignment: .top, spacing: .medium) {
                        ForEach(row) { item in
                            bookButton(item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        // A short last row keeps its book in the first column, at its width.
                        if row.count < columns {
                            Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                        }
                    }
                }
            } else {
                ForEach(user.items) { item in
                    bookButton(item)
                }
            }
        }
        .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
    }

    /// Their books in rows of `columns`, in the list's order, read left to right.
    private var bookRows: [[InventoryItem]] {
        let items: [InventoryItem] = user.items
        return stride(from: 0, to: items.count, by: columns).map { start in
            Array(items[start..<min(start + columns, items.count)])
        }
    }

    private func bookButton(_ item: InventoryItem) -> some View {
        Button {
            path.append(NavigationDestination.book(anchor: .item(item)))
        } label: {
            InventoryCell(item: item, filterParameter: .userInventory)
        }
        .buttonStyle(.plain)
        .contextMenu {
            borrowActions(for: item)
        }
    }

    @ViewBuilder
    private func borrowActions(for item: InventoryItem) -> some View {
        if item.ownerId != userModel.myUser?._id {
            if item.transaction == .inventorying {
                Button("community.owner_not_lending \(user.username)", systemImage: "hand.raised.slash") { }
                    .disabled(true)
            } else {
                Button(String(localized: item.transaction.requestMenuLabel(owner: user.username)), systemImage: "hand.wave") {
                    onBorrow(item)
                }
            }
        }
    }
}
