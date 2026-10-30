//
//  UserListsTab.swift
//  ReCIT_iOS
//
//  A reader's lists, under the Listes tab of their profile: the rows of my own Lists tab —
//  covers fanned out, name, what it is for, how many — and nothing that writes. No « + », no
//  swipe to delete, no search; a row opens the list, which knows on its own that it is not mine
//  (`EntityListDetail`). See PRD 0031.
//
//  The lists are whatever the store holds for that reader, refreshed by the screen as it opens;
//  the server alone decides which of them I may see.
//

import SwiftData
import SwiftUI

struct UserListsTab: View {
    /// Where the screen's fetch of the reader's lists stands — what tells an empty tab from one
    /// still waiting for its first answer.
    enum Load {
        case loading
        case loaded
        case failed
    }

    @Environment(UserModel.self) private var userModel

    let user: User
    let load: Load
    @Binding var path: NavigationPath

    @Query(sort: \EntityList.name) private var storedLists: [EntityList]

    private var lists: [EntityList] {
        if user._id == userModel.myUser?._id {
            storedLists.filter { $0.isCreated(byMe: user._id) }
        } else {
            storedLists.filter { $0.creatorId == user._id }
        }
    }

    var body: some View {
        if lists.isEmpty {
            Section {
                emptyState
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .large)
            }
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(lists) { list in
                    NavigationLink(value: NavigationDestination.entityList(id: list._id)) {
                        ListRowView(list: list)
                    }
                    .accessibilityIdentifier("e2e.user.listRow")
                }
            }
            .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch load {
        case .loading:
            ProgressView()
        case .loaded:
            EmptyStateView(
                glyph: "list.bullet",
                title: "user.lists.empty.title \(user.username)",
                message: "user.lists.empty.message"
            )
        case .failed:
            EmptyStateView(
                glyph: "list.bullet",
                title: "user.lists.failed \(user.username)"
            )
        }
    }
}
