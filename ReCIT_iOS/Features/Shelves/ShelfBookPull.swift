//
//  ShelfBookPull.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/11/2026.
//

import CoreGraphics

/// How far the grown book leans towards the finger in selection mode, as if tied to its place
/// on the shelf by a rubber band: a small gap is followed almost point for point, a large one
/// tends to a cap it never reaches.
///
/// The cap is what keeps the copy over the shelf's own book, which shows through the
/// half-strength veil. Travel further on an axis than the copy's extra growth covers and the
/// shelf's book shows beside it, so the book reads twice. Hence half the extra growth per axis,
/// and never more than `maximumPull` however large the book.
struct ShelfBookPull {
    static let maximumPull: CGFloat = 20

    /// The book at rest, unscaled.
    let bookSize: CGSize
    /// How much the copy is grown (1 = at rest, which leaves no room to lean).
    let growth: CGFloat

    /// The furthest the book may travel on each axis.
    var cap: CGSize {
        .init(
            width: cap(of: bookSize.width),
            height: cap(of: bookSize.height)
        )
    }

    /// `cap × gap / (cap + |gap|)`: zero at zero, the sign of the gap, and the cap only at infinity.
    private static func stretch(_ gap: CGFloat, upTo cap: CGFloat) -> CGFloat {
        guard cap > 0 else { return 0 }
        return cap * gap / (cap + abs(gap))
    }

    /// The book's offset when the finger is `gap` away from the book's centre at rest, each axis
    /// on its own.
    func offset(towards gap: CGSize) -> CGSize {
        .init(
            width: Self.stretch(gap.width, upTo: cap.width),
            height: Self.stretch(gap.height, upTo: cap.height)
        )
    }

    private func cap(of side: CGFloat) -> CGFloat {
        min(Self.maximumPull, max(0, (growth - 1) / 2 * side))
    }
}
