//
//  AvatarMetrics.swift
//  ReCIT_iOS
//
//  How the mark of an avatar without a picture is sized against the avatar's side.
//
//  `Avatar · Repli` is drawn at two sizes in Figma (Q21 bis): at 44 pt the initials are
//  `action300` and the `person.2` glyph 24 pt; at 32 pt the initials drop to `action200` —
//  `action300` fills a 32 pt disc — and the glyph to 18 pt. Every side from 44 up takes the
//  large type, every side below it the small one, and the glyph keeps the proportion of the
//  drawn size it is nearest to. Under 32 pt there is no mark at all, only the tinted fill: a
//  graph dot is 24 pt, and initials at that size are smaller than any text style (Q37).
//

import CoreGraphics

nonisolated struct AvatarMetrics: Equatable {

    /// The smallest side that takes `action300` initials and the 24 pt glyph.
    static let largeTypeSide: CGFloat = 44
    /// The smallest side that shows a mark at all.
    static let markSide: CGFloat = 32

    let side: CGFloat

    /// Whether the initials are `action300` (`true`) or `action200` (`false`).
    var usesLargeType: Bool {
        side >= Self.largeTypeSide
    }

    /// Whether initials or a glyph are drawn, or the tinted fill alone.
    var showsMark: Bool {
        side >= Self.markSide
    }

    /// The side of the square the `person.2` glyph is fitted in: 24 at 44, 18 at 32.
    var glyphSide: CGFloat {
        let ratio: CGFloat = usesLargeType ? 24 / Self.largeTypeSide : 18 / Self.markSide
        return (side * ratio).rounded()
    }
}
