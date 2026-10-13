//
//  NetworkReaderNode.swift
//  ReCIT_iOS
//
//  A reader in the Réseau graph: a friend or a requester, and whether they are **isolated** —
//  joined to none of the groups drawn, so placed near « Vous », tied to me alone (PRD 0019, Q6).
//
//  A requester is always isolated: the edges to groups are drawn for friends only (Q7), and a
//  request is placed by me, not by the groups (Q5b).
//

import Foundation

nonisolated struct NetworkReaderNode: Hashable, Sendable {
    let reader: NetworkGraphReader
    let state: NetworkReaderState
    let isIsolated: Bool

    var id: String {
        reader.id
    }

    var nodeID: NetworkNodeID {
        .reader(reader.id)
    }
}
