//
//  NetworkNodeAccessibility.swift
//  ReCIT_iOS
//
//  What VoiceOver says of one node of the Réseau graph and what it offers on it (PRD 0019, Q44):
//  its whole label, whether it is the heading, and its custom actions. Built once per
//  network by `NetworkGraphAccessibility`, not with each frame the camera moves.
//

import Foundation

struct NetworkNodeAccessibility: Hashable, Sendable {
    /// Everything the node says, in one string: « Club de Belleville, Admin, 2 demandes à
    /// examiner, 12 membres, dont 4 de vos amis : … ».
    let label: String
    /// The gestures offered besides selecting the node, in the order of its sheet's buttons.
    let actions: [NetworkNodeAction]
    /// « Vous », the heading the rest of the network hangs from.
    let isHeader: Bool
}
