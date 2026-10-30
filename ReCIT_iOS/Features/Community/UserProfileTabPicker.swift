//
//  UserProfileTabPicker.swift
//  ReCIT_iOS
//
//  Inventaire | Listes, at the foot of a reader's profile header: two words, the selected one
//  in a glass capsule that slides to the other when it is chosen — the tabs of the Contacts
//  card, quieter than a segmented control. See PRD 0031.
//

import SwiftUI

struct UserProfileTabPicker: View {
    @Binding var selection: UserProfileTab

    @Namespace private var capsule

    var body: some View {
        HStack(spacing: .xSmall) {
            ForEach(UserProfileTab.allCases, id: \.self) { tab in
                let isSelected: Bool = tab == selection
                Button {
                    withAnimation(.snappy) {
                        selection = tab
                    }
                } label: {
                    Text(tab.title)
                        .textStyle(.action300)
                        .foregroundStyle(isSelected ? .foregroundDefault : .foregroundSecondary)
                        .padding(.horizontal, .medium)
                        .padding(.vertical, .small)
                        .background {
                            if isSelected {
                                Color.clear
                                    .glassCapsule()
                                    .matchedGeometryEffect(id: "selection", in: capsule)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("user.segment")
        .accessibilityIdentifier("e2e.user.tabs")
    }
}
