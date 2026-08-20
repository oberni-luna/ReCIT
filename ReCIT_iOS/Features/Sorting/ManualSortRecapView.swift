//
//  ManualSortRecapView.swift
//  ReCIT_iOS
//
//  The pending work said once, in words, just above the buttons: how many étagères
//  would be created, how many changed, how many books filed, and how many would still
//  be on no étagère.
//
//  It says the same thing as the pills up the list because it is built from the same
//  reduction — `SortWritePlan` — and not from a second count of its own. The last of
//  the four numbers is the one the pills cannot show: what the session did *not*
//  solve.
//
//  **Three states, not two.** Nothing done at all is silence — the caller does not
//  render this view. Work that cancels itself out (a book taken off an étagère and put
//  back) has to be said out loud: the buttons still offer to save and to discard,
//  because the stack is not empty, and a recap reading « 0 étagère à créer, 0 étagère
//  modifiée » next to a live save button reads as a broken screen. So that case gets a
//  sentence of its own that explains itself. A draft left empty gets named rather than
//  silently dropped, for the same reason: the user typed that name.
//
//  Every count is pluralised by the string catalogue, through substitutions — never by
//  a ternary inside an interpolation, which is divergence D38 and cannot enter the
//  catalogue at all. See PRD 0008.
//

import SwiftUI

struct ManualSortRecapView: View {

    let plan: SortWritePlan

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            if plan.hasWork {
                Text(
                    "manual_sort.recap \(plan.summary.shelvesToCreate) \(plan.summary.shelvesModified) \(plan.summary.booksFiled) \(plan.summary.booksLeftUnshelved)"
                )
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
            } else {
                Text("manual_sort.recap.nothing_to_save")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
            }

            if plan.summary.droppedDrafts.isEmpty == false {
                // Locale-aware joining rather than `", "`: « A, B et C » in French,
                // "A, B, and C" in English, and neither written in Swift.
                Text(
                    "manual_sort.recap.dropped \(plan.summary.droppedDrafts.count) \(plan.summary.droppedDrafts.formatted(.list(type: .and)))"
                )
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
