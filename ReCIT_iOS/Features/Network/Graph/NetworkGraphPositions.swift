//
//  NetworkGraphPositions.swift
//  ReCIT_iOS
//
//  Where each node of the Réseau graph stands, as something SwiftUI can animate: when the
//  network changes, every node slides from its old place to its new one, and the lines follow
//  them frame by frame (PRD 0019, Q17).
//
//  A node missing on one side counts as standing on « Vous », the origin of the world: one that
//  arrives slides out of me, which is where everything in the graph hangs from.
//

import SwiftUI

nonisolated struct NetworkGraphPositions: VectorArithmetic, Sendable {
    private(set) var points: [NetworkNodeID: CGPoint]

    init(_ points: [NetworkNodeID: CGPoint] = [:]) {
        self.points = points
    }

    subscript(node: NetworkNodeID) -> CGPoint? {
        points[node]
    }

    static var zero: NetworkGraphPositions {
        .init()
    }

    static func + (lhs: NetworkGraphPositions, rhs: NetworkGraphPositions) -> NetworkGraphPositions {
        var points: [NetworkNodeID: CGPoint] = lhs.points
        for (node, point) in rhs.points {
            let current: CGPoint = points[node] ?? .zero
            points[node] = .init(x: current.x + point.x, y: current.y + point.y)
        }
        return .init(points)
    }

    static func - (lhs: NetworkGraphPositions, rhs: NetworkGraphPositions) -> NetworkGraphPositions {
        var points: [NetworkNodeID: CGPoint] = lhs.points
        for (node, point) in rhs.points {
            let current: CGPoint = points[node] ?? .zero
            points[node] = .init(x: current.x - point.x, y: current.y - point.y)
        }
        return .init(points)
    }

    mutating func scale(by rhs: Double) {
        points = points.mapValues { .init(x: $0.x * rhs, y: $0.y * rhs) }
    }

    var magnitudeSquared: Double {
        points.values.reduce(0) { $0 + Double($1.x * $1.x + $1.y * $1.y) }
    }
}
