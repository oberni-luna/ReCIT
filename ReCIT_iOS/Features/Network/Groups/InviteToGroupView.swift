//
//  InviteToGroupView.swift
//  ReCIT_iOS
//
//  My friends, and where each stands in a group — frame `A10`. Any member may invite, not only
//  the admins. Invitations go to friends only: they are the readers the app knows by name, and a
//  stranger is better found by the group's own search.
//
//  Inviting a friend who had asked to join accepts them: the server turns the invitation into
//  an acceptance, and the pill says so.
//

import SwiftUI
import SwiftData

struct InviteToGroupView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \User.username) private var allUsers: [User]
    @Query private var storedGroups: [StoredGroup]

    let groupId: String

    @State private var query: String = ""
    @State private var isInvitingByEmail: Bool = false

    private var group: ReaderGroup? {
        groupModel.group(id: groupId, among: storedGroups)
    }

    private var myFriends: [User] {
        allUsers.filter { $0.relation == .friend && $0._id != userModel.myUser?._id }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isQuerying: Bool {
        trimmedQuery.isEmpty == false
    }

    private var friends: [User] {
        guard isQuerying else { return myFriends }
        return myFriends.filter { $0.username.localizedStandardContains(trimmedQuery) }
    }

    var body: some View {
        List {
            Group {
                if friends.isEmpty {
                    Section {
                        InviteToGroupEmptyState(hasFriends: myFriends.isEmpty == false, query: trimmedQuery)
                            .padding(.vertical, .large)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(friends) { friend in
                            HStack(spacing: .sMedium) {
                                UserCellView(user: friend)
                                Spacer(minLength: .zero)
                                trailing(for: friend)
                            }
                        }
                    } header: {
                        Text("groups.invite.friends")
                            .textStyle(.action200)
                            .foregroundStyle(.foregroundSecondary)
                    } footer: {
                        GroupNote("groups.invite.footer")
                    }
                }

                if isQuerying {
                    EmailInvitationSection(.group(id: groupId)) {
                        isInvitingByEmail = true
                    }
                }
            }
            .textCase(nil)
        }
        .applyListBackground()
        .sheet(isPresented: $isInvitingByEmail) {
            EmailInvitationSheet(
                initialAddresses: EmailInvitationList.initialText(fromSearch: query),
                target: .group(id: groupId)
            )
        }
        .navigationTitle("groups.invite")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("groups.invite.prompt")
        )
    }

    @ViewBuilder
    private func trailing(for friend: User) -> some View {
        switch group?.role(of: friend._id) {
        case .admin, .member:
            Label("groups.invite.already_member", systemImage: "checkmark")
                .labelStyle(.secondaryTag)
        case .invited:
            Label("groups.invitation.sent", systemImage: "clock")
                .labelStyle(.secondaryTag)
        case .declined:
            Label("groups.invite.declined", systemImage: "xmark")
                .labelStyle(.secondaryTag)
        case .requested:
            Button("network.invitation.accept", systemImage: "checkmark") {
                invite(friend)
            }
            .buttonStyle(.pill(.prominent))
        case .none:
            Button("groups.invite.action", systemImage: "plus") {
                invite(friend)
            }
            .buttonStyle(.pill())
            .accessibilityIdentifier("e2e.group.invite")
        }
    }

    private func invite(_ friend: User) {
        groupModel.perform(.invite, on: groupId, target: friend._id, modelContext: modelContext)
    }
}
