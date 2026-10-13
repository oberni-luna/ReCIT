//
//  NetworkEdgeSegment.swift
//  ReCIT_iOS
//
//  A line of the Réseau graph on screen: from one anchor to the other, its kind, which says how it
//  is drawn, and whether the node touched lights it (R2).
//

import CoreGraphics

nonisolated struct NetworkEdgeSegment: Equatable, Sendable {
    let from: CGPoint
    let to: CGPoint
    let kind: NetworkEdgeKind
    var isLit: Bool = false
}
