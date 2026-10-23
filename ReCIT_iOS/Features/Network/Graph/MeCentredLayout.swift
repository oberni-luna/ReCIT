//
//  MeCentredLayout.swift
//  ReCIT_iOS
//
//  The empty state of « Tout » laid out by `MeCentredStack`: its first subview — « Vous » — at the
//  centre of the room it is offered, the others stacked under it, each centred on the width.
//  « Vous » is centred on its avatar, the point the graph's edges will meet, not on the avatar
//  and its pill together.
//
//  A `Layout` rather than a `VStack` with an alignment guide: a guide moves « Vous » to the
//  centre, but the stack does not grow for the offset, so at large text sizes the last link
//  would hang below the frame where nothing reaches it. This one measures its parts, says how
//  tall they need to be, and lets « Vous » climb rather than push a link out.
//
//  Its ideal height is the parts stacked tight — what `ViewThatFits` compares with the room, so
//  `NetworkEmptyView` scrolls only when even that does not fit.
//

import SwiftUI

struct MeCentredLayout: Layout {
    /// Between two parts.
    let spacing: CGFloat
    /// The point of the first subview that goes to the centre, down from its top; `nil` for its
    /// middle.
    let leadAnchor: CGFloat?

    init(
        spacing: DesignSystem.Spacing,
        leadAnchor: CGFloat? = nil
    ) {
        self.spacing = spacing.rawValue
        self.leadAnchor = leadAnchor
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let width: CGFloat = finite(proposal.width)
            ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max()
            ?? 0
        let stack: MeCentredStack = stack(width: width, subviews: subviews)
        // All the room offered, to centre « Vous » in it; the parts stacked tight when none is.
        let height: CGFloat = max(finite(proposal.height) ?? 0, stack.compactHeight)
        return .init(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let stack: MeCentredStack = stack(width: bounds.width, subviews: subviews)
        for (index, top) in stack.tops(in: bounds.height).enumerated() {
            subviews[index].place(
                at: .init(x: bounds.midX, y: bounds.minY + top),
                anchor: .top,
                proposal: .init(width: bounds.width, height: stack.heights[index])
            )
        }
    }

    private func stack(
        width: CGFloat,
        subviews: Subviews
    ) -> MeCentredStack {
        .init(
            heights: subviews.map { $0.sizeThatFits(.init(width: width, height: nil)).height },
            spacing: spacing,
            leadAnchor: leadAnchor
        )
    }

    /// An infinite proposal is no proposal: « as much as you like » has no centre.
    private func finite(_ value: CGFloat?) -> CGFloat? {
        guard let value, value.isFinite else { return nil }

        return value
    }
}
