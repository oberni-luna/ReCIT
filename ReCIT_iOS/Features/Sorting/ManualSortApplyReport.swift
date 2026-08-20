//
//  ManualSortApplyReport.swift
//  ReCIT_iOS
//
//  What the run did, said in words at the foot of the list.
//
//  The marks up the list already show it étagère by étagère, but a run that stopped
//  partway is the one outcome a user has to be able to read without counting rows:
//  nothing is rolled back, so what landed is theirs now.
//
//  **Three parts, never two.** What landed and holds its books; where the run broke —
//  which may exist without its books, since a creation that succeeded is not undone by
//  the membership write that failed after it; and what was never touched. Folding the
//  second into "not saved" would be the tidier report and the dishonest one: the user
//  would go looking for an étagère already sitting in their carousel.
//
//  It also says what recovery is: the same button again. What landed has left the
//  stack, so the second press sends the remainder and repeats nothing.
//
//  **An empty run reads sensibly.** A rangement whose changes cancelled each other out
//  is a run with nothing to save, and gets a sentence saying so rather than
//  « 0 étagère enregistrée » — the shape recorded as divergence D41 against the
//  auto-sort report, and deliberately not repeated here. Every count is pluralised by
//  the string catalogue through substitutions, never by a ternary inside an
//  interpolation (D38).
//
//  The wording says « enregistrée » rather than the mockup's « créée et remplie »: on
//  this surface most of what a run writes to are étagères that already existed, and
//  telling a user they were created would be the same class of lie the third part
//  exists to avoid. See PRD 0008.
//

import SwiftUI

struct ManualSortApplyReport: View {

    let progress: SortApplyLedger

    var body: some View {
        switch progress.result {
        case .running:
            EmptyView()

        case .allLanded:
            if progress.landedCount == 0 {
                Text("manual_sort.report.nothing_to_save")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
            } else {
                Text("manual_sort.report.all_landed \(progress.landedCount)")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
            }

        case .stopped(let landed, let failed, let notAttempted):
            ManualSortApplyStoppedReport(
                landed: landed,
                failed: failed,
                notAttempted: notAttempted
            )
        }
    }
}
