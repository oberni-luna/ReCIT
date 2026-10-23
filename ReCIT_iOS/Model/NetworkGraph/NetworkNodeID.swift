//
//  NetworkNodeID.swift
//  ReCIT_iOS
//
//  Which node of the Réseau graph: « Vous », a group, or a reader — a friend or someone who asked
//  to be one. A reader is one node however many groups they share with me (PRD 0019).
//

import Foundation

nonisolated enum NetworkNodeID: Hashable, Sendable {
    case me
    case group(String)
    case reader(String)
}
