//
//  UserProfileTabPicker.swift
//  ReCIT_iOS
//
//  Inventaire | Listes, pinned under the navigation bar once the header and the étagères have
//  scrolled away. It carries the screen's own ground, so the rows pass under it rather than
//  through it, and a hairline under it once it is pinned.
//

import SwiftUI

struct UserProfileTabPicker: View {
    @Binding var selection: UserProfileTab

    var body: some View {
        Picker("user.segment", selection: $selection) {
            ForEach(UserProfileTab.allCases, id: \.self) { tab in
                Text(tab.title)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, .medium)
        .padding(.vertical, .small)
        .background(DesignSystem.Color.backgroundForm.color)
        .accessibilityIdentifier("e2e.user.tabs")
    }
}
