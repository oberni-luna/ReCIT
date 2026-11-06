//
//  UserProfileTabLabel.swift
//  ReCIT_iOS
//
//  A tab's word on a reader's profile, with how many it holds after a « • »: « Inventaire • 540 »,
//  « Listes • 4 », « Échanges • 2 », « Présentation ». The count used to be a line of its own under the name; in
//  the tab, it says what the page holds before the page is turned to. See the « Détail d'un
//  amis » section of the Figma file (`865:17783`).
//

import SwiftUI

struct UserProfileTabLabel: View {
    @Environment(UserModel.self) private var userModel

    let tab: UserProfileTab
    let user: User
    let listsLoad: UserListsTab.Load

    /// My own inventory is counted in the store once synced, so it moves with every add and
    /// delete; anyone else's reads the server's snapshot — the rule `UserItemCountText` follows.
    private var countsInventoryLocally: Bool {
        user._id == userModel.myUser?._id && user.lastInventorySync != nil
    }

    var body: some View {
        switch tab {
        case .inventory:
            if countsInventoryLocally {
                OwnedInventoryTabTitle(ownerId: user._id)
            } else {
                Self.inventoryTitle(count: user.itemCount)
            }
        case .lists:
            UserListsTabTitle(user: user, load: listsLoad)
        case .transactions:
            UserTransactionsTabTitle(user: user)
        case .presentation:
            Text(tab.title)
        }
    }

    /// « Inventaire • 540 », read « Inventaire, 540 éléments » rather than with its bullet.
    static func inventoryTitle(count: Int) -> some View {
        Text("user.tab.inventory \(count)")
            .accessibilityLabel(Text("user.tab.inventory.accessibility \(count)"))
    }
}
