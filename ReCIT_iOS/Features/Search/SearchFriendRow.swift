//
//  SearchFriendRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// A friend found by Recherche, drawn as in Réseau. Opens their profile.
struct SearchFriendRow: View {
    private let user: User

    init(_ user: User) {
        self.user = user
    }

    var body: some View {
        if user.isStillInTheStore {
            NavigationLink(value: NavigationDestination.user(user: user)) {
                UserCellView(user: user)
            }
            .accessibilityIdentifier(AccessibilityID.row)
        }
    }
}

private extension SearchFriendRow {
    enum AccessibilityID {
        static let row: String = "e2e.searchFriend"
    }
}

#Preview(traits: .modifier(SearchLocalPreviewStore())) {
    @Previewable @Query(sort: \User.username) var users: [User]
    NavigationStack {
        List {
            ForEach(users) { user in
                SearchFriendRow(user)
            }
        }
    }
}
