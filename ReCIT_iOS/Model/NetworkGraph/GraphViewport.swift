//
//  GraphViewport.swift
//  ReCIT_iOS
//
//  The camera over the Réseau graph (PRD 0019, module 7): how large the world is drawn, and where
//  « Vous » stands on screen. `CoverZoom` for a network — anchored at the fingers and bounded.
//
//  **World and screen.** The placement puts every node in world points, « Vous » at the origin,
//  y downwards. On screen, a world point is `origin + point × scale`, `origin` being where
//  « Vous » stands. From full size up, the nodes keep their size — only their anchors move apart.
//  Below it they shrink with the network, about their anchors: the placement keeps the boxes
//  apart at full size, and only a network drawn whole, nodes and gaps alike, keeps them apart
//  smaller.
//
//  **Two levels** (Q31, R3). Under ×0.6 the graph turns to its overview — dots, compact tiles,
//  « Vous » at 70 % — and back above ×0.7 (`NetworkGraphLevel`). The overview's nodes have sizes
//  of their own, which the view measures and hands over as `overviewBoxes`: they are what a
//  touch lands on, and what the bounds hold, while the overview is up.
//
//  **The range** (Q33). It opens on the opening frame: the whole network, « Vous » in the middle,
//  never above full size. That frame is also the smallest scale — zooming out further would only
//  shrink a network already whole on screen — and twice the full size is the largest. The
//  opening frame is drawn in full when the whole graph fits at ×0.6 or more, its nodes shrinking
//  with it (`NetworkGraphPlacement.shrinkingFittingScale`); otherwise it is the overview, framed
//  on the overview's own boxes (`fittingScale`). At the smallest scale the graph is always drawn
//  at the level it opened at.
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
//  **Touching** (Q36): a node answers to a touch inside its box on screen — at the level drawn —
//  grown to 44 pt for one smaller than a finger; where two answer, the one whose anchor is nearer
//  wins.
//
//  **The buttons** (Q33, Q34): Zoomer and Dézoomer pinch by ×1.5 about the middle of the graph
//  area; Recentrer goes back to the opening frame.
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
    /// What Zoomer multiplies the scale by, and Dézoomer divides it by (Q33).
    static let zoomStep: CGFloat = 1.5

    private(set) var placement: NetworkGraphPlacement
    /// The graph area on screen.
    private(set) var size: CGSize
    /// How many screen points a world point takes.
    private(set) var scale: CGFloat
    /// Where « Vous » stands, from the middle of the graph area.
    private(set) var offset: CGSize
    /// The opening frame's scale, which is also the smallest.
    private(set) var minimumScale: CGFloat
    /// What the nodes are drawn as: full, or the overview (Q31).
    private(set) var level: NetworkGraphLevel
    /// What the opening frame is drawn as.
    private(set) var openingLevel: NetworkGraphLevel
    /// Each node's box in the overview, on screen: a dot, a compact tile, « Vous » at 70 %. A node
    /// without one is taken at its full size.
    private(set) var overviewBoxes: [NetworkNodeID: NetworkNodeBox]

    /// The opening frame over `placement` in a graph area of `size`.
    init(
        placement: NetworkGraphPlacement,
        size: CGSize,
        overviewBoxes: [NetworkNodeID: NetworkNodeBox] = [:]
    ) {
        self.placement = placement
        self.size = size
        self.overviewBoxes = overviewBoxes
        let opening: (scale: CGFloat, level: NetworkGraphLevel) = Self.openingFrame(
            placement: placement,
            size: size,
            overviewBoxes: overviewBoxes
        )
        minimumScale = opening.scale
        scale = opening.scale
        offset = .zero
        openingLevel = opening.level
        level = opening.level
    }

    /// The opening frame's scale and level: in full if the whole graph fits at ×0.6 or more with
    /// its nodes shrinking with it; otherwise the overview, framed on its own boxes.
    private static func openingFrame(
        placement: NetworkGraphPlacement,
        size: CGSize,
        overviewBoxes: [NetworkNodeID: NetworkNodeBox]
    ) -> (scale: CGFloat, level: NetworkGraphLevel) {
        let shrinking: CGFloat = placement.shrinkingFittingScale(in: size, margin: margin)
        if shrinking >= NetworkGraphLevel.overviewEntryScale {
            return (shrinking, .full)
        }
        let overview: CGFloat = placement.fittingScale(
            in: size,
            margin: margin,
            maximum: NetworkGraphLevel.overviewEntryScale,
            boxes: overviewBoxes
        )
        return (overview, .overview)
    }

    // MARK: - Range

    var scaleRange: ClosedRange<CGFloat> {
        minimumScale...max(Self.maximumScale, minimumScale)
    }

    /// Still where it opened: nothing has been pinched or dragged since.
    var isAtOpeningFrame: Bool {
        scale == minimumScale && offset == .zero
    }

    /// Whether Zoomer still has room to zoom.
    var canZoomIn: Bool {
        scale < scaleRange.upperBound
    }

    /// Whether Dézoomer still has room to zoom out.
    var canZoomOut: Bool {
        scale > scaleRange.lowerBound
    }

    /// How large the full nodes are drawn: their measured size from full size up, smaller with
    /// the network below it.
    var nodeScale: CGFloat {
        min(scale, 1)
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

    /// `node`'s box on screen, around its anchor: at the level drawn, and at `nodeScale` in full.
    func screenFrame(of node: NetworkNodeID) -> CGRect? {
        guard let position = placement.position(of: node), let box = screenBox(of: node) else { return nil }

        return box.frame(at: screenPoint(of: position))
    }

    /// `node`'s box as drawn on screen, its anchor where the lines meet.
    func screenBox(of node: NetworkNodeID) -> NetworkNodeBox? {
        if level == .overview, let box = overviewBoxes[node] {
            return box
        }
        guard let position = placement.position(of: node), let frame = placement.frame(of: node) else { return nil }

        let box: NetworkNodeBox = .init(
            size: frame.size,
            anchor: .init(x: position.x - frame.minX, y: position.y - frame.minY)
        )
        return box.scaled(by: nodeScale)
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
        viewport.setScale(clampedScale(scale * magnification))
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
        viewport.setScale(minimumScale)
        viewport.offset = .zero
        return viewport
    }

    /// Zoomer: ×1.5 about the middle of the graph area, within the range (Q33).
    func zoomingIn() -> GraphViewport {
        pinching(by: Self.zoomStep, at: .init(x: size.width / 2, y: size.height / 2))
    }

    /// Dézoomer: ÷1.5 about the middle of the graph area, within the range (Q33).
    func zoomingOut() -> GraphViewport {
        pinching(by: 1 / Self.zoomStep, at: .init(x: size.width / 2, y: size.height / 2))
    }

    /// The camera with the overview's boxes as the view last measured them — and, since they
    /// frame an overview opening, the opening frame they make.
    func with(overviewBoxes: [NetworkNodeID: NetworkNodeBox]) -> GraphViewport {
        guard overviewBoxes != self.overviewBoxes else { return self }

        var viewport: GraphViewport = self
        viewport.overviewBoxes = overviewBoxes
        return viewport.updating(placement: placement, size: size)
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
        let opening: GraphViewport = .init(
            placement: placement,
            size: size,
            overviewBoxes: overviewBoxes
        )
        guard isAtOpeningFrame == false, self.size.width > 0, self.size.height > 0 else { return opening }

        var viewport: GraphViewport = opening
        viewport.level = level
        viewport.setScale(viewport.clampedScale(scale))
        viewport.offset = offset
        return viewport.bounded()
    }

    // MARK: - Bounds

    /// Sets the scale, and the level it calls for coming from the current one — the opening
    /// frame's at the smallest scale.
    private mutating func setScale(_ newScale: CGFloat) {
        scale = newScale
        level = newScale <= minimumScale ? openingLevel : level.next(at: newScale)
    }

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
            guard let nodeBox = screenBox(of: node) else { continue }

            box = box.union(nodeBox.frame(at: .init(x: position.x * scale, y: position.y * scale)))
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
