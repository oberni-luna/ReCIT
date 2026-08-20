//
//  WrappingHStack.swift
//  ReCIT_iOS
//
//  A horizontal stack that starts a new line instead of overflowing.
//
//  Added for the genre tags on the book screen (issue 0035). An `HStack` there is wrong in the
//  direction that matters: two or three genres fit, and the work that carries eight pushes the
//  whole row off the side of the screen. What is needed is one row of pills that flows onto a
//  second line, and SwiftUI has no stack that does that.
//
//  A `Layout` conformance rather than a `GeometryReader`: the layout has to *measure* its
//  children to know where the line breaks, and reading the container's width in a geometry
//  proxy only tells it how much room there is, not how much each pill wants. `Layout` gets both
//  in one pass and without the extra render cycle a geometry-driven version needs.
//
//  Kept deliberately dumb — leading-aligned lines, one spacing horizontally and one vertically,
//  no alignment guides, no priorities. It is a primitive, not a flow-layout framework; anything
//  it does not do should be added when a second caller actually needs it.
//

import SwiftUI

struct WrappingHStack: Layout {

    /// Between two items on the same line.
    let horizontalSpacing: CGFloat

    /// Between two lines.
    let verticalSpacing: CGFloat

    init(
        horizontalSpacing: DesignSystem.Spacing = .small,
        verticalSpacing: DesignSystem.Spacing = .small
    ) {
        self.horizontalSpacing = horizontalSpacing.rawValue
        self.verticalSpacing = verticalSpacing.rawValue
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        // An unspecified width means "how big would you like to be", and the honest answer for
        // a wrapping stack is one single line — the caller then proposes a real width and we
        // wrap into it. `.infinity` is treated the same way, so a nil and an infinite proposal
        // do not disagree.
        let availableWidth: CGFloat = proposal.width ?? .infinity
        let lines: [Line] = lines(availableWidth: availableWidth, subviews: subviews)

        guard !lines.isEmpty else { return .zero }

        let width: CGFloat = lines.map(\.width).max() ?? 0
        let height: CGFloat = lines.reduce(0) { $0 + $1.height }
            + verticalSpacing * CGFloat(lines.count - 1)

        return .init(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        // Re-measured against the width actually granted, which is not always the one proposed.
        let lines: [Line] = lines(availableWidth: bounds.width, subviews: subviews)
        var y: CGFloat = bounds.minY

        for line in lines {
            var x: CGFloat = bounds.minX
            for index in line.indices {
                let size: CGSize = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: .init(x: x, y: y + (line.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: .init(size)
                )
                x += size.width + horizontalSpacing
            }
            y += line.height + verticalSpacing
        }
    }

    // MARK: - Line breaking

    /// One rendered line: which subviews it holds, and the box they occupy.
    private struct Line {
        var indices: [Subviews.Index] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Greedy line breaking — each item goes on the current line unless it would overrun, in
    /// which case it opens the next one. An item wider than the whole width still gets a line
    /// of its own rather than being dropped, which is what keeps a long single tag visible at
    /// the largest Dynamic Type sizes.
    private func lines(availableWidth: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var current: Line = .init()

        for index in subviews.indices {
            let size: CGSize = subviews[index].sizeThatFits(.unspecified)
            let extendedWidth: CGFloat = current.indices.isEmpty
                ? size.width
                : current.width + horizontalSpacing + size.width

            if !current.indices.isEmpty && extendedWidth > availableWidth {
                lines.append(current)
                current = .init(indices: [index], width: size.width, height: size.height)
            } else {
                current.indices.append(index)
                current.width = extendedWidth
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty {
            lines.append(current)
        }
        return lines
    }
}

#Preview {
    WrappingHStack {
        ForEach(["Science-fiction", "Romans", "Policier", "Bande dessinée", "Essai", "Poésie"], id: \.self) { genre in
            Label { Text(genre) } icon: { }
                .labelStyle(.tag)
        }
    }
    .padding(.all, .medium)
    .frame(width: 320)
}
