//
//  GraphViewport.swift
//  ReCIT_iOS
//
//  The camera over the Réseau graph (PRD 0019, module 7): how large the world is drawn, and where
//  « Vous » stands on screen. `CoverZoom` for a network — anchored at the fingers and bounded.
//
//  **World and screen.** The placement puts every node in world points, « Vous » at the origin,
//  y downwards. On screen, a world point is `origin + point × scale`, `origin` being where
//  « Vous » stands. The nodes keep their size at every scale — only their anchors move — so a
//  node's box on screen is its measured box, centred on its scaled anchor.
//
//  **The range** (Q33). It opens on the opening frame: the whole network, « Vous » in the middle,
//  never above full size (`NetworkGraphPlacement.fittingScale`). That frame is also the smallest
//  scale — zooming out further would only shrink a network already whole on screen — and twice
//  the full size is the largest.
//
//  **The bounds** (Q33): the network never leaves the screen. Whatever is pinched or dragged, the
//  network's box keeps covering the middle of the graph area: half of it can go past an edge, all
//  of it never. A tighter rule — the network kept inside the screen while it fits — would forbid
//  the one move the sheet needs: lifting a node out from under it (Q30).
//
//  **A gesture in flight** is applied on top of what the previous ones left (`pinching(by:at:)`,
//  `panning(by:)`), and the caller keeps the result when the fingers lift, as `CoverZoom` does.
//  A pinch is anchored at the fingers: the world point under them stays under them.
//
//  **Touching** (Q36): a node answers to a touch inside its box, grown to 44 pt for one smaller
//  than a finger; where two answer, the one whose anchor is nearer wins.
//
//  **When the network changes** — a sync, a new text size — the camera keeps its scale and its
//  place, brought back within the new bounds, so a sync never undoes a zoom. Only a camera still
//  on its opening frame follows the new opening frame.
//
//  Pure and `nonisolated`; tested by `GraphViewportTests`.
//

import CoreGraphics

