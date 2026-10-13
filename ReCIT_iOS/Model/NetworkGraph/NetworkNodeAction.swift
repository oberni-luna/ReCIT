//
//  NetworkNodeAction.swift
//  ReCIT_iOS
//
//  What VoiceOver offers on a node of the Réseau graph, besides selecting it (PRD 0019, Q44): the
//  gestures of its sheet, without opening it — open a group's page, a reader's profile, accept or
//  refuse what waits on me. `NetworkGraph.actions(for:)` says which a node has.
//

import Foundation

nonisolated enum NetworkNodeAction: Hashable, Sendable {
    /// « Ouvrir le groupe ».
    case openGroup
    /// « Voir le profil ».
    case viewProfile
    /// « Accepter » an invitation to a group, or a reader asking to be my friend.
    case accept
    /// « Refuser » it.
    case refuse
}
