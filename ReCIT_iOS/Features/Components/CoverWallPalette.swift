//
//  CoverWallPalette.swift
//  ReCIT_iOS
//
//  The paints of a cover that does not exist yet.
//
//  Before the first cover has arrived — and for good, if inventaire.io cannot be reached — the
//  wall is drawn rather than photographed: flat book-sized fields in the brand's own colours,
//  with a band and two title lines. No image ships in the bundle, which keeps a wall of book
//  jackets out of the binary; and the same paints are the wall's floor whenever the network
//  fails, so the screen has no empty state at all.
//
//  Same reasoning as `ShelfPalette`: these tints depict a painted object, not interface
//  chrome, so they are the same in light and dark and they do not live in
//  `DesignSystem.Color`. See PRD 0011.
//

import SwiftUI

enum CoverWallPalette {

    /// The painted jackets, in the order a wall cycles through them. Six, so a four-column
    /// grid never stacks the same tint twice in a row, vertically or horizontally.
    static let paintedTints: [Color] = [
        .init("color/green/700"),
        .init("color/red/800"),
        .init("color/yellow/400"),
        ShelfPalette.parchment,
        .init("color/green/800"),
        .init("color/green/100"),
    ]

    /// The band across the lower third of a painted jacket, and the two lines standing in for
    /// a title. White at low opacity rather than a token: they are highlights on a painted
    /// surface, and they have to read on all six tints.
    static let paintedBand: Color = .white.opacity(0.34)
    static let paintedTitle: Color = .white.opacity(0.62)

    /// The fold of the jacket over the spine, and the jacket's own edge. Both are black at low
    /// opacity, so they darken every tint by the same amount instead of tinting six colours
    /// six different ways — a flat field under a veil reads as glass, a field with a fold and
    /// an edge reads as a book.
    static let paintedFold: Color = .black.opacity(0.16)
    static let paintedEdge: Color = .black.opacity(0.14)

    /// A painted jacket's corner. The shelf draws books at 2 pt (`radius/book`); a wall seen
    /// flat keeps the same figure.
    static let coverCornerRadius: CGFloat = 2

    /// Which tint a slot is painted in.
    static func tint(at index: Int) -> Color {
        paintedTints[abs(index) % paintedTints.count]
    }
}
