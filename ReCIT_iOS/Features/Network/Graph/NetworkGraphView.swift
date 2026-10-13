//
//  NetworkGraphView.swift
//  ReCIT_iOS
//
//  « Tout » when there is someone or something around me: the constellation, framed on the whole
//  network with « Vous » in the middle (PRD 0019, Q33). Static for now — pinching, dragging and
//  touching come with `GraphViewport` (issue 0107).
//
//  **Measure, place, show.** Every node is laid out first, invisible, at its real size — real
//  text, the reader's text size up to the graph's cap (Q19, Q43). Once all are measured, their
//  boxes and the graph make a `NetworkGraphLayout`, whose placement is looked up in the cache or
//  computed off the main actor (Q45). Then the nodes appear in place: the graph opens already
//  laid out, with nothing flying in (Q23).
//
//  **When the network changes** — a friend arrives or leaves, a group changes — the new placement
//  is computed the same way and the nodes slide from their old places to the new ones; nothing
//  slides with Reduce Motion on (Q17).
//
//  **The text size is capped at `.xxxLarge`** on the graph alone (Q43): past it the boxes would
//  crowd any screen; the lists and VoiceOver carry the accessibility sizes.
//

import SwiftUI

struct NetworkGraphView: View {
    let graph: NetworkGraph

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Each node's size as last measured.
    @State private var sizes: [NetworkNodeID: CGSize] = [:]
    /// Where the nodes stand; `nil` until the first placement, which is shown without animation.
    @State private var placement: NetworkGraphPlacement?
    /// The room the graph has on screen.
    @State private var viewport: CGSize = .zero

    private let cache: NetworkGraphLayoutCache = .shared

    var body: some View {
        let boxes: [NetworkNodeID: NetworkNodeBox] = boxes
        let layout: NetworkGraphLayout? = .init(graph: graph, boxes: boxes)
        let isReady: Bool = placement != nil && viewport.width > 0 && viewport.height > 0
        let scale: CGFloat = isReady
            ? placement?.fittingScale(in: viewport, margin: DesignSystem.Spacing.medium.rawValue) ?? 1
            : 1

        NetworkConstellationView(
            graph: graph,
            positions: .init(placement?.positions ?? [:]),
            scale: scale,
            centre: .init(x: viewport.width / 2, y: viewport.height / 2),
            placed: isReady ? Set(placement?.positions.keys.map(\.self) ?? []) : [],
            boxes: boxes,
            onMeasure: { node, size in
                if sizes[node] != size {
                    sizes[node] = size
                }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            viewport = size
        }
        .clipped()
        .dynamicTypeSize(...NetworkGraphMetrics.largestTextSize)
        .task(id: layout) {
            await place(layout)
        }
    }

    /// The box of every node measured so far, anchored where its lines meet: the centre of the
    /// avatar for « Vous » and the readers, the centre of the card for a group.
    private var boxes: [NetworkNodeID: NetworkNodeBox] {
        var boxes: [NetworkNodeID: NetworkNodeBox] = [:]
        for node in graph.nodes {
            guard let size = sizes[node] else { continue }

            switch node {
            case .me:
                boxes[node] = .init(
                    size: size,
                    anchor: .init(x: size.width / 2, y: NetworkGraphMetrics.meSide / 2)
                )
            case .reader:
                boxes[node] = .init(
                    size: size,
                    anchor: .init(x: size.width / 2, y: NetworkGraphMetrics.friendSide / 2)
                )
            case .group:
                boxes[node] = .init(centred: size)
            }
        }
        return boxes
    }

    /// Places the nodes of `layout` — at once the first time, sliding afterwards.
    private func place(_ layout: NetworkGraphLayout?) async {
        guard let layout else { return }

        let next: NetworkGraphPlacement = await cache.placementOffMainActor(for: layout)
        guard Task.isCancelled == false, next != placement else { return }

        if let animation = NetworkGraphMotion.animation(
            isFirstPlacement: placement == nil,
            reduceMotion: reduceMotion
        ) {
            withAnimation(animation) {
                placement = next
            }
        } else {
            var transaction: Transaction = .init()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                placement = next
            }
        }
    }
}

#Preview {
    let strangers: [String] = (0..<8).map { "stranger-\($0)" }
    NetworkGraphView(
        graph: .init(
            .init(
                me: .init(id: "me", username: "olivier_berni"),
                friends: ["Inès", "Léa", "Rémi", "Camille", "Hugo", "Sami", "Nora", "Paul"].map {
                    .init(id: $0, username: $0)
                },
                requesters: [.init(id: "Ariane", username: "Ariane")],
                groups: [
                    .init(
                        id: "club",
                        name: "Club de Belleville",
                        role: .admin,
                        memberIds: ["me", "Inès", "Léa", "Rémi", "Camille"] + strangers,
                        pendingCount: 2
                    ),
                    .init(
                        id: "bd",
                        name: "BD & romans graphiques",
                        role: .member,
                        memberIds: ["me", "Rémi", "Hugo", "Sami"] + strangers
                    ),
                    .init(
                        id: "l11",
                        name: "Lecteurs du 11e",
                        role: .invited,
                        memberIds: ["Camille", "Nora"] + strangers,
                        invitorUsername: "Camille"
                    )
                ]
            )
        )
    )
    .background(.backgroundDefault)
}
