//
//  BookListsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import SwiftData
import SwiftUI

/// « Dans les listes » on the book screen, split in two: « Dans mes listes » under Mon exemplaire,
/// « Dans les listes de mes ami·es » under Dans le réseau. A row opens the list on that work;
/// `trailing` rows close the section.
struct BookListsSection<Trailing: View>: View {
    private let titleKey: LocalizedStringKey
    private let entries: [BookListEntry]
    private let trailing: Trailing

    init(
        _ titleKey: LocalizedStringKey,
        entries: [BookListEntry],
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.titleKey = titleKey
        self.entries = entries
        self.trailing = trailing()
    }

    var body: some View {
        Section(titleKey) {
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

            trailing
        }
    }
}

extension BookListsSection where Trailing == EmptyView {
    init(
        _ titleKey: LocalizedStringKey,
        entries: [BookListEntry]
    ) {
        self.init(titleKey, entries: entries) {
            EmptyView()
        }
    }
}

private extension BookListsSection {
    /// Computed: a generic type holds no stored static.
    enum AccessibilityID {
        static var listRow: String { "book.inLists.row" }
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

#Preview("Mine and a friend's", traits: .modifier(BookListsSection<EmptyView>.PreviewStore())) {
    List {
        BookListEntriesReader(workUris: ["wd:Q1"], myUserId: "me") { entries in
            BookListsSection("book.my_lists", entries: entries.filter(\.isMine)) {
                Text(verbatim: "Ajouter à une liste")
            }

            BookListsSection("book.friends_lists", entries: entries.filter { $0.isMine == false })
        }
    }
}

#Preview("In none of my lists") {
    List {
        BookListsSection("book.my_lists", entries: []) {
            Text(verbatim: "Ajouter à une liste")
        }
    }
}
