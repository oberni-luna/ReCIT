//
//  AboutInventaireShelfBooks.swift
//  ReCIT_iOS
//
//  The books on the À propos plank: my three latest, newest first — fewer if I own fewer, none if
//  I own none. Drawn by `ShelfBooksView`, the inventory's own renderer, so they stand, lean and
//  lie exactly as they would on an étagère of the same width: one book face-on, two or three as
//  spines with the last one leaning.
//
//  The renderer is used bare. The gestures of an étagère — press to grow, slide, lift to open —
//  live in `ShelfRowView` around it, and this view does not bring them: the plank is a picture of
//  my books on inventaire.io, not a way into them.
//
//  The width is measured, not assumed, as `OnboardingSettlingBooksView` does: every size on a
//  shelf derives from it (`ShelfCardMetrics`), and this plank is whatever the screen's column is.
//

import SwiftUI
import SwiftData

struct AboutInventaireShelfBooks: View {

    /// My books, newest first, three at most.
    @Query private var books: [InventoryItem]

    @State private var width: CGFloat = 0

    /// How many books the plank carries.
    static let limit: Int = 3

    init(ownerId: String) {
        var descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [.init(\.created, order: .reverse)]
        )
        descriptor.fetchLimit = Self.limit
        _books = .init(descriptor)
    }

    private var metrics: ShelfCardMetrics { .init(width: width) }

    var body: some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { measured in
                width = measured
            }
            .overlay(alignment: .bottom) {
                plank(carrying: books)
            }
    }

    /// The books and their geometry from one reading of the query, for the reason
    /// `ShelfRowView.drawn` gives: a live list read twice can disagree with itself.
    @ViewBuilder
    private func plank(carrying books: [InventoryItem]) -> some View {
        let layout: ShelfBooksLayout = .init(books: books, metrics: metrics)
        // Nothing until the band has been measured: a book laid out against a width of zero
        // would be resized the moment the real one arrived.
        if layout.width > 0, books.isEmpty == false {
            ShelfBooksView(books: books, metrics: metrics, layout: layout)
        }
    }
}
