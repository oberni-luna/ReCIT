//
//  NetworkNodePlacement.swift
//  ReCIT_iOS
//
//  How a node of the Réseau graph is put on screen: measured at its own size first — the size
//  the placement keeps clear around it — then centred where its anchor falls. Hidden, and out of
//  VoiceOver's way, until the placement has a place for it.
//

import SwiftUI

struct NetworkNodePlacement: ViewModifier {
    let node: NetworkNodeID
    let centre: CGPoint
    let isPlaced: Bool
    let onMeasure: (NetworkNodeID, CGSize) -> Void

    func body(content: Content) -> some View {
        content
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                onMeasure(node, size)
            }
            .opacity(isPlaced ? 1 : 0)
            .accessibilityHidden(isPlaced == false)
            .position(centre)
    }
}
