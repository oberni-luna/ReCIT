//
//  NetworkNodePlacement.swift
//  ReCIT_iOS
//
//  How a node of the Réseau graph is put on screen: measured at its own size first — the size
//  the placement keeps clear around it — then centred where its anchor falls. Hidden, and out of
//  VoiceOver's way, until the placement has a place for it; faded to 30 % when a touch lights
//  other nodes and not this one (R2).
//
//  The node is touched through the graph's hit test, not as a button; VoiceOver activates it
//  through `onActivate` instead, and the end-to-end scenario finds it by
//  `e2e.network.graph.node.<id>`.
//

import SwiftUI

struct NetworkNodePlacement: ViewModifier {
    let node: NetworkNodeID
    let centre: CGPoint
    let isPlaced: Bool
    var isDimmed: Bool = false
    let onMeasure: (NetworkNodeID, CGSize) -> Void
    /// What activating the node does, or `nil` for « Vous », which does nothing (Q28).
    var onActivate: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                onMeasure(node, size)
            }
            .opacity(isPlaced ? (isDimmed ? NetworkGraphMetrics.dimmedNodeOpacity : 1) : 0)
            .accessibilityHidden(isPlaced == false)
            .modifier(NetworkNodeActivation(onActivate: onActivate))
            .accessibilityIdentifier("e2e.network.graph.node.\(node.e2eIdentifier)")
            .position(centre)
    }
}
