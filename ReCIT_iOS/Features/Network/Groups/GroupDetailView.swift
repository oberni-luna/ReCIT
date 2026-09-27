//
//  GroupDetailView.swift
//  ReCIT_iOS
//
//  One group, as I stand in it — frames `A5` (not a member), `A6` (member) and `A8` (admin).
//
//  The screen reads the group afresh each time it opens (`GET /api/groups/by-id`), whether it
//  came from my list or from a search: a group seen from the search is not in memory yet, and
//  one of mine may have moved since the launch. What the gestures change is shown at once, from
//  `GroupModel`, which is observable.
//

import SwiftUI
import SwiftData

struct GroupDetailView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \User.username) private var allUsers: [User]

    let groupId: String
    @Binding var path: NavigationPath

    @State private var loadFailed: Bool = false
    @State private var isConfirmingLeave: Bool = false
    @State private var isEditingSettings: Bool = false

    /// How many members the screen shows before « Voir les N membres ».
    private static let membersPreviewCount: Int = 5

    private var group: ReaderGroup? {
        groupModel.group(id: groupId)
    }

    private var myRole: GroupRole? {
        group?.role(of: groupModel.myUserId)
    }

    private var usersByID: [String: User] {
        .init(allUsers.map { ($0._id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        List {
            if let group {
                content(for: group)
            } else if loadFailed {
                Section {
                    EmptyStateView(
                        glyph: "exclamationmark.circle",
                        title: "groups.detail.load_failed",
                        message: "groups.detail.load_failed.message"
                    )
                    .padding(.vertical, .large)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
        .applyListBackground()
        .navigationTitle(group?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            do {
                try await groupModel.fetchGroup(id: groupId, modelContext: modelContext)
                loadFailed = false
            } catch {
                loadFailed = true
            }
        }
        .sheet(isPresented: $isEditingSettings) {
            if let group {
                GroupSettingsView(group: group)
            }
        }
        .confirmationDialog(
            "groups.leave.confirm \(group?.name ?? "")",
            isPresented: $isConfirmingLeave,
            titleVisibility: .visible
        ) {
            Button("groups.leave", role: .destructive) {
                groupModel.perform(.leave, on: groupId, modelContext: modelContext)
            }
            Button("action.cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func content(for group: ReaderGroup) -> some View {
        Section {
            GroupHeaderView(group: group)
        }

        Section {
            GroupActionsView(group: group, myRole: myRole, invitorName: invitorName(in: group))
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)

        // First for an admin, since these wait on them and nothing else will say so.
        if myRole == .admin && group.requested.isEmpty == false {
            Section {
                ForEach(group.requested.compactMap { usersByID[$0.user] }) { user in
                    GroupRequestRowView(user: user, groupId: group.id) {
                        path.append(NavigationDestination.user(user: user))
                    }
                }
            } header: {
                Text("groups.requests.to_review")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }

        membersSection(for: group)
    }

    @ViewBuilder
    private func membersSection(for group: ReaderGroup) -> some View {
        let members: [(user: User, role: GroupRole)] = group.memberIds.compactMap { id in
            guard let user = usersByID[id], let role = group.role(of: id) else { return nil }
            return (user, role)
        }
        Section {
            ForEach(members.prefix(Self.membersPreviewCount), id: \.user._id) { member in
                NavigationLink(value: NavigationDestination.user(user: member.user)) {
                    GroupMemberRowView(user: member.user, role: member.role)
                }
            }

            NavigationLink(value: NavigationDestination.groupMembers(id: group.id)) {
                link("groups.members.see_all \(group.memberCount)")
            }
            .accessibilityIdentifier("e2e.group.members")

            // Any member may invite, not only the admins.
            if myRole?.belongs == true {
                NavigationLink(value: NavigationDestination.inviteToGroup(id: group.id)) {
                    link("groups.invite")
                }
                .accessibilityIdentifier("e2e.group.inviteFriends")
            }
        } header: {
            Text("groups.members")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
    }

    private func link(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .textStyle(.action300)
            .foregroundStyle(.foregroundTinted)
    }

    private func invitorName(in group: ReaderGroup) -> String? {
        guard let myUserId = groupModel.myUserId,
              let invitorId = group.invitor(of: myUserId) else { return nil }
        return usersByID[invitorId]?.username
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if myRole?.belongs == true {
                Menu {
                    Group {
                        if myRole == .admin {
                            Button("groups.settings", systemImage: "slider.horizontal.3") {
                                isEditingSettings = true
                            }
                            .accessibilityIdentifier("e2e.group.settings")
                        }

                        Button("groups.invite", systemImage: "person.badge.plus") {
                            path.append(NavigationDestination.inviteToGroup(id: groupId))
                        }

                        Button("groups.leave", systemImage: "rectangle.portrait.and.arrow.right") {
                            isConfirmingLeave = true
                        }
                        .disabled(group.map { $0.canLeave(groupModel.myUserId ?? "") } == false)
                        .accessibilityIdentifier("e2e.group.leave")
                    }
                    .tint(.foregroundDefault)
                } label: {
                    Label("action.more", systemImage: "ellipsis")
                }
                .accessibilityIdentifier("e2e.group.menu")
            }
        }
    }
}
