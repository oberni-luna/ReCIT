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
        let entries: [BookListEntry] = BookListEntry.entries(
            items: items,
            myUserId: myUserId,
            friends: users.filter { $0.relation == .friend }
        )
        if !entries.isEmpty {
            Section("book.in_lists") {
                ForEach(entries) { entry in
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

    /// A store holding a work in one of my lists and in a friend's.
    struct PreviewStore: PreviewModifier {
        static func makeSharedContext() throws -> ModelContainer {
            let container: ModelContainer = try .init(
                for: EntityList.self,
                EntityListItem.self,
                User.self,
                configurations: .init(isStoredInMemoryOnly: true)
            )
            let lea: User = .init(
                _id: "lea",
                _rev: "1",
                username: "Léa",
                email: nil,
                position: nil,
                avatarURLValue: nil,
                itemCount: 0
            )
            lea.relation = .friend
            container.mainContext.insert(lea)

            let lists: [EntityList] = [
                .mock(id: "mine", name: "Livres lus", updated: .now, creatorId: "me"),
                .mock(id: "lea", name: "Polars nordiques", creatorId: "lea")
            ]
            for list in lists {
                container.mainContext.insert(list)
                list.elements.append(
                    .init(
                        _id: "\(list._id)-wd:Q1",
                        uri: "wd:Q1",
                        ordinal: "0",
                        created: .now,
                        itemType: .work
                    )
                )
            }
            return container
        }

        func body(
            content: Content,
            context: ModelContainer
        ) -> some View {
            content.modelContainer(context)
        }
    }
}

#Preview("Mine and a friend's", traits: .modifier(BookListsSection.PreviewStore())) {
    List {
        BookListsSection(
            workUris: ["wd:Q1"],
            myUserId: "me"
        )
    }
}

#Preview("In no list") {
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
