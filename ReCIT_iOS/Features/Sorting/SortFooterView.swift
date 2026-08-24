//
//  SortFooterView.swift
//  ReCIT_iOS
//
//  The footer slot, rendered. Which reading it is showing is `SortFooter`'s decision; this
//  view only draws it, and draws each one with the type that already knows how — the recap
//  and the two reports carry their plural rules and their three-part account from PRD 0008.
//
//  **The voice belongs to the slot, not to the readings.** Centred, secondary, one text
//  style: set once here rather than four times in four types, so no reading can be the one
//  that looks out of place. Anything the readings declared for themselves was removed for
//  the same reason — an inner `foregroundStyle` wins, which is exactly what must not happen.
//  Per design `160:6659` / `185:7804`.
//
//  It has no fixed height on purpose. The panel is anchored to the bottom of the screen, so
//  a four-line stopped report grows *upwards* and the grid shrinks by that much — which is
//  what lets the account of a half-written library be read without a tap, on a screen whose
//  design allots it two lines. What keeps the panel steady between `idle` and `recap` is that
//  both readings are two lines of prose, not a height reserved for them.
//

import SwiftUI

struct SortFooterView: View {
    let footer: SortFooter

    var body: some View {
        Group {
            switch footer {
            case .idle:
                Text("manual_sort.footer.idle")

            case .recap(let plan):
                ManualSortRecapView(plan: plan)

            case .report(let progress):
                ManualSortApplyReport(progress: progress)

            case .notice(let notice):
                Text(notice.text)
            }
        }
        .textStyle(.content300)
        .multilineTextAlignment(.center)
        .foregroundStyle(.foregroundSecondary)
        .frame(maxWidth: .infinity)
    }
}

private extension SortNotice {

    var text: LocalizedStringKey {
        switch self {
        case .nothingToPropose: "manual_sort.proposal.nothing_to_propose"
        }
    }
}
