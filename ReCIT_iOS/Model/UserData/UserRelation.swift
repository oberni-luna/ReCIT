//
//  UserRelation.swift
//  ReCIT_iOS
//
//  Where I stand with another reader, as inventaire.io sees it.
//
//  `GET /api/relations` answers with four lists of user ids — `friends`, `userRequested`
//  (I asked), `otherRequested` (they asked) and `network` (friends plus the members of the
//  groups I am in). The app used to keep `network` alone, which is why the Profil's « Réseau »
//  section listed anyone who had ever landed in the store, and why nothing in the app could
//  tell a friend from a stranger met in a transaction.
//
//  This is server state copied locally, never a local truth: every sync rewrites it whole, so a
//  relation undone on the website disappears here on the next sync rather than lingering.
//

import Foundation

enum UserRelation: String, Codable, CaseIterable, Sendable {
    /// Nobody to me yet — the only state from which a request can be sent.
    case none
    case friend
    /// I asked, and I am waiting. Cancellable.
    case requestSent
    /// They asked, and they are waiting on me. Acceptable or refusable.
    case requestReceived
}

extension UserRelation {
    /// The relation of every reader named by a `/api/relations` answer, keyed by user id.
    ///
    /// Pure on purpose: the precedence between the four lists is the only rule worth a test,
    /// and it needs no store to be checked. `friends` wins over both pending states — the
    /// server can carry a stale request alongside an accepted relation, and a friend showing an
    /// « Accepter » button would be the worse of the two lies.
    ///
    /// `network` deliberately maps to nothing: it holds the members of my groups, who are not
    /// my friends. It is what tells the app *which users to fetch*, not who is close to me.
    static func byUserID(from dto: UserNetworkDTO) -> [String: UserRelation] {
        var states: [String: UserRelation] = [:]
        for id in dto.userRequested {
            states[id] = .requestSent
        }
        for id in dto.otherRequested {
            states[id] = .requestReceived
        }
        for id in dto.friends {
            states[id] = .friend
        }
        return states
    }
}
