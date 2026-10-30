//
//  UserProfileTabPicker.swift
//  ReCIT_iOS
//
//  Inventaire | Listes, pinned under the navigation bar once the header and the étagères have
//  scrolled away. No band of its own: a grey strip the width of the screen read as a bar
//  stuck under the bar, so the control floats over the rows that pass beneath it.
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
        .accessibilityIdentifier("e2e.user.tabs")
    }
}
