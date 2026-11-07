//
//  FriendItemRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftData
import SwiftUI

/// A friend's copy of a book, as the Fiche livre and a Liste list it: a tap opens the friend's
/// profile, a long press asks them for it — or says they do not lend it.
struct FriendItemRow: View {
    private let item: InventoryItem
    private let onOpenFriend: (User) -> Void
    private let onRequest: (InventoryItem) -> Void
    private var isRequestOffered: Bool = true

    init(
        _ item: InventoryItem,
        onOpenFriend: @escaping (User) -> Void,
        onRequest: @escaping (InventoryItem) -> Void
    ) {
        self.item = item
        self.onOpenFriend = onOpenFriend
        self.onRequest = onRequest
    }

    var body: some View {
        Button {
            if let owner = item.owner {
                onOpenFriend(owner)
            }
        } label: {
            // For the chevron: the button is what opens the profile.
            NavigationLink(value: UUID()) {
                UserItemCellView(item: item)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.row)
        .contextMenu {
            if let owner = item.owner {
                if isRequestOffered == false {
                    Button("community.book_in_my_inventory", systemImage: "books.vertical") { }
                        .disabled(true)
                } else if item.transaction == .inventorying {
                    Button("community.owner_not_lending \(owner.username)", systemImage: "hand.raised.slash") { }
                        .disabled(true)
                } else {
                    Button(String(localized: item.transaction.requestMenuLabel(owner: owner.username)), systemImage: "hand.wave") {
                        onRequest(item)
                    }
                }
            }
        }
    }
}

extension FriendItemRow {
    /// Whether the long press offers to ask for the copy. Not when I own the book myself: it then
    /// says the book is in my inventory.
    func requestOffered(_ isOffered: Bool = true) -> Self {
        var copy: Self = self
        copy.isRequestOffered = isOffered
        return copy
    }
}

private extension FriendItemRow {
    enum AccessibilityID {
        static let row: String = "friendItem.row"
    }
}

#Preview(traits: .modifier(FriendItemsPreviewStore())) {
    @Previewable @Query(sort: \InventoryItem._id) var items: [InventoryItem]

    NavigationStack {
        List(items) { item in
            FriendItemRow(
                item,
                onOpenFriend: { _ in },
                onRequest: { _ in }
            )
        }
    }
}
