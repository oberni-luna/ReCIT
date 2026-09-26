//
//  ListsEmptyStateView.swift
//  ReCIT_iOS
//
//  What the Lists tab shows before the user has a single list: the step written on the
//  screen, then two paper tags — one saying what a list is for, next to an étagère, and one
//  that creates the first list. Same paper as the empty shelf (feature 0021), so the two
//  empty screens speak the same language; no plank under it, since a list is not a piece
//  of furniture. Straight from the Figma frame `A · Une étiquette qui explique`
//  (`462:12186`). See docs/features/0022.
//
//  Only the explanation matters here, and it matters only once: the tab used to be a grey
//  screen with no sentence and no way out but the « + » in the bar (D54).
//

import SwiftUI

struct ListsEmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: .xLarge) {
            VStack(spacing: .xSmall) {
                Text("lists.empty.heading")
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)
                    .accessibilityAddTraits(.isHeader)
                Text("lists.empty.body")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .multilineTextAlignment(.center)

            ListsExplanationTag()

            ListsCreateTag(onTap: onCreate)
        }
        .padding(.horizontal, .xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("e2e.lists.empty")
    }
}
