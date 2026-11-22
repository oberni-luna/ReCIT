//
//  BookHeaderMetrics.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// What every height of the Fiche livre's header is made of, so the screen knows how far the fold
/// goes before it has happened. The title and the line under it are measured, since a title can
/// take several lines; the rest is read off the fonts.
struct BookHeaderMetrics {
    /// The cover's height at rest, and once folded — the height of a book row's cover.
    static let cover: (rest: CGFloat, folded: CGFloat) = (256, ThumbnailSize.medium.sizeInPt)
    /// How far the folded header rises into the navigation bar: the top of the small cover level
    /// with the top of the bar's buttons, as a reader's folded picture is on their profile.
    static let barRise: CGFloat = 62

    /// The title at rest, on as many lines as it takes.
    let titleHeight: CGFloat
    /// The « auteur·ices · sous-titre » line and the room above it, which fold away.
    let bylineHeight: CGFloat
    /// The title once folded: one line in `title50`, the size of an inline navigation bar's title.
    let foldedTitleHeight: CGFloat
    /// What the title is scaled by on its way down to `title50`.
    let foldedTitleScale: CGFloat

    init(
        dynamicTypeSize: DynamicTypeSize,
        titleHeight: CGFloat,
        bylineHeight: CGFloat
    ) {
        let title: UIFont = DesignSystem.TextStyle.title200.uiFont(for: dynamicTypeSize)
        let folded: UIFont = DesignSystem.TextStyle.title50.uiFont(for: dynamicTypeSize)
        self.titleHeight = titleHeight
        self.bylineHeight = bylineHeight
        foldedTitleHeight = folded.lineHeight
        foldedTitleScale = folded.pointSize / title.pointSize
    }

    /// Never shorter at rest than folded, which a title not measured yet would be.
    var titleFrameHeight: (rest: CGFloat, folded: CGFloat) {
        (max(titleHeight, foldedTitleHeight), foldedTitleHeight)
    }

    var titleScale: (rest: CGFloat, folded: CGFloat) {
        (1, foldedTitleScale)
    }

    /// The cover shrinks, the header rises into the bar, the title comes down to one small line
    /// and the line under it goes: the page under the header stays glued to its foot until then.
    var collapse: FoldingHeaderCollapse {
        .init(
            distance: (Self.cover.rest - Self.cover.folded)
                + Self.barRise
                + (titleFrameHeight.rest - titleFrameHeight.folded)
                + bylineHeight
        )
    }
}
