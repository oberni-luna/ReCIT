//
//  NetworkEdgesCanvas.swift
//  ReCIT_iOS
//
//  The lines of the Réseau graph, drawn in one `Canvas` under the nodes (PRD 0019, Q19, Q32,
//  Q32 bis): green to a group, from me or from a friend; a lighter green from me to each reader;
//  dashed for what waits on my answer — an invitation, a friend request.
//
//  **A node touched** (R2): its lines are lit — full green, 2.5 pt, dashed still if they were —
//  and every other line fades to 12 %, in place of its own opacity.
//
//  **Two sets of styles** (Q32): the full graph's (R1) and the overview's (R3), by
//  `NetworkEdgeStyle`.
//
//  One path per style, each stroked once: hundreds of lines cost a handful of draws, and where
//  two lines of a style cross they do not darken each other.
//
//  The colours are the design system's dynamic ones, resolved by the canvas against its own
//  environment, so the lines follow the appearance (Q42). Hidden from VoiceOver: the nodes say
//  who is joined to whom (issue 0110).
//

import SwiftUI

struct NetworkEdgesCanvas: View {
    let segments: [NetworkEdgeSegment]
    /// A node is touched: what it does not light fades.
    let isHighlighting: Bool
    /// The level drawn, which picks the set of styles (Q32).
    var level: NetworkGraphLevel = .full

    var body: some View {
        let tinted: Color = DesignSystem.Color.foregroundTinted.color
        let batches: [(style: NetworkEdgeStyle, path: Path)] = batches
        Canvas { context, _ in
            for batch in batches {
                context.stroke(
                    batch.path,
                    with: .color(tinted.opacity(batch.style.opacity)),
                    style: .init(
                        lineWidth: batch.style.lineWidth,
                        dash: batch.style.isDashed ? NetworkGraphMetrics.dash : []
                    )
                )
            }
        }
        .accessibilityHidden(true)
    }

    /// One path per style, in the order the styles first appear — the lit ones last, over the
    /// others.
    private var batches: [(style: NetworkEdgeStyle, path: Path)] {
        var batches: [(style: NetworkEdgeStyle, path: Path)] = []
        var indices: [NetworkEdgeStyle: Int] = [:]
        for segment in segments.filter({ $0.isLit == false }) + segments.filter(\.isLit) {
            let base: NetworkEdgeStyle = .init(segment.kind, level: level)
            let style: NetworkEdgeStyle = segment.isLit ? base.lit : (isHighlighting ? base.dimmed : base)
            let index: Int
            if let existing = indices[style] {
                index = existing
            } else {
                index = batches.count
                indices[style] = index
                batches.append((style, Path()))
            }
            batches[index].path.move(to: segment.from)
            batches[index].path.addLine(to: segment.to)
        }
        return batches
    }
}
