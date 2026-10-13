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
    /// Selects a node activated by VoiceOver.
    var onActivate: (NetworkNodeID) -> Void = { _ in }

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

            ForEach(graph.readers, id: \.id) { reader in
                let isHighlighted: Bool = highlight?.contains(reader.nodeID) == true
                Group {
                    if showsOverview(reader.nodeID) {
                        NetworkFriendDot(reader: reader, isHighlighted: isHighlighted)
                    } else {
                        NetworkFriendNode(reader: reader, isHighlighted: isHighlighted)
                    }
                }
                .modifier(placement(of: reader.nodeID))
                .zIndex(selection == reader.nodeID ? 2 : 0)
            }

            ForEach(graph.groups, id: \.id) { group in
                let isSelected: Bool = selection == .group(group.id)
                Group {
                    if showsOverview(.group(group.id)) {
                        NetworkGroupTile(group: group, isSelected: isSelected)
                    } else {
                        NetworkGroupCard(group: group, isSelected: isSelected)
                    }
                }
                .modifier(placement(of: .group(group.id)))
                .zIndex(isSelected ? 2 : 1)
            }

            NetworkMeNode(
                username: graph.me.username,
                imageUrl: graph.me.pictureURL
            )
            .modifier(placement(of: .me))
            .zIndex(3)
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

    private func placement(of node: NetworkNodeID) -> NetworkNodePlacement {
        let anchor: CGPoint = anchor(of: node)
        let isOverview: Bool = showsOverview(node)
        // The box on screen, and how much the view is scaled to fill it.
        let box: NetworkNodeBox?
        let drawScale: CGFloat
        if isOverview {
            box = overviewBoxes[node]
            drawScale = node == .me ? NetworkGraphLevel.overviewMeScale : 1
        } else {
            let nodeScale: CGFloat = min(scale, 1)
            box = boxes[node]?.scaled(by: nodeScale)
            drawScale = nodeScale
        }
        let offset: CGSize = box.map {
            .init(width: $0.width / 2 - $0.anchorX, height: $0.height / 2 - $0.anchorY)
        } ?? .zero
        // A compact tile's measure is the overview's; every other view measured is a full one.
        let measuresOverview: Bool = isOverview && node != .me
        return .init(
            node: node,
            centre: .init(x: anchor.x + offset.width, y: anchor.y + offset.height),
            scale: drawScale,
            isPlaced: placed.contains(node),
            isDimmed: highlight.map { $0.contains(node) == false } ?? false,
            onMeasure: measuresOverview ? onMeasureOverview : onMeasure,
            onActivate: node == .me ? nil : { onActivate(node) }
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
