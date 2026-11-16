//
//  ListShareRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// « Partager » on the selected element: the link opens the list on this element, with the
/// element's title as subject. Absent on a list visible to its creator alone, and on an element
/// the server has not created yet.
struct ListShareRow: View {
    let item: EntityListItem
    let list: EntityList

    @Query private var works: [Work]
    @Query private var authors: [Author]

    init(
        item: EntityListItem,
        list: EntityList
    ) {
        self.item = item
        self.list = list
        let uri: String = item.uri
        _works = Query(filter: #Predicate<Work> { $0.uri == uri })
        _authors = Query(filter: #Predicate<Author> { $0.uri == uri })
    }

    private var title: String {
        list.type == .author ? authors.first?.name ?? "" : works.first?.title ?? ""
    }

    var body: some View {
        if list.isVisibleToCreatorAlone == false {
            DeepLinkShareLink(.list(id: list._id, elementId: item._id), subject: title)
                .labelStyle(.titleOnly)
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier(AccessibilityID.share)
        }
    }
}

private extension ListShareRow {
    enum AccessibilityID {
        static let share: String = "e2e.listElement.share"
    }
}

#Preview {
    let list: EntityList = .mock(id: "88b00676d608d9d53c5974fd9bc1009a", visibility: [.friends])
    let item: EntityListItem = .init(
        _id: "88b00676d608d9d53c5974fd9bc8a871",
        uri: "wd:Q25338",
        ordinal: "1",
        created: .now,
        itemType: .work
    )
    DesignSystem.FormList {
        Section {
            ListShareRow(item: item, list: list)
        }
    }
    .modelContainer(for: [Work.self, Author.self], inMemory: true)
}
