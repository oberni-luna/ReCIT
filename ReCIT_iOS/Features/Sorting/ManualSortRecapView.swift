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
//  sentence of its own that explains itself.
//
//  There used to be a third line, naming the drafts left empty so they could be dropped
//  without vanishing silently. Empty drafts are created now, so there is nothing to warn
//  about — see `SortWritePlan`.
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

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
