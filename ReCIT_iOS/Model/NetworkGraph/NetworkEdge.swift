//
//  NetworkEdge.swift
//  ReCIT_iOS
//
//  One line of the Réseau graph, from one node to another. « Vous » is always `from` when it is
//  an end; a reader is always `from` when the other end is a group.
//

import Foundation

nonisolated struct NetworkEdge: Hashable, Sendable {
    let from: NetworkNodeID
    let to: NetworkNodeID
    let kind: NetworkEdgeKind

    /// Whether `node` is one of its two ends.
    func touches(_ node: NetworkNodeID) -> Bool {
        from == node || to == node
    }
}
