//
//  NetworkNodeAccessibilityFrame.swift
//  ReCIT_iOS
//
//  A node of the Réseau graph as VoiceOver reads it (PRD 0019, Q44): a transparent frame over the
//  node drawn, the same size and in the same place, carrying its label and actions
//  (`NetworkNodeAccessibilityElement`). The constellation lays these frames out in the graph's
//  reading order, apart from the drawn nodes, whose `zIndex` would otherwise set the order they
//  are read in. The order is given twice, since each side of accessibility reads it its own way
//  (checked in the simulator, issue 0110): the automation tree follows the order of declaration,
//  and the elements UIKit hands VoiceOver are sorted by place on screen unless a sort priority
//  says otherwise.
//
//  It takes no touch — a finger goes through it to the graph's own hit test — and is hidden
//  until its node is placed and measured. The end-to-end scenario finds the node by its
//  `e2e.network.graph.node.<id>` identifier.
//

import SwiftUI

struct NetworkNodeAccessibilityFrame: View {
    let node: NetworkNodeID
    /// Where the centre of the node drawn is on screen.
    let centre: CGPoint
    /// The room the node drawn takes on screen.
    let size: CGSize
    /// Higher is read first: its place in `NetworkGraph.readingOrder`, counted from the end.
    let sortPriority: Double
    let isPlaced: Bool
    /// What VoiceOver says of the node and offers on it; `nil` until the graph is first described.
    let accessibility: NetworkNodeAccessibility?
    var isSelected: Bool = false
    /// What activating the node does, or `nil` for « Vous », which does nothing (Q28).
    let onActivate: (() -> Void)?
    /// Does one of the node's custom actions.
    let onAction: (NetworkNodeAction) -> Void

    var body: some View {
        Color.clear
            .frame(width: size.width, height: size.height)
            .modifier(
                NetworkNodeAccessibilityElement(
                    accessibility: accessibility,
                    isSelected: isSelected,
                    onActivate: onActivate,
                    onAction: onAction
                )
            )
            .accessibilitySortPriority(sortPriority)
            .accessibilityHidden(isPlaced == false)
            .accessibilityIdentifier("e2e.network.graph.node.\(node.e2eIdentifier)")
            .allowsHitTesting(false)
            .position(centre)
    }
}
