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
//  bound. Two rules, for the two ways nodes are drawn below full size (issue 0109): nodes that
//  shrink with the network — the full graph — and nodes of a size of their own — the overview's
//  dots and tiles.
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
    ///
    /// `boxes`, when given, are the sizes the nodes are drawn at instead of their placed frames —
    /// the overview's.
    func fittingScale(
        in viewport: CGSize,
        margin: CGFloat,
        maximum: CGFloat = 1,
        boxes: [NetworkNodeID: NetworkNodeBox] = [:]
    ) -> CGFloat {
        let halfWidth: CGFloat = viewport.width / 2 - margin
        let halfHeight: CGFloat = viewport.height / 2 - margin
        var scale: CGFloat = maximum
        for (node, position) in positions {
            guard let frame = boxes[node]?.frame(at: position) ?? frames[node] else { continue }

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

    /// The scale that shows the whole network in `viewport` when the nodes shrink with it — the
    /// full graph below full size: the network's box, from « Vous », scaled to fit, every box at
    /// least `margin` inside the edges. Never above full size, from which the nodes keep their
    /// size and `fittingScale` applies.
    func shrinkingFittingScale(
        in viewport: CGSize,
        margin: CGFloat
    ) -> CGFloat {
        let halfWidth: CGFloat = viewport.width / 2 - margin
        let halfHeight: CGFloat = viewport.height / 2 - margin
        let box: CGRect = bounds
        guard box.isNull == false else { return 1 }

        let farX: CGFloat = max(box.maxX, -box.minX)
        let farY: CGFloat = max(box.maxY, -box.minY)
        var scale: CGFloat = 1
        if farX > 0 {
            scale = min(scale, halfWidth / farX)
        }
        if farY > 0 {
            scale = min(scale, halfHeight / farY)
        }
        return max(scale, Self.minimumScale)
    }
}
