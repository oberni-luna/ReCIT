//
//  FriendsCarouselCover.swift
//  ReCIT_iOS
//
//  One book in « Chez mes amis »: the very card « Ranger mes livres » shows for a book waiting
//  to be filed — same width, same cover, same title under it — so the two carousels of the app
//  read as one. Tapping it opens the book, which the sorting surface deliberately does not do.
//
//  See PRD 0020 and issue 0115.
//

import SwiftUI

struct FriendsCarouselCover: View {
    let item: InventoryItem
    let width: CGFloat

    var body: some View {
        // Same guard as `InventoryCell`: a copy deleted while the carousel is on screen must not
        // have its properties read. See `PersistentModel+StillInTheStore` and issue 0065.
        if item.isStillInTheStore, let edition = item.edition {
            SortBookCardView(
                book: .init(
                    id: item._id,
                    title: edition.title,
                    coverImageUrl: edition.image
                ),
                width: width,
                isDraggable: false,
                onFile: { _ in }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(title: edition.title))
        }
    }

    private func accessibilityLabel(title: String) -> Text {
        if let owner = item.owner {
            Text("inventory.search.friends_section.cover \(title) \(owner.username)")
        } else {
            Text(title)
        }
    }
}
