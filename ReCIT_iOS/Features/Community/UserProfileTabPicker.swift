//
//  UserProfileTabPicker.swift
//  ReCIT_iOS
//
//  Inventaire • 540 | Listes • 4 | Échanges • 2 | Présentation, at the foot of a reader's profile
//  header: a `LensTabPicker`, its capsule following the pager and picked up to slide across the
//  words. The labels are in `action200`, the capsules side by side with 8 pt of padding each, so
//  that four of them, counts included, fit a phone's width; at the largest text sizes the row
//  scrolls instead. See PRD 0031 and `UserProfileTabLabel`.
//

import SwiftUI

struct UserProfileTabPicker: View {
    @Binding var selection: UserProfileTab
    /// The profile's pages, in their order.
    let tabs: [UserProfileTab]
    /// Where the pager stands: 0 on the first tab, 1 on the second, 2 on the third, in between
    /// during a swipe.
    let pagePosition: CGFloat
    /// Whose counts the labels give.
    let user: User
    let listsLoad: UserListsTab.Load

    var body: some View {
        LensTabPicker(selection: $selection, tabs: tabs, pagePosition: pagePosition) { tab in
            UserProfileTabLabel(tab: tab, user: user, listsLoad: listsLoad)
        }
        .wordPadding(.small)
        .accessibilityLabel("user.segment")
        .accessibilityIdentifier("e2e.user.tabs")
    }
}
