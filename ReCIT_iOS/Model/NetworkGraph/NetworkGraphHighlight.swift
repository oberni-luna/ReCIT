//
//  NetworkGraphHighlight.swift
//  ReCIT_iOS
//
//  What stays lit when a node is touched — the node, its neighbours and the lines between them;
//  everything else fades (PRD 0019, R2, Q27).
//

import Foundation

nonisolated struct NetworkGraphHighlight: Hashable, Sendable {
    let nodes: Set<NetworkNodeID>
    let edges: Set<NetworkEdge>

    func contains(_ node: NetworkNodeID) -> Bool {
        nodes.contains(node)
    }

    func contains(_ edge: NetworkEdge) -> Bool {
        edges.contains(edge)
    }
}
