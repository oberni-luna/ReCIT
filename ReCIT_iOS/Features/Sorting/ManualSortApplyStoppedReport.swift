//
//  ManualSortApplyStoppedReport.swift
//  ReCIT_iOS
//
//  The three parts of a rangement that stopped partway, and how to finish it. Split out
//  of `ManualSortApplyReport` only because it is a type of its own; the reasoning for
//  the three parts is there.
//
//  Colour and alignment come from `SortFooterView`, for the whole slot. This report used to
//  set its own — its first line in `foreground/default` over three details in
//  `foreground/secondary`, so the headline of a failure carried more weight than its
//  breakdown. That hierarchy is gone; what is left to tell the resume line apart from the
//  rest is its smaller text style. Worth restoring here if a stopped run ever reads too flat.
//

import SwiftUI

/// The three parts of a run that stopped, plus how to finish it.
///
/// Names are joined by `ListFormat` rather than by `", "`: « A, B et C » in French,
/// "A, B, and C" in English, and neither of them written in Swift.
struct ManualSortApplyStoppedReport: View {

    let landed: [String]
    let failed: [String]
    let notAttempted: [String]

    var body: some View {
        VStack(spacing: .sMedium) {
            Text("manual_sort.report.stopped")

            if landed.isEmpty {
                Text("manual_sort.report.stopped.none_landed")
            } else {
                Text("manual_sort.report.stopped.landed \(landed.count) \(landed.formatted(.list(type: .and)))")
            }

            // Said apart from "never touched" on purpose: nothing is rolled back, so
            // the étagère the run broke on may be sitting in the carousel without its
            // books. A user told it was not saved would go looking for it and find it.
            if failed.isEmpty == false {
                Text("manual_sort.report.stopped.failed \(failed.count) \(failed.formatted(.list(type: .and)))")
            }

            if notAttempted.isEmpty == false {
                Text("manual_sort.report.stopped.not_attempted \(notAttempted.count) \(notAttempted.formatted(.list(type: .and)))")
            }

            Text("manual_sort.report.stopped.resume")
                .textStyle(.footnote200)
        }
        .frame(maxWidth: .infinity)
    }
}
