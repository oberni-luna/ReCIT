//
//  SortTipAim.swift
//  ReCIT_iOS
//
//  What an astuce card of the sorting surface is pointing at — the only thing that differs
//  between them, since the card itself is one component and knows nothing of its target
//  (PRD 0013).
//
//  It exists because the two aims are placed by two different mechanisms, and the difference
//  is worth naming rather than leaving as two call sites that look alike: the first cover of
//  a carousel is at a measured inset the surface can compute, whereas « Appliquer » is
//  wherever the action bar's own layout puts it and can only be found through the alignment
//  guide that bar publishes.
//
//  See issues 0077 and 0079.
//

import SwiftUI

enum SortTipAim {

    /// The first cover of « Livres à ranger ». The pointer sits under the card, at an inset
    /// derived from the carousel's own metrics, so the two cannot drift apart.
    case firstUnshelvedBook(SortGridMetrics)

    /// « Appliquer ». The pointer is **not** drawn with the card here: it is laid out by the
    /// panel on `HorizontalAlignment.sortApply`, because only the action bar knows where its
    /// middle button sits, and a full-width card cannot ride on that guide without dragging
    /// the whole column sideways.
    case applyButton

    /// How far in the pointer sits, for the aims that place it under the card themselves.
    /// `nil` where the pointer is someone else's business.
    var pointerInset: CGFloat? {
        switch self {
        case .firstUnshelvedBook(let metrics):
            // The carousel's own margin plus half a book card, less half the pointer — so
            // its apex falls on the centre of the first cover.
            let firstBookCentre: CGFloat = SortGridMetrics.shelfSpacing + metrics.bookColumnWidth / 2

            return max(0, firstBookCentre - TipPointerView.size.width / 2)

        case .applyButton:
            return nil
        }
    }

    /// How far the card is held off the edges of whatever it is laid in. The carousel's
    /// region carries no horizontal padding of its own, so the card brings the panel's;
    /// the block of controls already has it, so the card brings none.
    var cardInset: DesignSystem.Spacing {
        switch self {
        case .firstUnshelvedBook: .medium
        case .applyButton: .zero
        }
    }
}
