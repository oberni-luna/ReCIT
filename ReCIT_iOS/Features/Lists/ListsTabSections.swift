//
//  ListsTabSections.swift
//  ReCIT_iOS
//
//  What the Lists tab shows, from everything the store holds: « Mes listes », by name, then
//  « Dans mon réseau », my friends' lists, the most recently changed first — what they have just
//  done, as « Chez mes amis » in Recherche.
//
//  A friend is a reader whose relation is `.friend`: a stranger whose profile I opened has lists
//  in the store too, and they stay on that profile. The search keeps the lists whose name holds
//  the text, in both sections.
//

import Foundation

struct ListsTabSections {
    let mine: [EntityList]
    let network: [NetworkListEntry]

    var isEmpty: Bool {
        mine.isEmpty && network.isEmpty
    }

    init(
        lists: [EntityList],
        myUserId: String?,
        friends: [User],
        searchText: String = ""
    ) {
        let matching: [EntityList] = if searchText.isEmpty {
            lists
        } else {
            lists.filter { $0.name.localizedStandardContains(searchText) }
        }
        let friendsById: [String: User] = .init(friends.map { ($0._id, $0) }) { first, _ in first }

        mine = matching
            .filter { $0.isCreated(byMe: myUserId) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        network = matching
            .compactMap { list in
                guard let creatorId = list.creatorId, creatorId != myUserId, let owner = friendsById[creatorId] else {
                    return nil
                }
                return NetworkListEntry(list: list, owner: owner)
            }
            .sorted { ($0.list.updated ?? $0.list.created) > ($1.list.updated ?? $1.list.created) }
    }
}
