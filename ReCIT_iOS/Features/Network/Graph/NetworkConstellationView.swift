//
//  NetworkConstellationView.swift
//  ReCIT_iOS
//
//  The Réseau graph drawn: the lines in a `Canvas` under real views for the nodes, each set by
//  `.position` at its place on screen (PRD 0019, module 8). Bottom to top: lines, friends,
//  groups, « Vous » (Q19).
//
//  The world is centred on « Vous »; the screen is the world scaled about `centre`. From full size
//  up, the nodes keep their size — only their places move apart; below it they shrink with the
//  network, about their anchors, so the gaps the layout left between them at full size stay
//  (`GraphViewport.nodeScale`).
//
//  **Two levels** (Q31, R3). In the overview, readers are dots, groups compact tiles, « Vous » is
//  drawn at 70 %, and the lines from « Vous » to the friends who have a group go (Q6). A node
//  whose full size is not measured yet — just arrived — is still laid out in full, invisible,
//  since the placement is computed from full sizes.
//
//  **Animatable.** Positions, scale and centre are its `animatableData`: when the network changes,
//  or the camera moves a node out from under the sheet, SwiftUI runs this view frame by frame
//  between the old places and the new, and the lines are redrawn with the nodes rather than
//  jumping ahead of them (Q17, Q30). A node not placed yet — just arrived,
//  still being measured — is laid out on « Vous », invisible, so it can be measured, and fades
//  in as it slides to its place.
//
//  **A node touched** (R2, Q25, Q27): what `highlight` lights stays at full strength, the rest
//  fades to 30 %; the lines it lights thicken; the group touched takes the selected look, the
//  readers lit the highlighted one; and the node touched is drawn over the others, under « Vous »
//  (Q19).
//
//  **To VoiceOver** (Q44) the lines are nothing, and each node is one element with its whole
//  label and its actions, read in `NetworkGraph.readingOrder`. The drawn nodes are hidden from
//  it — `zIndex`, which keeps the drawing order above, would order them for accessibility too.
//  VoiceOver reads instead a layer of transparent frames over the nodes, laid out in reading
//  order and given it as sort priorities, without which UIKit sorts them by where they are on
//  screen (`NetworkNodeAccessibilityFrame`).
//

import SwiftUI

struct NetworkConstellationView: View, Animatable {
    let graph: NetworkGraph
    /// Where each node's anchor stands, in the world.
    nonisolated var positions: NetworkGraphPositions
    /// How many screen points a world point takes.
    nonisolated var scale: CGFloat
    /// Where « Vous » stands on screen.
    nonisolated var centre: CGPoint
    /// The nodes the placement has put somewhere: the others are not shown yet.
    let placed: Set<NetworkNodeID>
    /// Each node's box as measured in full, to centre its view on its anchor.
    let boxes: [NetworkNodeID: NetworkNodeBox]
    /// What the nodes are drawn as.
    var level: NetworkGraphLevel = .full
    /// Each node's box on screen in the overview, « Vous » already at 70 %.
    var overviewBoxes: [NetworkNodeID: NetworkNodeBox] = [:]
    /// The node touched, if any.
    var selection: NetworkNodeID?
    /// What the node touched lights; `nil` when nothing is touched.
    var highlight: NetworkGraphHighlight?
    /// Reports a node's full size whenever it is measured.
    let onMeasure: (NetworkNodeID, CGSize) -> Void
    /// Reports the size of a group's compact tile whenever it is measured.
    var onMeasureOverview: (NetworkNodeID, CGSize) -> Void = { _, _ in }
    /// What VoiceOver says of each node, and in which order it reads them (Q44).
    var accessibility: NetworkGraphAccessibility = .init()
    /// Selects a node activated by VoiceOver.
    var onActivate: (NetworkNodeID) -> Void = { _ in }
    /// Does a VoiceOver custom action on a node.
    var onAction: (NetworkNodeID, NetworkNodeAction) -> Void = { _, _ in }

    nonisolated var animatableData: AnimatablePair<NetworkGraphPositions, AnimatablePair<CGFloat, CGPoint.AnimatableData>> {
        get { .init(positions, .init(scale, centre.animatableData)) }
        set {
            positions = newValue.first
            scale = newValue.second.first
            centre.animatableData = newValue.second.second
        }
    }

