//
//  NetworkConstellationView.swift
//  ReCIT_iOS
//
//  The Réseau graph drawn: the lines in a `Canvas` under real views for the nodes, each set by
//  `.position` at its place on screen (PRD 0019, module 8). Bottom to top: lines, friends,
//  groups, « Vous » (Q19).
//
//  The world is centred on « Vous »; the screen is the world scaled about `centre`. The nodes keep
//  their size at every scale — only their places move — so their boxes are the ones they were
//  measured with, and the layout can promise none covers another.
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
    /// Each node's box as measured, to centre its view on its anchor.
    let boxes: [NetworkNodeID: NetworkNodeBox]
    /// The node touched, if any.
    var selection: NetworkNodeID?
    /// What the node touched lights; `nil` when nothing is touched.
    var highlight: NetworkGraphHighlight?
    /// Reports a node's size whenever it is measured.
    let onMeasure: (NetworkNodeID, CGSize) -> Void
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
            NetworkEdgesCanvas(segments: segments, isHighlighting: highlight != nil)

            ForEach(graph.readers, id: \.id) { reader in
                NetworkFriendNode(
                    reader: reader,
                    isHighlighted: highlight?.contains(reader.nodeID) == true
                )
                .modifier(placement(of: reader.nodeID))
                .zIndex(selection == reader.nodeID ? 2 : 0)
            }

            ForEach(graph.groups, id: \.id) { group in
                NetworkGroupCard(
                    group: group,
                    isSelected: selection == .group(group.id)
                )
                .modifier(placement(of: .group(group.id)))
                .zIndex(selection == .group(group.id) ? 2 : 1)
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

    private func placement(of node: NetworkNodeID) -> NetworkNodePlacement {
        let anchor: CGPoint = anchor(of: node)
        let offset: CGSize = boxes[node].map {
            .init(width: $0.width / 2 - $0.anchorX, height: $0.height / 2 - $0.anchorY)
        } ?? .zero
        return .init(
            node: node,
            centre: .init(x: anchor.x + offset.width, y: anchor.y + offset.height),
            isPlaced: placed.contains(node),
            isDimmed: highlight.map { $0.contains(node) == false } ?? false,
            onMeasure: onMeasure,
            onActivate: node == .me ? nil : { onActivate(node) }
        )
    }

    /// The lines whose two ends are placed, from anchor to anchor.
    private var segments: [NetworkEdgeSegment] {
        graph.edges.compactMap { edge in
            guard placed.contains(edge.from), placed.contains(edge.to) else { return nil }

            return .init(
                from: anchor(of: edge.from),
                to: anchor(of: edge.to),
                kind: edge.kind,
                isLit: highlight?.contains(edge) == true
            )
        }
    }
}
