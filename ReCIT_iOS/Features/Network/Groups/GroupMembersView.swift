//
//  GroupMembersView.swift
//  ReCIT_iOS
//
//  Everyone in a group, by role — frame `A9`: the admins, the members, then, for the admins
//  alone, the requests waiting on them, and the invitations still unanswered.
//
//  An admin gets a « … » on each member's line: see the profile, name them admin, remove them.
//  Never on another admin's line beyond the profile — the server refuses to remove an admin, and
//  has no way to take the role back. Both gestures ask first (see `MemberGesture`).
//

import SwiftUI
import SwiftData

struct GroupMembersView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \User.username) private var allUsers: [User]

    let groupId: String
    @Binding var path: NavigationPath

    @State private var pendingGesture: MemberGesture?

    private var group: ReaderGroup? {
        groupModel.group(id: groupId)
    }

    private var amAdmin: Bool {
        group?.role(of: groupModel.myUserId) == .admin
    }

    private func users(_ memberships: [GroupMembership]) -> [User] {
        let ids: Set<String> = Set(memberships.map(\.user))
        return allUsers.filter { ids.contains($0._id) }
    }

    var body: some View {
        List {
            if let group {
                section("groups.members.admins", users: users(group.admins), role: .admin)
                section("groups.members.members", users: users(group.members), role: .member)

                if amAdmin && group.requested.isEmpty == false {
                    Section {
                        ForEach(users(group.requested)) { user in
                            GroupRequestRowView(user: user, groupId: groupId) {
                                path.append(NavigationDestination.user(user: user))
                            }
                        }
                    } header: {
                        header("groups.requests.to_review")
                    }
                }

                if group.invited.isEmpty == false {
                    section("groups.members.invited", users: users(group.invited), role: .invited)
                }
            }
        }
        .applyListBackground()
        .navigationTitle("groups.members")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            confirmationTitle,
            isPresented: .init(
                get: { pendingGesture != nil },
                set: { if $0 == false { pendingGesture = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingGesture
        ) { gesture in
            switch gesture {
            case .makeAdmin:
                Button("groups.member.make_admin") { run(gesture) }
            case .kick:
                Button("groups.member.kick", role: .destructive) { run(gesture) }
            }
            Button("action.cancel", role: .cancel) {}
        } message: { gesture in
            switch gesture {
            case .makeAdmin:
                Text("groups.member.make_admin.message")
            case .kick:
                Text("groups.member.kick.message")
            }
        }
    }

    private var confirmationTitle: LocalizedStringKey {
        switch pendingGesture {
        case .makeAdmin(let user):
            "groups.member.make_admin.confirm \(user.username)"
        case .kick(let user):
            "groups.member.kick.confirm \(user.username)"
        case .none:
            ""
        }
    }

    private func run(_ gesture: MemberGesture) {
        groupModel.perform(gesture.action, on: groupId, target: gesture.user._id, modelContext: modelContext)
        pendingGesture = nil
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, users: [User], role: GroupRole) -> some View {
        if users.isEmpty == false {
            Section {
                ForEach(users) { user in
                    HStack(spacing: .sMedium) {
                        Button {
                            path.append(NavigationDestination.user(user: user))
                        } label: {
                            GroupMemberRowView(user: user, role: role)
                        }
                        .buttonStyle(.plain)

                        if amAdmin && role == .member && user._id != groupModel.myUserId {
                            Menu {
                                Group {
                                    Button("groups.member.make_admin", systemImage: "checkmark.seal") {
                                        pendingGesture = .makeAdmin(user)
                                    }
                                    Button("groups.member.kick", systemImage: "person.badge.minus") {
                                        pendingGesture = .kick(user)
                                    }
                                }
                                .tint(.foregroundDefault)
                            } label: {
                                Label("action.more", systemImage: "ellipsis")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.foregroundDefault)
                            }
                            .accessibilityIdentifier("e2e.group.member.menu")
                        }
                    }
                }
            } header: {
                header(title)
            }
        }
    }

    private func header(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .textStyle(.action200)
            .foregroundStyle(.foregroundSecondary)
    }
}
