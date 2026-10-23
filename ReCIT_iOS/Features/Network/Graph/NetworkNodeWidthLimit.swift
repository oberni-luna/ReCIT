//
//  NetworkNodeWidthLimit.swift
//  ReCIT_iOS
//
//  A line of text in a node of the Réseau graph: as wide as it needs, never wider than
//  `maxWidth`, and cut on one line past it (Q19).
//
//  A `Layout` because neither frame does it: `.frame(maxWidth:)` stretches a short name to the
//  full width — every friend 100 pt wide, and the placement spreading them for nothing — and,
//  under the `fixedSize()` a node is measured with, it lets a long name overflow uncut. This one
//  takes the text's natural width, caps it, and proposes the capped width back so the text
//  truncates.
//

import SwiftUI

struct NetworkNodeWidthLimit: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard let subview = subviews.first else { return .zero }

        return subview.sizeThatFits(capped(proposal, subview))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard let subview = subviews.first else { return }

        subview.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: .init(width: bounds.width, height: bounds.height)
        )
    }

    /// The text's own width, or the room offered, whichever is less — and never past the limit.
    private func capped(
        _ proposal: ProposedViewSize,
        _ subview: LayoutSubview
    ) -> ProposedViewSize {
        let natural: CGFloat = subview.sizeThatFits(.unspecified).width
        let offered: CGFloat = proposal.width.map { $0.isFinite ? $0 : natural } ?? natural
        return .init(width: min(natural, offered, maxWidth), height: proposal.height)
    }
}
