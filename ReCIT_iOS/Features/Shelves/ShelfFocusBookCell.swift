//
//  ShelfFocusBookCell.swift
//  ReCIT_iOS
//
//  The pressed book's identity, shown at the top of the screen while selection mode is on:
//  cover, title, authors, stacked and centred. A pared-down `InventoryCell` — no subtitle and
//  no transaction tag, because this is read at a glance with a thumb on the shelf, not
//  browsed.
//
//  The cover's *height* is what is fixed here, not its width — the opposite of a list cell,
//  and deliberate. Every cell is then exactly as tall as every other, so the title lands in
//  the same place for every book as the finger slides along the shelf and nothing jumps. The
//  cost is that a squat art book reads wider than a tall paperback, which is true of the
//  books themselves.
//
//  It carries no backdrop of its own: the overlay blurs what is behind this whole region
//  instead, which keeps the title readable over an arbitrary shelf without drawing an edge
//  across the screen. See ADR 0006.
//

import SwiftUI

struct ShelfFocusBookCell: View {
    let item: InventoryItem

    /// The cover's height. Fixed; the width follows from the book's own proportions.
    private let coverHeight: CGFloat = 90
    /// Stand-in proportions while the cover loads, so the cell doesn't resize under itself.
    private let nominalAspect: CGFloat = 48.0 / 75.0

    var body: some View {
        if let edition = item.edition {
            VStack(spacing: 0) {
                cover(url: edition.image)
                    .padding(.bottom, .small)

                Text(edition.title)
                    .textStyle(.content400Bold)
                    .lineLimit(2)
                    .padding(.bottom, .xSmall)

                Text(edition.authorNames.joined(separator: ", "))
                    .textStyle(.footnote200)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.foregroundDefault)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .medium)
        }
    }

    /// The cover at the cell's fixed height, its width left to the book's own proportions.
    private func cover(url: String?) -> some View {
        CachedAsyncImage(url: url.flatMap { URL(string: $0) }) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Color.clear
                .aspectRatio(nominalAspect, contentMode: .fit)
        }
        .frame(height: coverHeight)
        .clipShape(RoundedRectangle(cornerRadius: .minimal))
        .shadow(.light)
    }
}
