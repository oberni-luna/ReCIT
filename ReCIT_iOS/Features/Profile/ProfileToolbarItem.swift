//
//  ProfileToolbarItem.swift
//  ReCIT_iOS
//
//  The way into the profile, at the top left of Inventaire, Listes and Réseau — the Profil tab's
//  replacement since feature 0038. A tap opens `ProfileSheet` through `TabRouter`.
//
//  Two faces. With no picture on the account, the tab's old icon in the bar's own round glass
//  button. With one, the picture in a circle: the bar's shared glass is put away so the picture
//  fills the circle instead of sitting inside a ring, and a glass circle of its own carries the
//  icon underneath, which is what shows while the picture loads, and if it never does.
//

import SwiftUI

struct ProfileToolbarItem: ToolbarContent {
    @Environment(UserModel.self) private var userModel
    @Environment(TabRouter.self) private var router

    private var avatarURL: URL? {
        guard let avatarURLValue = userModel.myUser?.avatarURLValue else { return nil }
        return URL(string: avatarURLValue)
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if let avatarURL {
                Button {
                    router.openProfile()
                } label: {
                    ProfileAvatar(url: avatarURL)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("nav.profile")
                .accessibilityIdentifier("e2e.profile.open")
            } else {
                Button("nav.profile", systemImage: "person") {
                    router.openProfile()
                }
                .accessibilityIdentifier("e2e.profile.open")
            }
        }
        .sharedBackgroundVisibility(avatarURL == nil ? .automatic : .hidden)
    }
}
