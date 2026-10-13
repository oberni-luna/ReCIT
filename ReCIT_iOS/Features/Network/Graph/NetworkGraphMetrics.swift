//
//  NetworkGraphMetrics.swift
//  ReCIT_iOS
//
//  The sizes of the Réseau graph that have no design token: the Figma components of the
//  `Réseau · Graphe` section were drawn at sizes the token scale does not hold, and PRD 0019
//  keeps them here rather than adding tokens (precedents: `ShelfCardMetrics`, `SortGridMetrics`).
//
//  Seeded with « Vous » (`Graph / Me`, `512:16006`); the other nodes add theirs as they are drawn.
//

import SwiftUI

enum NetworkGraphMetrics {
    /// The side of my avatar at the centre of the graph.
    static let meSide: CGFloat = 72
    /// The ring around it, painted over the photo's edge.
    static let meRingWidth: CGFloat = 3
    /// How far the « Vous » pill climbs over the bottom of the avatar.
    static let meLabelOverlap: CGFloat = 10
    /// The « Vous » pill's padding: 3 above and below, 10 on the sides — off the 2 / 4 / 8 / 12
    /// spacing scale.
    static let meLabelInsets: EdgeInsets = .init(
        top: 3,
        leading: 10,
        bottom: 3,
        trailing: 10
    )
}