    var body: some View {
        ZStack {
            NetworkEdgesCanvas(segments: segments, isHighlighting: highlight != nil, level: level)

            // Drawn bottom to top by `zIndex`, and hidden from VoiceOver.
            ForEach(graph.readingOrder, id: \.self) { node in
                if let subject = subject(of: node) {
                    NetworkNodeView(
                        subject: subject,
                        isOverview: showsOverview(node),
                        isSelected: selection == node,
                        isHighlighted: highlight?.contains(node) == true
                    )
                    .modifier(placement(of: node))
                    .zIndex(zIndex(of: node))
                }
            }
        }
        // What VoiceOver reads, over the drawing, in the reading order (Q44).
        .overlay {
            ZStack {
                ForEach(graph.readingOrder.enumerated(), id: \.element) { offset, node in
                    accessibilityFrame(of: node, sortPriority: Double(graph.readingOrder.count - offset))
                }
            }
        }
    }

    private func subject(of node: NetworkNodeID) -> NetworkNodeView.Subject? {
        switch node {
        case .me:
            .me(graph.me)
        case .group(let id):
            graph.group(id: id).map { .group($0) }
        case .reader(let id):
            graph.reader(id: id).map { .reader($0) }
        }
    }

    /// Bottom to top: friends, groups, the node touched, « Vous » (Q19).
    private func zIndex(of node: NetworkNodeID) -> Double {
        switch node {
        case .me:
            3
        case _ where selection == node:
            2
        case .group:
            1
        case .reader:
            0
        }
    }

    /// Where `node`'s anchor is on screen; on « Vous » while it is not placed.
    private func anchor(of node: NetworkNodeID) -> CGPoint {
        let world: CGPoint = positions[node] ?? .zero
        return .init(x: centre.x + world.x * scale, y: centre.y + world.y * scale)
    }

    /// Whether `node` is drawn as in the overview: at that level, once its full size — which
    /// the placement needs — is known. « Vous » is the same view either way, only smaller.
    private func showsOverview(_ node: NetworkNodeID) -> Bool {
        level == .overview && boxes[node] != nil
    }

    /// The box `node` takes on screen — `nil` until it is measured — and how much its view is
    /// scaled to fill it.
    private func screenBox(of node: NetworkNodeID) -> (box: NetworkNodeBox?, scale: CGFloat) {
        if showsOverview(node) {
            return (overviewBoxes[node], node == .me ? NetworkGraphLevel.overviewMeScale : 1)
        }
        let nodeScale: CGFloat = min(scale, 1)
        return (boxes[node]?.scaled(by: nodeScale), nodeScale)
    }

    /// Where the centre of `node`'s view falls on screen.
    private func viewCentre(of node: NetworkNodeID, box: NetworkNodeBox?) -> CGPoint {
        let anchor: CGPoint = anchor(of: node)
        guard let box else { return anchor }

        return .init(x: anchor.x + box.width / 2 - box.anchorX, y: anchor.y + box.height / 2 - box.anchorY)
    }

    private func placement(of node: NetworkNodeID) -> NetworkNodePlacement {
        let (box, drawScale): (NetworkNodeBox?, CGFloat) = screenBox(of: node)
        // A compact tile's measure is the overview's; every other view measured is a full one.
        let measuresOverview: Bool = showsOverview(node) && node != .me
        return .init(
            node: node,
            centre: viewCentre(of: node, box: box),
            scale: drawScale,
            isPlaced: placed.contains(node),
            isDimmed: highlight.map { $0.contains(node) == false } ?? false,
            onMeasure: measuresOverview ? onMeasureOverview : onMeasure
        )
    }

    private func accessibilityFrame(
        of node: NetworkNodeID,
        sortPriority: Double
    ) -> NetworkNodeAccessibilityFrame {
        let box: NetworkNodeBox? = screenBox(of: node).box
        return .init(
            node: node,
            centre: viewCentre(of: node, box: box),
            size: box?.size ?? .zero,
            sortPriority: sortPriority,
            isPlaced: placed.contains(node) && box != nil,
            accessibility: accessibility[node],
            isSelected: selection == node,
            onActivate: node == .me ? nil : { onActivate(node) },
            onAction: { action in onAction(node, action) }
        )
    }

    /// The lines drawn at this level whose two ends are placed, from anchor to anchor — and, in the
    /// overview, a line from « Vous » to a friend when the touch lights it.
    private var segments: [NetworkEdgeSegment] {
        graph.edges.compactMap { edge in
            guard placed.contains(edge.from), placed.contains(edge.to) else { return nil }

            let isLit: Bool = highlight?.contains(edge) == true
            guard isLit || graph.isDrawn(edge, at: level) else { return nil }

            return .init(
                from: anchor(of: edge.from),
                to: anchor(of: edge.to),
                kind: edge.kind,
                isLit: isLit
            )
        }
    }
}
