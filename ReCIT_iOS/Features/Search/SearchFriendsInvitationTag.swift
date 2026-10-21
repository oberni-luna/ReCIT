//
//  SearchFriendsInvitationTag.swift
//  ReCIT_iOS
//
//  What stands where « Chez mes amis » would, for a reader with no friend yet: a paper tag, on
//  the same paper as the empty shelf's and the empty Lists tab's, that takes them to the Réseau
//  tab — the one place a friend can be found. It changes tab rather than pushing a screen of
//  its own: finding readers already has a home, and a second way in would be a second screen
//  to keep in step.
//
//  See PRD 0020 and issue 0117.
//

import SwiftUI

struct SearchFriendsInvitationTag: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: .xSmall) {
                Label {
                    Text("inventory.search.friends_section.invite.title")
                        .textStyle(.content400Bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } icon: {
                    Image(systemName: "person.2")
                }

                Text("inventory.search.friends_section.invite.detail")
                    .textStyle(.footnote200)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(ShelfPalette.labelInk)
            .padding(.horizontal, .medium)
            .padding(.vertical, .sMedium)
            .shelfPaper(text: String(localized: "inventory.search.friends_section.invite.title"))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("inventory.search.friends_section.invite.detail"))
        .accessibilityIdentifier("e2e.searchFriends.invite")
    }
}
