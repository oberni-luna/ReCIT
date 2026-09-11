//
//  SortTipAim.swift
//  ReCIT_iOS
//
//  What an astuce card of the sorting surface is pointing at — the only thing that differs
//  between them, since the card itself is one component and knows nothing of its target
//  (PRD 0013).
//
//  It exists because the two aims are placed by two different mechanisms, and the difference
//  is worth naming rather than leaving as call sites that look alike: the first cover of a
//  carousel is at a measured inset the surface can compute, whereas the two buttons are
//  wherever the action bar's own layout puts them and can only be found through the alignment
//  guides that bar publishes.
//
//  See issues 0077, 0079 and 0080.
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

    /// The proposal control — the wand in a circle at the end of the same bar. Its pointer is
    /// laid out the same way « Appliquer »'s is, on `HorizontalAlignment.sortProposal`: the
    /// bar closes up around this control when the device cannot run the model, so nobody else
    /// knows where it lands.
    case proposalButton

    /// How far in the pointer sits, for the aims that place it under the card themselves.
    /// `nil` where the pointer is someone else's business.
    var pointerInset: CGFloat? {
        switch self {
        case .firstUnshelvedBook(let metrics):
            // The carousel's own margin plus half a book card, less half the pointer — so
            // its apex falls on the centre of the first cover.
            let firstBookCentre: CGFloat = SortGridMetrics.shelfSpacing + metrics.bookColumnWidth / 2

            return max(0, firstBookCentre - TipPointerView.size.width / 2)

        case .applyButton, .proposalButton:
            return nil
        }
    }

    /// The guide the pointer rides when the action bar is the one placing it, and `nil` for
    /// the aims that carry their own pointer under the card. It is what tells the panel both
    /// whether to draw a pointer above the bar and which control to aim it at.
    var barPointerAlignment: HorizontalAlignment? {
        switch self {
        case .firstUnshelvedBook: nil
        case .applyButton: .sortApply
        case .proposalButton: .sortProposal
        }
    }

    /// How far the card is held off the edges of whatever it is laid in. The carousel's
    /// region carries no horizontal padding of its own, so the card brings the panel's;
    /// the block of controls already has it, so the card brings none.
    var cardInset: DesignSystem.Spacing {
        switch self {
        case .firstUnshelvedBook: .medium
        case .applyButton, .proposalButton: .zero
        }
    }
}
