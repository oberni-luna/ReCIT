//
//  ManualSortShelfMark.swift
//  ReCIT_iOS
//
//  The mark against one étagère while the rangement is being written: an empty circle
//  for one whose turn has not come, a spinner while it is being written, a tick once
//  everything it was owed has landed, and an error mark where the run broke.
//
//  **A tick means all of it landed** — the creation, the removals and the additions.
//  An étagère created without its books is a failure, not a half-success, which is the
//  whole reason the writes wait (PRD 0008).
//
//  An étagère the run has nothing to do to carries **no mark at all**: the caller
//  passes `nil` and this view is not drawn. A pending mark on a shelf nobody is going
//  to touch would read as a queue that never advances.
//
//  Its own view rather than `AutoSortShelfMark`'s: the vocabulary is shared — it is
//  the same ledger — but that one is worded for a screen that only ever *creates*
//  étagères ("À créer", "Créée"), and here most of them already exist and are merely
//  being refilled. It also lives in the flow slice 0043 dismantles. The glyphs follow
//  the design's `Mark glyph` property: outline marks, tinted / error / disabled, as
//  the token table in docs/design-system/figma-library.md maps them.
//

import SwiftUI

struct ManualSortShelfMark: View {

    let outcome: AutoSortApplyProgress.ShelfOutcome

    var body: some View {
        switch outcome {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.foregroundDisable)
                .accessibilityLabel("manual_sort.mark.pending")
        case .applying:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("manual_sort.mark.applying")
        case .landed:
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.foregroundTinted)
                .accessibilityLabel("manual_sort.mark.landed")
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.foregroundError)
                .accessibilityLabel("manual_sort.mark.failed")
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .medium) {
        ManualSortShelfMark(outcome: .pending)
        ManualSortShelfMark(outcome: .applying)
        ManualSortShelfMark(outcome: .landed)
        ManualSortShelfMark(outcome: .failed)
    }
    .padding(.all, .medium)
}
