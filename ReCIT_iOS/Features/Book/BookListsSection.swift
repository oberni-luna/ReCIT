//
//  BookListsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import SwiftData
import SwiftUI

/// « Dans les listes » on the book screen: every list of works, mine or a friend's, holding one
/// of the edition's works. Absent when there is none. A row opens the list on that work.
struct BookListsSection: View {
    let myUserId: String?

    @Query private var items: [EntityListItem]
    @Query private var users: [User]

    init(
        workUris: [String],
        myUserId: String?
    ) {
        self.myUserId = myUserId
        _items = Query(filter: #Predicate<EntityListItem> { workUris.contains($0.uri) })
    }

    var body: some View {
        let entries: BookListEntries = .init(
            items: items,
            myUserId: myUserId,
            friends: users.filter { $0.relation == .friend }
        )
        if !entries.isEmpty {
            Section("book.in_lists") {
                ForEach(entries.entries) { entry in
                    NavigationLink(
                        value: NavigationDestination.entityList(
                            id: entry.list._id,
                            focusURI: entry.focusURI
                        )
                    ) {
                        ListRowView(list: entry.list, owner: entry.owner)
                    }
                    .accessibilityIdentifier(AccessibilityID.listRow)
                }
            }
        }
    }
}

private extension BookListsSection {
    enum AccessibilityID {
        static let listRow: String = "book.inLists.row"
    }
}

#Preview {
    List {
        BookListsSection(
            workUris: ["wd:Q1"],
            myUserId: "me"
        )
    }
    .modelContainer(
        for: [EntityList.self, EntityListItem.self, User.self],
        inMemory: true
    )
}
