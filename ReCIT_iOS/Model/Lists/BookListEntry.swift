//
//  BookListEntry.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import SwiftData

/// One row of the book screen's « Dans les listes »: a list holding the book's work, who made
/// it when it is a friend's, and the work the list opens on.
struct BookListEntry: Identifiable {
    let list: EntityList
    let owner: User?
    let focusURI: String

    var id: PersistentIdentifier { list.id }

    /// The lists of works holding a book's work, mine and my friends', the most recently changed
    /// first. A list holding two works of a recueil comes once, opened on the first in list order.
    ///
    /// - Parameters:
    ///   - items: The list elements whose uri is one of the book's works.
    ///   - myUserId: The signed-in reader's id.
    ///   - friends: My friends, whose lists are kept beside mine.
    /// - Returns: One entry per list, a stranger's left out.
    static func entries(
        items: [EntityListItem],
        myUserId: String?,
        friends: [User]
    ) -> [BookListEntry] {
        let friendsById: [String: User] = User.byId(friends)
        let firstItemByList: [String: EntityListItem] = .init(
            items
                .filter(\.isStillInTheStore)
                .compactMap { item -> (String, EntityListItem)? in
                    guard let list = item.list, list.isStillInTheStore, list.type == .work else { return nil }
                    return (list._id, item)
                }
        ) { first, second in first.ordinal <= second.ordinal ? first : second }

        return firstItemByList.values
            .compactMap { item -> BookListEntry? in
                guard let list = item.list else { return nil }
                if list.isCreated(byMe: myUserId) {
                    return .init(list: list, owner: nil, focusURI: item.uri)
                }
                guard let owner = list.friendCreator(myUserId: myUserId, friendsById: friendsById) else {
                    return nil
                }
                return .init(list: list, owner: owner, focusURI: item.uri)
            }
            .sorted { lhs, rhs in
                lhs.list.lastChanged == rhs.list.lastChanged
                    ? lhs.list._id < rhs.list._id
                    : lhs.list.lastChanged > rhs.list.lastChanged
            }
    }
}
