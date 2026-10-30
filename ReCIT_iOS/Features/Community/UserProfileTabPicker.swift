//
//  UserProfileTabPicker.swift
//  ReCIT_iOS
//
//  Inventaire | Listes, at the foot of a reader's profile header: two words, the selected one
//  in a glass capsule — the tabs of the Contacts card, quieter than a segmented control. See
//  PRD 0031.
//
//  The capsule follows the pager rather than the selection: it slides under the finger as a page
//  is swiped, between the two words by as much of each page as is on screen, and glides to a word
//  chosen by its name as the pager turns to it — as Messages' does.
//

import SwiftUI

struct UserProfileTabPicker: View {
    @Binding var selection: UserProfileTab
    /// Where the pager stands: 0 on the first tab, 1 on the second, in between during a swipe.
    let pagePosition: CGFloat

    /// Each word's frame in the picker, which the capsule is drawn between.
    @State private var labelFrames: [UserProfileTab: CGRect] = [:]

    private static let coordinateSpace: String = "UserProfileTabPicker"

    private var clampedPosition: CGFloat {
        min(max(pagePosition, 0), CGFloat(UserProfileTab.allCases.count - 1))
    }

    /// The word the capsule is mostly under, drawn as the selected one.
    private var highlighted: UserProfileTab {
        UserProfileTab.allCases[Int(clampedPosition.rounded())]
    }

    /// Between the frames of the two words the pager stands between, by how far it has gone.
    private var capsuleFrame: CGRect? {
        let tabs: [UserProfileTab] = UserProfileTab.allCases
        let lower: Int = Int(clampedPosition.rounded(.down))
        let upper: Int = min(lower + 1, tabs.count - 1)
        guard let from = labelFrames[tabs[lower]], let to = labelFrames[tabs[upper]] else { return nil }

        let progress: CGFloat = clampedPosition - CGFloat(lower)
        return .init(
            x: from.minX + (to.minX - from.minX) * progress,
            y: from.minY,
            width: from.width + (to.width - from.width) * progress,
            height: from.height
        )
    }

    var body: some View {
        HStack(spacing: .xSmall) {
            ForEach(UserProfileTab.allCases, id: \.self) { tab in
                let isHighlighted: Bool = tab == highlighted
                Button {
                    // The pager turns to it, and the capsule with the pager.
                    selection = tab
                } label: {
                    Text(tab.title)
                        .textStyle(.action300)
                        .foregroundStyle(isHighlighted ? .foregroundDefault : .foregroundSecondary)
                        .padding(.horizontal, .medium)
                        .padding(.vertical, .small)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.coordinateSpace)) } action: { frame in
                    labelFrames[tab] = frame
                }
                .accessibilityAddTraits(tab == selection ? .isSelected : [])
            }
        }
        .background(alignment: .topLeading) {
            if let capsuleFrame {
                Color.clear
                    .glassCapsule()
                    .frame(width: capsuleFrame.width, height: capsuleFrame.height)
                    .offset(x: capsuleFrame.minX, y: capsuleFrame.minY)
            }
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("user.segment")
        .accessibilityIdentifier("e2e.user.tabs")
    }
}
