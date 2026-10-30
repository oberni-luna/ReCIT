//
//  UserPresentationTab.swift
//  ReCIT_iOS
//
//  A reader's bio, under the Présentation tab of their profile — « Bio » in English. It used to
//  open the page above the étagères, centred, whatever the tab; it is now a page of its own, the
//  text in one card, left-aligned like any paragraph. See the « Détail d'un amis » section of the
//  Figma file (`865:17783`, F6).
//

import SwiftUI

struct UserPresentationTab: View {
    let user: User

    var body: some View {
        if let bio = user.bio, bio.isEmpty == false {
            Section {
                Text(bio)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        } else {
            Section {
                EmptyStateView(
                    glyph: "text.quote",
                    title: "user.presentation.empty \(user.username)"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, .large)
            }
            .listRowBackground(Color.clear)
        }
    }
}
