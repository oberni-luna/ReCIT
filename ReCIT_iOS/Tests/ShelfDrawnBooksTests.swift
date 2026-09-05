//
//  ShelfDrawnBooksTests.swift
//  ReCIT_iOSTests
//
//  The run of books a shelf draws: covers first, then newest, then the cap.
//

import Testing
import Foundation
@testable import ReCIT_iOS

@Suite("Shelf drawn books")
@MainActor
struct ShelfDrawnBooksTests {

    private func item(id: String, created: TimeInterval, image: String?) -> InventoryItem {
        let edition: Edition = Fixture.edition(uri: "isbn:\(id)", title: id)
        edition.image = image
        let item: InventoryItem = Fixture.inventoryItem(id: id, edition: edition)
        item.created = .init(timeIntervalSince1970: created)
        return item
    }

    @Test("A book with a cover is drawn before an older-or-newer one without")
    func coversComeFirst() {
        let books: [InventoryItem] = ShelfDrawnBooks.from([
            item(id: "naked-new", created: 300, image: nil),
            item(id: "painted-old", created: 100, image: "https://example.org/a.jpg"),
            item(id: "naked-empty", created: 200, image: "")
        ])

        #expect(books.map(\._id) == ["painted-old", "naked-new", "naked-empty"])
    }

    @Test("Within each group the newest copy comes first")
    func newestFirstWithinAGroup() {
        let books: [InventoryItem] = ShelfDrawnBooks.from([
            item(id: "older", created: 100, image: "https://example.org/a.jpg"),
            item(id: "newer", created: 200, image: "https://example.org/b.jpg")
        ])

        #expect(books.map(\._id) == ["newer", "older"])
    }

    @Test("A huge shelf still draws at most the cap")
    func capsTheRun() {
        let many: [InventoryItem] = (0..<(ShelfDrawnBooks.limit + 5)).map {
            item(id: "i\($0)", created: TimeInterval($0), image: "https://example.org/\($0).jpg")
        }

        #expect(ShelfDrawnBooks.from(many).count == ShelfDrawnBooks.limit)
    }
}
