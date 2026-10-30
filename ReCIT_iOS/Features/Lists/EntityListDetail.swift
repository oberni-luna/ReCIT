//
//  EntityListDetail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import SwiftData

struct EntityListDetail: View {
    let listId: String
    @Binding var path: NavigationPath

    @Environment(UserModel.self) private var userModel

    @Query private var matchingLists: [EntityList]
    @State private var presentEditForm: Bool = false

    init(listId: String, path: Binding<NavigationPath>) {
        self.listId = listId
        self._path = path
        _matchingLists = Query(filter: #Predicate<EntityList> { $0._id == listId })
    }

    private var list: EntityList? { matchingLists.first }

    /// Whether this screen may write to the list. Derived from the list's creator, like an
    /// étagère's owner in `ShelfDetailView`: a friend's list, opened from their profile, cannot
    /// lie about whose it is.
    private var isMine: Bool {
        list?.isCreated(byMe: userModel.myUser?._id) ?? false
    }

    /// Leaves when the list this screen is about stops existing.
    ///
    /// Deleting a list used to drop this screen into its own not-found branch, which draws
    /// `ContentUnavailableView("list.empty")` — so the same screen meant both "this list holds
    /// nothing" and "this list is gone", and the user was left looking at the remains of what
    /// they had just deleted until they pressed back.
    ///
    /// Keyed on the transition rather than on the current value, which is what tells a deletion
    /// apart from the list simply not having synced yet: a screen opened before the first sync
    /// starts empty and must wait, a screen whose list disappears under it must leave.
    private func popIfTheListIsGone(wasMissing: Bool, isMissing: Bool) {
        guard isMissing, !wasMissing, !path.isEmpty else { return }

        path.removeLast()
    }

    var body: some View {
        Group {
            if let list {
                switch list.type {
                case .work, .author:
                    ListCoverFlowScreen(list: list, path: $path)
                case .publisher:
                    List {
                        Text("list.empty")
                            .textStyle(.content300)
                    }
                    .applyListBackground(.backgroundGrouped)
                }
            } else {
                ContentUnavailableView(
                    "list.empty",
                    systemImage: "list.bullet.rectangle"
                )
                .applyListBackground(.backgroundGrouped)
            }
        }
        .navigationTitle(list?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isMine {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.edit", systemImage: "pencil") {
                        presentEditForm = true
                    }
                }
            }
        }
        .sheet(isPresented: $presentEditForm) {
            if let list {
                ListFormView(list: list)
            }
        }
        .onChange(of: matchingLists.isEmpty, popIfTheListIsGone)
    }
}
