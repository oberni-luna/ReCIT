//
//  InviteToGroupEmptyState.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import SwiftUI

/// What « Inviter des ami·es » shows when it lists nobody: that I have no friends to invite, or
/// that none of them goes by the name searched.
struct InviteToGroupEmptyState: View {
    private let hasFriends: Bool
    private let query: String

    /// - Parameters:
    ///   - hasFriends: Whether I have friends at all.
    ///   - query: The search, trimmed, named when friends exist but none matches.
    init(
        hasFriends: Bool,
        query: String
    ) {
        self.hasFriends = hasFriends
        self.query = query
    }

    var body: some View {
        if hasFriends {
            EmptyStateView(
                glyph: "magnifyingglass",
                title: "groups.invite.no_match",
                message: "groups.invite.no_match.message \(query)"
            )
        } else {
            EmptyStateView(
                glyph: "person.2",
                title: "groups.invite.no_friends",
                message: "groups.invite.no_friends.message"
            )
        }
    }
}

#Preview("Aucun·e ami·e") {
    InviteToGroupEmptyState(hasFriends: false, query: "")
}

#Preview("Aucun·e ami·e de ce nom") {
    InviteToGroupEmptyState(hasFriends: true, query: "marie")
}
