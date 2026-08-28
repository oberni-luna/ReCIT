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
//  On a phone that cannot run the arrangement, the *automatic* offer is replaced by the reason —
//  never a control that cannot work. Filing by hand is still offered underneath it, because
//  losing the model is not losing the ability to sort, and a freshly scanned library with
//  nowhere to go was the complaint that changed this screen (issue 0062). The count and its
//  title are untouched either way: the scan happened, and what the phone cannot do afterwards
//  does not unfile a book. Only the sentence under the title shortens, because its second half
//  offers to arrange the books and would be contradicted three lines lower. The reason itself,
//  and whether a route to Settings belongs beside it, are `AutoSortUnavailableView`'s to say —
//  see `OnboardingTallyUnavailableActions`.
//
//  The screen decides nothing. Whether it is owed is `OnboardingGate`'s answer and the scanning
//  session's to ask; which shape its ending takes is the session's too, read fresh from
//  auto-sort's availability and handed in; and where each answer leads is the session's, since
//  it owns the navigation stack this pushes into. See `BatchScanView`.
//
//  See PRD 0007, designs C2 and C2b.
//

import SwiftUI

struct OnboardingScanTallyView: View {
    let addedBookCount: Int
    /// The shape auto-sort's availability gives this screen's ending, derived by the session
    /// that presents it so that it is read fresh on every render.
    let entryPoint: AutoSortEntryPoint
    let onSort: () -> Void
    let onLater: () -> Void

    var body: some View {
        OnboardingScreenLayout(
            title: Text("onboarding.tally.title \(addedBookCount)"),
            message: Text(message)
        ) {
            OnboardingScanTallyIllustrationView()
        } actions: {
            if entryPoint.isEnabled {
                // « Rangement automatique » where the model can answer: the CTA names what
                // happens next, which is a wait and then a proposal — not the filing itself.
                OnboardingActions(
                    primaryTitle: "onboarding.tally.auto_sort",
                    onPrimary: onSort,
                    onLater: onLater
                )
            } else {
                OnboardingTallyUnavailableActions(
                    entryPoint: entryPoint,
                    onSort: onSort,
                    onContinue: onLater
                )
            }
        }
    }

    /// The full sentence offers to arrange the books; where that cannot happen it stops after
    /// stating where the books stand, and the reason takes over from there.
    private var message: LocalizedStringKey {
        entryPoint.isEnabled ? "onboarding.tally.body" : "onboarding.tally.body.unavailable"
    }
}

#Preview("Many books") {
    OnboardingScanTallyView(addedBookCount: 24, entryPoint: .offered, onSort: {}, onLater: {})
}

#Preview("One book") {
    OnboardingScanTallyView(addedBookCount: 1, entryPoint: .offered, onSort: {}, onLater: {})
}

#Preview("Apple Intelligence off") {
    OnboardingScanTallyView(addedBookCount: 24, entryPoint: .switchedOff, onSort: {}, onLater: {})
}

#Preview("Model downloading") {
    OnboardingScanTallyView(addedBookCount: 24, entryPoint: .downloading, onSort: {}, onLater: {})
}

#Preview("Device ineligible") {
    OnboardingScanTallyView(addedBookCount: 24, entryPoint: .hidden, onSort: {}, onLater: {})
}
