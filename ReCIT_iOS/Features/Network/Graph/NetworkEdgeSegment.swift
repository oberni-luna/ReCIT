//
//  NetworkEdgeSegment.swift
//  ReCIT_iOS
//
//  A line of the Réseau graph on screen: from one anchor to the other, and its kind, which says
//  how it is drawn.
//

import CoreGraphics

nonisolated struct NetworkEdgeSegment: Equatable, Sendable {
    let from: CGPoint
    let to: CGPoint
    let kind: NetworkEdgeKind
}
