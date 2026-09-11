//
//  InventorySearchContent.swift
//  ReCIT_iOS
//
//  The inventory screen while its search field is open. It replaces what used to sit behind
//  `isSearching` — a flat list of the user's own books, and nothing else — with a surface
//  driven by `SearchPhase`, which is what lets the field stop meaning "filter my shelves" and
//  start meaning "find this book".
//
//  This first slice renders one of the four phases. Under three characters the screen shows
//  nothing new rather than an empty section, which is the whole point of the threshold living
//  in `SearchPhase`: the silence is a decision, not an accident. `recents` and `results` are
//  computed here already and deliberately draw nothing until issues 0072 and 0071 give them
//  something to draw.
//
//  Both `@Query`s are the reactive ones ADR 0001 asks for — mine by owner id, my friends' by
//  its negation — and the matching happens in memory over what they already hold. No fetch, no
//  server call, nothing persisted: searching is a read.
//
//  See PRD 0012.
//

import SwiftData
import SwiftUI

struct InventorySearchContent: View {
    let user: User
    let searchText: String

    @Environment(\.isSearching) private var isSearching

    @Query private var myItems: [InventoryItem]
    @Query private var friendsItems: [InventoryItem]

    init(
        user: User,
        searchText: String
    ) {
        self.user = user
        self.searchText = searchText

        let ownerId: String = user._id
        _myItems = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
        _friendsItems = Query(
            filter: #Predicate { $0.ownerId != ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    /// Nothing has been submitted yet: the keyboard's « rechercher » key and the inventaire.io
    /// suggestions arrive with issue 0071, and until they do no query can reach `results`.
    private var phase: SearchPhase? {
        SearchPhase.current(
            isFocused: isSearching,
            query: searchText,
            submittedQuery: nil
        )
    }

    /// The query the local section searches for — set only past the threshold.
    private var localQuery: String? {
        if case .suggesting(let query) = phase { query } else { nil }
    }

    var body: some View {
        List {
            if let localQuery {
                InventorySearchLocalSection(
                    query: localQuery,
                    ownerId: user._id,
                    myItems: myItems,
                    friendsItems: friendsItems
                )
            }
        }
        .listStyle(.plain)
        .applyListBackground()
    }
}
