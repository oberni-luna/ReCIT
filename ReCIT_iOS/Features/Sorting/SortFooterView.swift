//
//  SortFooterView.swift
//  ReCIT_iOS
//
//  The footer slot, rendered. Which reading it is showing is `SortFooter`'s decision; this
//  view only draws it, and draws each one with the type that already knows how — the recap
//  and the two reports are unchanged from PRD 0008, plural rules and three-part account
//  included.
//
//  It has no fixed height on purpose. The panel is anchored to the bottom of the screen, so
//  a four-line stopped report grows *upwards* and the grid shrinks by that much — which is
//  what lets the account of a half-written library be read without a tap, on a screen whose
//  design allots it two lines.
//

import SwiftUI

struct SortFooterView: View {
    let footer: SortFooter

    var body: some View {
        switch footer {
        case .silent:
            EmptyView()

        case .recap(let plan):
            ManualSortRecapView(plan: plan)

        case .report(let progress):
            ManualSortApplyReport(progress: progress)

        case .notice(let notice):
            Text(notice.text)
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension SortNotice {

    var text: LocalizedStringKey {
        switch self {
        case .nothingToPropose: "manual_sort.proposal.nothing_to_propose"
        }
    }
}
