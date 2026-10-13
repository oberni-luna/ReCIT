//
//  NetworkGroupCardDetail.swift
//  ReCIT_iOS
//
//  The second line of a group's card in the Réseau graph (PRD 0019, Q9) — the same format at
//  every zoom: « Admin · 12 membres » for a group I administer, « 48 membres » for one I belong
//  to, « Invitation de Camille » for one that invited me. An invitation whose sender the store
//  does not know falls back on the number of members rather than an « Invitation de » with no
//  name.
//

import Foundation

nonisolated enum NetworkGroupCardDetail: Hashable, Sendable {
    case admin(memberCount: Int)
    case members(count: Int)
    case invitation(from: String)

    init(_ group: NetworkGraphGroup) {
        switch group.role {
        case .admin:
            self = .admin(memberCount: group.memberCount)
        case .member:
            self = .members(count: group.memberCount)
        case .invited:
            if let invitor = group.invitorUsername, invitor.isEmpty == false {
                self = .invitation(from: invitor)
            } else {
                self = .members(count: group.memberCount)
            }
        }
    }
}
