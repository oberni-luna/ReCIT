//
//  UserListsTabTitle.swift
//  ReCIT_iOS
//

import SwiftData
import SwiftUI

/// « Listes • 4 »: the lists the Listes tab shows, counted the way it filters them. While the
/// first fetch runs with nothing stored, the word alone — « Listes • 0 » would be a guess.
struct UserListsTabTitle: View {
    @Environment(UserModel.self) private var userModel

    let user: User
    let load: UserListsTab.Load

    @Query private var storedLists: [EntityList]

    private var count: Int {
        if user._id == userModel.myUser?._id {
            storedLists.count(where: { $0.isCreated(byMe: user._id) })
        } else {
            storedLists.count(where: { $0.creatorId == user._id })
        }
    }

    var body: some View {
        if count == 0, load == .loading {
            Text(UserProfileTab.lists.title)
        } else {
            Text("user.tab.lists \(count)")
                .accessibilityLabel(Text("user.tab.lists.accessibility \(count)"))
        }
    }
}
