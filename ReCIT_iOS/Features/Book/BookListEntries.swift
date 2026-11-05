//
//  BookListEntries.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import Foundation

/// The lists of works holding a book's work, mine and my friends', the most recently changed
/// first. A list holding two works of a recueil shows once, opened on the first in list order.
struct BookListEntries {
    let entries: [BookListEntry]

    var isEmpty: Bool {
        entries.isEmpty
    }

    /// - Parameters:
    ///   - items: The list elements whose uri is one of the book's works.
    ///   - myUserId: The signed-in reader's id.
    ///   - friends: My friends, whose lists are kept beside mine.
    init(
        items: [EntityListItem],
        myUserId: String?,
        friends: [User]
    ) {
        let friendsById: [String: User] = .init(friends.map { ($0._id, $0) }) { first, _ in first }
        let firstItemByList: [String: EntityListItem] = .init(
            items
                .filter(\.isStillInTheStore)
                .compactMap { item -> (String, EntityListItem)? in
                    guard let list = item.list, list.isStillInTheStore, list.type == .work else { return nil }
                    return (list._id, item)
                }
        ) { first, second in first.ordinal <= second.ordinal ? first : second }

        entries = firstItemByList.values
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
            .sorted(by: Self.mostRecentlyChangedFirst)
    }

    private static func mostRecentlyChangedFirst(
        _ lhs: BookListEntry,
        _ rhs: BookListEntry
    ) -> Bool {
        let lhsDate: Date = lhs.list.updated ?? lhs.list.created
        let rhsDate: Date = rhs.list.updated ?? rhs.list.created
        return lhsDate == rhsDate ? lhs.list._id < rhs.list._id : lhsDate > rhsDate
    }
}
