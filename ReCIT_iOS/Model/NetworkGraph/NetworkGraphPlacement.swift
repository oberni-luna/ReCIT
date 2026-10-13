//
//  NetworkGraphPlacement.swift
//  ReCIT_iOS
//
//  Where `NetworkGraphLayout` put each node of the Réseau graph, in **world** coordinates: points,
//  y downwards, « Vous » at the origin. The screen is the world scaled about « Vous » and moved to
//  the middle of the graph area; the nodes themselves keep their size at every scale — only their
//  positions move (PRD 0019, module 8).
//
//  Also the opening frame (Q33): the largest scale, no larger than full size, at which every node
//  is on screen with « Vous » in the middle. `GraphViewport` (issue 0107) takes it as its lower
//  bound.
//

import CoreGraphics

nonisolated struct NetworkGraphPlacement: Equatable, Sendable {
    /// Where each node's anchor sits.
    let positions: [NetworkNodeID: CGPoint]
    /// The box each node takes, its anchor at its position.
    let frames: [NetworkNodeID: CGRect]

    /// The smallest scale the opening frame goes down to, for a network far larger than the
    /// screen: past it the nodes would only be a blur.
    static let minimumScale: CGFloat = 0.05

    func position(of node: NetworkNodeID) -> CGPoint? {
        positions[node]
    }

    func frame(of node: NetworkNodeID) -> CGRect? {
        frames[node]
    }

    /// Every box together, or `.null` when nothing is placed.
    var bounds: CGRect {
        frames.values.reduce(CGRect.null) { $0.union($1) }
    }

    /// The scale that shows the whole network in `viewport`, « Vous » in its middle and every box
    /// at least `margin` inside its edges — never above `maximum`, full size by default: a small
    /// network opens at its natural size rather than blown up.
    ///
    /// The boxes do not scale with the positions, so the rule is not a ratio of two bounding
    /// boxes: each node limits the scale by how far its anchor is from « Vous » and how much of
    /// its box hangs past the anchor on the far side.
    func fittingScale(
        in viewport: CGSize,
        margin: CGFloat,
        maximum: CGFloat = 1
    ) -> CGFloat {
        let halfWidth: CGFloat = viewport.width / 2 - margin
        let halfHeight: CGFloat = viewport.height / 2 - margin
        var scale: CGFloat = maximum
        for (node, position) in positions {
            guard let frame = frames[node] else { continue }

            if position.x > 0 {
                scale = min(scale, (halfWidth - (frame.maxX - position.x)) / position.x)
            } else if position.x < 0 {
                scale = min(scale, (halfWidth - (position.x - frame.minX)) / -position.x)
            }
            if position.y > 0 {
                scale = min(scale, (halfHeight - (frame.maxY - position.y)) / position.y)
            } else if position.y < 0 {
                scale = min(scale, (halfHeight - (position.y - frame.minY)) / -position.y)
            }
        }
        return max(scale, Self.minimumScale)
    }
}
