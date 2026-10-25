//
//  GroupsSegmentView.swift
//  ReCIT_iOS
//
//  Réseau › Groupes — frames `A2` and `A3` of the `Réseau · Onglet & Groupes` pass: the
//  invitations waiting on me first, since nothing else will tell me about them, then my groups,
//  then the requests I sent that nobody has answered, and the ways to find or start one.
//
//  Sections only, like `FriendsSegmentView`, so it slots under the segmented control. The groups
//  are read from the store through `@Query` (ADR 0001), so they are there from the moment the
//  app opens, offline too, and answering an invitation moves the group from one section to the
//  other on the spot. `MyGroups` does the sorting; `GroupModel` knows who I am.
//

import SwiftUI
import SwiftData

struct GroupsSegmentView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(SyncStatusStore.self) private var syncStatus
    @Query private var allUsers: [User]
    @Query private var storedGroups: [StoredGroup]

    @Binding var path: NavigationPath
    /// Opens the creation form, which `NetworkView` presents: the « + » of its bar opens it too.
    let onCreate: () -> Void

    var body: some View {
        let groups: MyGroups = groupModel.myGroups(from: storedGroups)

        // An empty store says nothing before the groups have synced once: placeholder, or the
        // failure of that first sync. Once they have, it means « in no group », offline too.
        if groups.isEmpty && syncStatus.hasCompletedFirstSync(.groups) == false {
            Section {
                if syncStatus.phase(.groups) == .failed {
                    Text("groups.load_failed")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                } else {
                    SyncingInlineRow()
                }
            }
        } else if groups.isEmpty {
            Section {
                EmptyStateView(
                    glyph: "person.2",
                    title: "groups.empty.title",
                    message: "groups.empty.message",
                    action: .init(title: "groups.find") {
                        path.append(NavigationDestination.findGroups)
                    }
                )
                .padding(.vertical, .large)

                Button("groups.create", action: onCreate)
                    .buttonStyle(.secondary())
                    .accessibilityIdentifier("e2e.groups.create.empty")
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            if groups.invitations.isEmpty == false {
                Section {
                    ForEach(groups.invitations) { group in
                        GroupInvitationRowView(
                            group: group,
                            invitorName: invitorName(in: group)
                        ) {
                            path.append(NavigationDestination.group(id: group.id))
                        }
                    }
                } header: {
                    header("groups.invitations")
                }
            }

            if groups.mine.isEmpty == false {
                Section {
                    ForEach(groups.mine) { group in
                        NavigationLink(value: NavigationDestination.group(id: group.id)) {
                            GroupRowView(
                                cell: .init(
                                    group: group,
                                    pendingCount: group.requestsToReview(by: groupModel.myUserId)
                                ),
                                role: group.role(of: groupModel.myUserId)
                            )
                        }
                    }
                } header: {
                    header("groups.mine")
                }
            }

            if groups.sentRequests.isEmpty == false {
                Section {
                    ForEach(groups.sentRequests) { group in
                        NavigationLink(value: NavigationDestination.group(id: group.id)) {
                            GroupRowView(cell: .init(group: group), role: .requested)
                        }
                    }
                } header: {
                    header("groups.requests.sent")
                }
            }

            Section {
                NavigationLink(value: NavigationDestination.findGroups) {
                    link("groups.find")
                }
                .accessibilityIdentifier("e2e.groups.find")

                Button(action: onCreate) {
                    link("groups.create")
                }
                .accessibilityIdentifier("e2e.groups.create")
            }
        }
    }

    private func invitorName(in group: ReaderGroup) -> String? {
        guard let myUserId = groupModel.myUserId,
              let invitorId = group.invitor(of: myUserId) else { return nil }
        return allUsers.first { $0._id == invitorId }?.username
    }

    private func header(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .textStyle(.action200)
            .foregroundStyle(.foregroundSecondary)
    }

    private func link(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .textStyle(.action300)
            .foregroundStyle(.foregroundTinted)
    }
}
