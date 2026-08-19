//
//  ShelfFocusBookCell.swift
//  ReCIT_iOS
//
//  The pressed book's identity, shown above it while selection mode is on: cover, title and
//  authors on one line each. A pared-down `InventoryCell` — no subtitle and no transaction
//  tag, because this is read at a glance with a thumb on the shelf, not browsed.
//
//  It carries its own backdrop, fading in and out vertically, so it stays readable over the
//  veiled shelf without drawing a line across the screen. See ADR 0006.
//

import SwiftUI

struct ShelfFocusBookCell: View {
    let item: InventoryItem

    /// How opaque the backdrop gets at its middle. It fades to nothing at both edges, so it
    /// never draws a line across the veiled shelf.
    private let peakOpacity: Double = 0.9
    /// The cover's width. Its height follows from the book's own proportions.
    private let coverWidth: CGFloat = 48
    /// Stand-in proportions while the cover loads, so the row doesn't resize under itself.
    private let nominalAspect: CGFloat = 48.0 / 75.0

    var body: some View {
        if let edition = item.edition {
            // Bottom-aligned: the cover and the last line of text end on the same line,
            // however tall the cover turns out to be.
            HStack(alignment: .bottom, spacing: .sMedium) {
                cover(url: edition.image)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(edition.title)
                        .textStyle(.content400Bold)
                        .lineLimit(2)

                    Text(edition.authorNames.joined(separator: ", "))
                        .textStyle(.footnote200)
                        .lineLimit(1)
                }
                .foregroundStyle(.foregroundDefault)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, .medium)
            .padding(.top, .small)
            .padding(.bottom, .medium)
            .background(backdrop)
        }
    }

    /// The cover at its own proportions: the width is fixed, the height is whatever the book
    /// is — a tall paperback and a squat art book both look like themselves.
    private func cover(url: String?) -> some View {
        CachedAsyncImage(url: url.flatMap { URL(string: $0) }) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Color.clear
                .aspectRatio(nominalAspect, contentMode: .fit)
        }
        .frame(width: coverWidth)
        .clipShape(RoundedRectangle(cornerRadius: .minimal))
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
    }

    private var backdrop: some View {
        LinearGradient(
            stops: [
                .init(color: paper.opacity(0), location: 0),
                .init(color: paper.opacity(peakOpacity), location: 0.5),
                .init(color: paper.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var paper: Color { DesignSystem.Color.backgroundDefault.color }
}
