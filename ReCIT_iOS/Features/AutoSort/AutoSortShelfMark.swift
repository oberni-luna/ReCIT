//
//  AutoSortShelfMark.swift
//  ReCIT_iOS
//
//  The mark against one proposed étagère in the review-turned-progress list: an empty
//  circle while it is only a proposal, a spinner while it is being written, a filled
//  tick once both its creation and its membership write have landed, and an error mark
//  if it failed.
//
//  Why a mark per étagère rather than a progress screen: the run can stop partway and
//  nothing is rolled back, so the user's real question afterwards is *which* étagères
//  exist. A list that already shows one row per proposed shelf answers that on its own
//  — a bar would have to be explained by a second screen. See PRD 0006.
//
//  A tick only ever means both stages landed; a created-but-empty étagère is a failure,
//  not a partial success, and is marked as one.
//

import SwiftUI

struct AutoSortShelfMark: View {
    let outcome: AutoSortApplyProgress.ShelfOutcome

    var body: some View {
        switch outcome {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.foregroundDisable)
                .accessibilityLabel("À créer")
        case .applying:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Création en cours")
        case .landed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.foregroundTinted)
                .accessibilityLabel("Créée")
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.foregroundError)
                .accessibilityLabel("Échec")
        }
    }
}
