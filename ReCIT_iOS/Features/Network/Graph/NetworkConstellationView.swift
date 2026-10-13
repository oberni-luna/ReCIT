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
//  **Animatable.** Positions and scale are its `animatableData`: when the network changes, SwiftUI
//  runs this view frame by frame between the old places and the new, and the lines are redrawn
//  with the nodes rather than jumping ahead of them (Q17). A node not placed yet — just arrived,
//  still being measured — is laid out on « Vous », invisible, so it can be measured, and fades
//  in as it slides to its place.
//

import SwiftUI

struct NetworkConstellationView: View, Animatable {
    let graph: NetworkGraph
    /// Where each node's anchor stands, in the world.
    nonisolated var positions: NetworkGraphPositions
    /// How many screen points a world point takes.
    nonisolated var scale: CGFloat
    /// Where « Vous » stands on screen.
    let centre: CGPoint
    /// The nodes the placement has put somewhere: the others are not shown yet.
    let placed: Set<NetworkNodeID>
    /// Each node's box as measured, to centre its view on its anchor.
    let boxes: [NetworkNodeID: NetworkNodeBox]
    /// Reports a node's size whenever it is measured.
    let onMeasure: (NetworkNodeID, CGSize) -> Void

    nonisolated var animatableData: AnimatablePair<NetworkGraphPositions, CGFloat> {
        get { .init(positions, scale) }
        set {
            positions = newValue.first
            scale = newValue.second
        }
    }

    var body: some View {
        ZStack {
            NetworkEdgesCanvas(segments: segments)

            ForEach(graph.readers, id: \.id) { reader in
                NetworkFriendNode(reader: reader)
                    .modifier(placement(of: reader.nodeID))
            }

            ForEach(graph.groups, id: \.id) { group in
                NetworkGroupCard(group: group)
                    .modifier(placement(of: .group(group.id)))
            }

            NetworkMeNode(
                username: graph.me.username,
                imageUrl: graph.me.pictureURL
            )
            .modifier(placement(of: .me))
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
            onMeasure: onMeasure
        )
    }

    /// The lines whose two ends are placed, from anchor to anchor.
    private var segments: [NetworkEdgeSegment] {
        graph.edges.compactMap { edge in
            guard placed.contains(edge.from), placed.contains(edge.to) else { return nil }

            return .init(from: anchor(of: edge.from), to: anchor(of: edge.to), kind: edge.kind)
        }
    }
}
