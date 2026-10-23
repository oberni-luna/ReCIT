//
//  NetworkGraphZoomControls.swift
//  ReCIT_iOS
//
//  Zoomer, Dézoomer, Recentrer — for whoever does not pinch, and for VoiceOver (PRD 0019, Q33,
//  Q34, Q35): three glass buttons stacked at the bottom right of « Tout », one glass container, an
//  icon each and a name for VoiceOver. The Figma capsule (`Graph / Zoom Controls`, `521:15969`) is
//  a stand-in for Liquid Glass.
//
//  A button with nowhere to go — Zoomer at the largest scale, Dézoomer at the smallest, Recentrer
//  on the opening frame — is disabled, not hidden: the controls never move (Q34).
//

import SwiftUI

struct NetworkGraphZoomControls: View {
    let canZoomIn: Bool
    let canZoomOut: Bool
    let canRecentre: Bool
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onRecentre: () -> Void

    var body: some View {
        VStack(spacing: .small) {
            Button("network.graph.zoom_in", systemImage: "plus", action: onZoomIn)
                .disabled(canZoomIn == false)
                .accessibilityIdentifier("e2e.network.graph.zoomIn")
            Button("network.graph.zoom_out", systemImage: "minus", action: onZoomOut)
                .disabled(canZoomOut == false)
                .accessibilityIdentifier("e2e.network.graph.zoomOut")
            Button("network.graph.recentre", systemImage: "scope", action: onRecentre)
                .disabled(canRecentre == false)
                .accessibilityIdentifier("e2e.network.graph.recentre")
        }
        .labelStyle(.iconOnly)
        .glassButtonStyle()
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .glassEffectContainer()
    }
}

#Preview {
    NetworkGraphZoomControls(
        canZoomIn: true,
        canZoomOut: false,
        canRecentre: true,
        onZoomIn: {},
        onZoomOut: {},
        onRecentre: {}
    )
    .padding()
    .background(.backgroundDefault)
}
