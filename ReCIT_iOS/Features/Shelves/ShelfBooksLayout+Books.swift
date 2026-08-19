//
//  ShelfBooksLayout+Books.swift
//  ReCIT_iOS
//
//  Bridges the pure layout to real books, so the shelf and the focus overlay build the same
//  geometry from the same inputs. Kept out of `ShelfBooksLayout.swift` to leave that type
//  free of SwiftData. See ADR 0006.
//

import CoreGraphics

extension ShelfBooksLayout {
    init(books: [InventoryItem], metrics: ShelfCardMetrics) {
        self.init(
            pageCounts: books.map { $0.edition?.numberOfPages },
            width: metrics.booksWidth,
            zoneHeight: metrics.zoneHeight
        )
    }
}