nonisolated struct GraphViewport: Equatable, Sendable {
    /// The largest scale: twice the full size (Q33).
    static let maximumScale: CGFloat = 2
    /// The room kept between the network and the edges in the opening frame, and between a node
    /// lifted from under the sheet and the sheet.
    static let margin: CGFloat = 16
    /// The smallest touch target, on each side (Q36).
    static let touchSide: CGFloat = 44

    private(set) var placement: NetworkGraphPlacement
    /// The graph area on screen.
    private(set) var size: CGSize
    /// How many screen points a world point takes.
    private(set) var scale: CGFloat
    /// Where « Vous » stands, from the middle of the graph area.
    private(set) var offset: CGSize
    /// The opening frame's scale, which is also the smallest.
    private(set) var minimumScale: CGFloat

    /// The opening frame over `placement` in a graph area of `size`.
    init(
        placement: NetworkGraphPlacement,
        size: CGSize
    ) {
        self.placement = placement
        self.size = size
        let opening: CGFloat = placement.fittingScale(in: size, margin: Self.margin)
        minimumScale = opening
        scale = opening
        offset = .zero
    }

    // MARK: - Range

    var scaleRange: ClosedRange<CGFloat> {
        minimumScale...max(Self.maximumScale, minimumScale)
    }

    /// Still where it opened: nothing has been pinched or dragged since.
    var isAtOpeningFrame: Bool {
        scale == minimumScale && offset == .zero
    }

    // MARK: - World → screen

    /// Where « Vous », the world's origin, stands on screen.
    var origin: CGPoint {
        .init(x: size.width / 2 + offset.width, y: size.height / 2 + offset.height)
    }

    func screenPoint(of world: CGPoint) -> CGPoint {
        .init(x: origin.x + world.x * scale, y: origin.y + world.y * scale)
    }

    /// The world point drawn at `screen`.
    func worldPoint(at screen: CGPoint) -> CGPoint {
        .init(x: (screen.x - origin.x) / scale, y: (screen.y - origin.y) / scale)
    }

    /// Where `node`'s anchor stands on screen.
    func screenAnchor(of node: NetworkNodeID) -> CGPoint? {
        placement.position(of: node).map(screenPoint(of:))
    }

    /// `node`'s box on screen: its measured size, around its anchor.
    func screenFrame(of node: NetworkNodeID) -> CGRect? {
        guard let position = placement.position(of: node), let frame = placement.frame(of: node) else { return nil }

        let anchor: CGPoint = screenPoint(of: position)
        return frame.offsetBy(dx: anchor.x - position.x, dy: anchor.y - position.y)
    }

    // MARK: - Gestures

    /// The camera with a pinch of `magnification` applied, anchored at `anchor` on screen: the
    /// world point under the fingers stays under them, unless a bound stops it.
    func pinching(
        by magnification: CGFloat,
        at anchor: CGPoint
    ) -> GraphViewport {
        guard magnification > 0, magnification.isFinite else { return self }

        var viewport: GraphViewport = self
        viewport.scale = clampedScale(scale * magnification)
        let ratio: CGFloat = viewport.scale / scale
        let origin: CGPoint = origin
        let newOrigin: CGPoint = .init(
            x: anchor.x - (anchor.x - origin.x) * ratio,
            y: anchor.y - (anchor.y - origin.y) * ratio
        )
        viewport.offset = .init(
            width: newOrigin.x - size.width / 2,
            height: newOrigin.y - size.height / 2
        )
        return viewport.bounded()
    }

    /// The camera dragged by `translation`, within its bounds.
    func panning(by translation: CGSize) -> GraphViewport {
        var viewport: GraphViewport = self
        viewport.offset = .init(
            width: offset.width + translation.width,
            height: offset.height + translation.height
        )
        return viewport.bounded()
    }

    /// Back to the opening frame: the whole network, « Vous » in the middle.
    func recentred() -> GraphViewport {
        var viewport: GraphViewport = self
        viewport.scale = minimumScale
        viewport.offset = .zero
        return viewport
    }

    // MARK: - Touching

    /// The node a touch at `point` lands on, or `nil` for empty space (Q36). « Vous » answers
    /// like any other node: what a touch on it does is the caller's business (Q28).
    func node(at point: CGPoint) -> NetworkNodeID? {
        var best: (node: NetworkNodeID, distance: CGFloat)?
        for (node, _) in placement.positions {
            guard let frame = screenFrame(of: node), let anchor = screenAnchor(of: node) else { continue }

            let zone: CGRect = frame.insetBy(
                dx: min(0, (frame.width - Self.touchSide) / 2),
                dy: min(0, (frame.height - Self.touchSide) / 2)
            )
            guard zone.contains(point) else { continue }

            let distance: CGFloat = hypot(point.x - anchor.x, point.y - anchor.y)
            if let current = best, current.distance < distance || (current.distance == distance && Self.isAbove(current.node, node)) {
                continue
            }
            best = (node, distance)
        }
        return best?.node
    }

    // MARK: - The sheet

    /// The camera moved up just enough for `node` to clear `bottomInset` points at the bottom of
    /// the graph area — the part the sheet covers — with the zoom unchanged (Q30). Unmoved when
    /// the node is already clear; never so far that its top leaves the screen.
    func revealing(
        _ node: NetworkNodeID,
        bottomInset: CGFloat
    ) -> GraphViewport {
        guard bottomInset > 0, let frame = screenFrame(of: node) else { return self }

        let visibleBottom: CGFloat = size.height - bottomInset - Self.margin
        let needed: CGFloat = frame.maxY - visibleBottom
        let room: CGFloat = frame.minY - Self.margin
        let shift: CGFloat = min(needed, room)
        guard shift > 0 else { return self }

        return panning(by: .init(width: 0, height: -shift))
    }

    // MARK: - Changes

    /// The camera over a new placement or a new graph area: same scale and place, within the new
    /// bounds — or the new opening frame, for a camera that never left the old one.
    func updating(
        placement: NetworkGraphPlacement,
        size: CGSize
    ) -> GraphViewport {
        let opening: GraphViewport = .init(placement: placement, size: size)
        guard isAtOpeningFrame == false, self.size.width > 0, self.size.height > 0 else { return opening }

        var viewport: GraphViewport = opening
        viewport.scale = viewport.clampedScale(scale)
        viewport.offset = offset
        return viewport.bounded()
    }

    // MARK: - Bounds

    private func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, scaleRange.lowerBound), scaleRange.upperBound)
    }

    /// The camera with « Vous » moved back as little as needed for the network's box to cover the
    /// middle of the graph area.
    private func bounded() -> GraphViewport {
        guard let extent = extent else {
            var viewport: GraphViewport = self
            viewport.offset = .zero
            return viewport
        }

        // The box on screen is `extent` moved by the origin; it covers the middle when
        // `extent.minX + offset ≤ 0 ≤ extent.maxX + offset`.
        var viewport: GraphViewport = self
        viewport.offset = .init(
            width: min(max(offset.width, -extent.maxX), -extent.minX),
            height: min(max(offset.height, -extent.maxY), -extent.minY)
        )
        return viewport
    }

    /// The network's box at the current scale, from « Vous »'s place on screen; `nil` when
    /// nothing is placed.
    private var extent: CGRect? {
        var box: CGRect = .null
        for (node, position) in placement.positions {
            guard let frame = placement.frame(of: node) else { continue }

            box = box.union(frame.offsetBy(dx: position.x * (scale - 1), dy: position.y * (scale - 1)))
        }
        return box.isNull ? nil : box
    }

    /// Whether `lhs` is drawn over `rhs`: « Vous » over the groups, the groups over the readers
    /// (Q19) — what breaks a tie between two nodes at the same distance.
    private static func isAbove(
        _ lhs: NetworkNodeID,
        _ rhs: NetworkNodeID
    ) -> Bool {
        layer(of: lhs) > layer(of: rhs)
    }

    private static func layer(of node: NetworkNodeID) -> Int {
        switch node {
        case .reader: 0
        case .group: 1
        case .me: 2
        }
    }
}
