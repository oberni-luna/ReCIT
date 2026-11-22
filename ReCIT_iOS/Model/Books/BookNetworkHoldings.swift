//
//  BookNetworkHoldings.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import Foundation

/// What my network holds of a book, under the Fiche livre's Dans le réseau: the other readers'
/// copies of the edition, and my friends' lists holding its work. Their total is the tab's count.
struct BookNetworkHoldings {
    let copies: [InventoryItem]
    let lists: [BookListEntry]

    /// - Parameters:
    ///   - copies: Every copy of the edition, mine included.
    ///   - lists: The lists holding the book's work, mine included.
    ///   - myUserId: The signed-in reader's id.
    ///
    /// A deleted copy is dropped before its owner is read: the edition can still hold the one
    /// the screen has just removed. See `PersistentModel+StillInTheStore` and issue 0065.
    init(
        copies: [InventoryItem],
        lists: [BookListEntry],
        myUserId: String?
    ) {
        self.copies = copies.filter { $0.isStillInTheStore && $0.ownerId != myUserId }
        self.lists = lists.filter { $0.isMine == false }
    }

    var count: Int { copies.count + lists.count }

    var isEmpty: Bool { copies.isEmpty && lists.isEmpty }
}
