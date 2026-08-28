//
//  OnboardingTallyUnavailableActions.swift
//  ReCIT_iOS
//
//  What the foot of the bilan holds on a phone that cannot arrange books: the reason, then the
//  way to file the books by hand, then the way out. The *automatic* offer is not shown greyed
//  out beside it — a button that cannot work is a worse answer than a sentence saying why.
//
//  The reason stopped being the end of the screen at issue 0062. A phone that cannot run the
//  model loses the proposal, not the ability to sort, and leaving a freshly scanned library
//  with nowhere to go was the whole complaint: « Ranger mes livres » opens the same surface,
//  with everything in « À ranger » and nothing proposed on it.
//
//  It words nothing itself. `AutoSortUnavailableView` is the one place auto-sort's three
//  reasons are put into words, and it decides on its own whether a route to Settings belongs
//  beside them, so the bilan gets the three treatments for free: Apple Intelligence switched
//  off is stated with a route to Settings, a downloading model is stated as temporary with no
//  route, and an ineligible device is stated with no control at all. Restating any of that here
//  is how the same reason comes to be described one way in the flow and another way in the
//  bilan.
//
//  Which is also why no case was added to `AutoSortEntryPoint` for this screen. Its cases are
//  shapes derived from availability, not a list of the places that read them; a "scan tally"
//  case would have been a category error, and the wording would have had to be written twice.
//
//  The escape hatch reads "Continuer sans ranger" rather than the accueil's "Plus tard": there
//  is no arranging to defer here, so an invitation to come back to it later would be a promise
//  the phone cannot keep.
//
//  See PRD 0007, design C2b, and features/0008 for why the three reasons differ.
//

import SwiftUI

struct OnboardingTallyUnavailableActions: View {
    let entryPoint: AutoSortEntryPoint
    let onSort: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: .medium) {
            AutoSortUnavailableView(entryPoint: entryPoint)

            Button("onboarding.tally.sort", action: onSort)
                .buttonStyle(.primary())

            OnboardingSkipButton(
                title: "onboarding.tally.continue_without_sorting",
                action: onContinue
            )
        }
    }
}

#Preview("Apple Intelligence off") {
    OnboardingTallyUnavailableActions(entryPoint: .switchedOff, onSort: {}, onContinue: {})
        .padding(.horizontal, .medium)
}

#Preview("Model downloading") {
    OnboardingTallyUnavailableActions(entryPoint: .downloading, onSort: {}, onContinue: {})
        .padding(.horizontal, .medium)
}

#Preview("Device ineligible") {
    OnboardingTallyUnavailableActions(entryPoint: .hidden, onSort: {}, onContinue: {})
        .padding(.horizontal, .medium)
}
