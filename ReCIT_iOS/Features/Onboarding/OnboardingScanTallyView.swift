//
//  OnboardingScanTallyView.swift
//  ReCIT_iOS
//
//  The bilan: what a scanning session says for itself before it lets go. How many books it
//  filed, that they are on no étagère, and the offer to have them arranged — at the one moment
//  the user is holding the evidence that they need it.
//
//  It says the arrangement happens on the phone, because "let the app sort my library" is
//  otherwise indistinguishable from "upload my library", and that is a sentence a user is
//  entitled to before they agree rather than after.
//
//  The count is a parameter rather than a query: three books added among three hundred are
//  invisible in any snapshot of the store, so the number has to be carried out of the session
//  that produced it. The title pluralises in the string catalogue, from the count interpolated
//  into its key — never with a ternary in Swift, which is what the auto-sort screens do and what
//  makes them read as machine-generated for one book.
//
//  The plank is not bare here as it is on the accueil: it carries the user's own covers, settling
//  onto it one at a time. That is the payoff of the whole sequence, and it is the illustration's
//  own business — see `OnboardingScanTallyIllustrationView`.
//
//  The screen decides nothing. Whether it is owed is `OnboardingGate`'s answer and the scanning
//  session's to ask; where each answer leads is the session's too, since it owns the navigation
//  stack this pushes into. See `BatchScanView`.
//
//  See PRD 0007, design C2.
//

import SwiftUI

struct OnboardingScanTallyView: View {
    let addedBookCount: Int
    let onSort: () -> Void
    let onLater: () -> Void

    var body: some View {
        OnboardingScreenLayout(
            title: Text("onboarding.tally.title \(addedBookCount)"),
            message: Text("onboarding.tally.body")
        ) {
            OnboardingScanTallyIllustrationView()
        } actions: {
            OnboardingActions(
                primaryTitle: "onboarding.tally.sort",
                onPrimary: onSort,
                onLater: onLater
            )
        }
    }
}

#Preview("Many books") {
    OnboardingScanTallyView(addedBookCount: 24, onSort: {}, onLater: {})
}

#Preview("One book") {
    OnboardingScanTallyView(addedBookCount: 1, onSort: {}, onLater: {})
}
