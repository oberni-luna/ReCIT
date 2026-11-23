//
//  BookListEntriesReader.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftData
import SwiftUI

/// Reads from the store the lists of works holding one of a book's works, mine and my friends',
/// and hands them to `content`: Mon exemplaire keeps mine, Dans le réseau my friends'.
struct BookListEntriesReader<Content: View>: View {
    private let myUserId: String?
    private let content: ([BookListEntry]) -> Content

    @Query private var items: [EntityListItem]
    @Query private var users: [User]

    init(
        workUris: [String],
        myUserId: String?,
        @ViewBuilder content: @escaping ([BookListEntry]) -> Content
    ) {
        self.myUserId = myUserId
        self.content = content
        _items = Query(filter: #Predicate<EntityListItem> { workUris.contains($0.uri) })
    }

    var body: some View {
        content(
            BookListEntry.entries(
                items: items,
                myUserId: myUserId,
                friends: users.filter { $0.relation == .friend }
            )
        )
    }
}

#Preview {
    BookListEntriesReader(workUris: ["wd:Q1"], myUserId: "me") { entries in
        Text(verbatim: "\(entries.count)")
    }
    .modelContainer(
        for: [EntityList.self, EntityListItem.self, User.self],
        inMemory: true
    )
}
