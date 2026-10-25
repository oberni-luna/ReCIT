//
//  FriendsSegmentView.swift
//  ReCIT_iOS
//
//  Réseau › Amis — frame `A1`. The two sections the Profil used to carry, moved without being
//  redrawn: the invitations waiting on me, then my friends and the way to add more (feature
//  0018). Sections only, so it slots under the segmented control of `NetworkView`'s list.
//

import SwiftUI
import SwiftData

struct FriendsSegmentView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(SyncStatusStore.self) private var syncStatus

    @Query(sort: \User.username) private var allUsers: [User]

    @Binding var path: NavigationPath

    /// `relation == .friend`, not "every user that is not me": the store also holds the owners
    /// met in a transaction, the readers looked up in the search and the members of my groups.
    private var friends: [User] {
        allUsers.filter { $0._id != userModel.myUser?._id && $0.relation == .friend }
    }

    /// The readers waiting on an answer from me. inventaire.io notifies nobody, so an
    /// invitation is only ever discovered by opening the app — which is why it is the first
    /// thing under the segmented control, and what the tab's badge counts.
    private var invitations: [User] {
        allUsers.filter { $0.relation == .requestReceived }
    }

    var body: some View {
        if invitations.isEmpty == false {
            Section {
                ForEach(invitations) { invitation in
                    InvitationRowView(user: invitation) {
                        path.append(NavigationDestination.user(user: invitation))
                    }
                }

                // The rest of the waiting — the requests I sent — lives one screen away,
                // since it has nothing to be answered here.
                NavigationLink(value: NavigationDestination.invitations) {
                    Text("network.invitations.all")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundTinted)
                }
                .accessibilityIdentifier("e2e.profile.invitations")
            } header: {
                Text("profile.invitations")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }

        Section {
            if syncStatus.shouldShowPlaceholder(.community) {
                SyncingInlineRow()
            } else {
                if friends.isEmpty {
                    Text("profile.network.empty")
                } else {
                    ForEach(friends) { friend in
                        NavigationLink(value: NavigationDestination.user(user: friend)) {
                            UserCellView(user: friend)
                        }
                    }
                }

                // Kept below the friends and present even when there are none — an empty
                // network is exactly when one needs it.
                NavigationLink(value: NavigationDestination.addFriends) {
                    Text("network.add_friends")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundTinted)
                }
                .accessibilityIdentifier("e2e.profile.addFriends")
            }
        } header: {
            Text("network.friends")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
    }
}
