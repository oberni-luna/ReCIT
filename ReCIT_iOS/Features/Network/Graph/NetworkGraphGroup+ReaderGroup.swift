//
//  NetworkGraphGroup+ReaderGroup.swift
//  ReCIT_iOS
//
//  One of my groups, copied into the value the Réseau graph is built from: my role in it, who is
//  in it, how many, who invited me, and how many requests wait on me there (PRD 0019, Q7–Q9,
//  Q22).
//

import Foundation

extension NetworkGraphGroup {
    /// `nil` for a group the graph does not draw: one I asked to join, declined, or hold no role
    /// in (Q4).
    ///
    /// - Parameters:
    ///   - me: The signed-in reader's id.
    ///   - usernames: The handle of every reader in the store, by id — to name who invited me.
    init?(
        group: ReaderGroup,
        me: String,
        usernames: [String: String]
    ) {
        let role: NetworkGroupRole
        switch group.role(of: me) {
        case .admin: role = .admin
        case .member: role = .member
        case .invited: role = .invited
        case .requested, .declined, .none: return nil
        }

        self.init(
            id: group.id,
            name: group.name,
            pictureURL: group.pictureURL,
            role: role,
            memberIds: group.memberIds,
            memberCount: group.memberCount,
            invitorUsername: group.invitor(of: me).flatMap { usernames[$0] },
            pendingCount: group.requestsToReview(by: me)
        )
    }
}
