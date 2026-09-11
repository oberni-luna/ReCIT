//
//  InvitationsView.swift
//  ReCIT_iOS
//
//  Both directions of the waiting, on one screen — frame `N8` of the « Réseau » pass: what is
//  being asked of me, and what I have asked of others.
//
//  One screen for the two because it is one call: `GET /api/relations` answers with
//  `otherRequested` and `userRequested` together, and the store holds both as a relation. There
//  is nothing to fetch here at all — the lists are `@Query`, so answering an invitation from the
//  Profil redraws this screen behind it, and answering one here redraws the Profil.
//
//  A request I sent carries no gesture here: it is taken back from the reader's own profile,
//  where the sentence explaining what cancelling means has room to sit.
//

import SwiftUI
import SwiftData

struct InvitationsView: View {
    @Query(sort: \User.username) private var allUsers: [User]

    @Binding var path: NavigationPath

    private var received: [User] {
        allUsers.filter { $0.relation == .requestReceived }
    }

    private var sent: [User] {
        allUsers.filter { $0.relation == .requestSent }
    }

    var body: some View {
        List {
            if received.isEmpty && sent.isEmpty {
                Section {
                    EmptyStateView(
                        glyph: "envelope",
                        title: "network.invitations.empty",
                        message: "network.invitations.empty.message"
                    )
                    .padding(.vertical, .large)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if received.isEmpty == false {
                Section {
                    ForEach(received) { user in
                        InvitationRowView(user: user) {
                            path.append(NavigationDestination.user(user: user))
                        }
                    }
                } header: {
                    Text("network.invitations.received")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            if sent.isEmpty == false {
                Section {
                    ForEach(sent) { user in
                        ReaderRowView(user: user) {
                            path.append(NavigationDestination.user(user: user))
                        }
                    }
                } header: {
                    Text("network.invitations.sent")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
        }
        .applyListBackground()
        .navigationTitle("network.invitations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
