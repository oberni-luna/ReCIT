//
//  NetworkNodeID+E2E.swift
//  ReCIT_iOS
//
//  The suffix a node of the Réseau graph is found by in the end-to-end scenario:
//  `e2e.network.graph.node.<id>` — the server's id of the group or the reader, `me` for « Vous ».
//

import Foundation

extension NetworkNodeID {
    var e2eIdentifier: String {
        switch self {
        case .me: "me"
        case .group(let id): id
        case .reader(let id): id
        }
    }
}
