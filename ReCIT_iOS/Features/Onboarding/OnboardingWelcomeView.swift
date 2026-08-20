//
//  OnboardingWelcomeView.swift
//  ReCIT_iOS
//
//  The accueil: what a new user meets instead of an empty bookshelf. A bare plank, what scanning
//  is actually like in one sentence, and one thing to do — with a way out that is not a dead end.
//
//  It says the camera stays open and the books pile up, because that is the part a user cannot
//  guess from the word "scanner": what they would otherwise expect is a single lookup, and the
//  slowest way into this app is one book at a time.
//
//  One action. Offering three doors on a first launch makes the user choose before they know what
//  any of them lead to, and the other two exist in the app anyway for whoever goes looking.
//
//  Nothing but copy is its own: the plank, the geometry and the pair of answers are
//  `OnboardingScreenLayout`'s, shared with the bilan at the other end of the sequence.
//
//  The screen makes no network call and has no state of its own: whichever button is pressed, the
//  accueil is answered and gone. Which of the two also opens the scanner is the cover's business,
//  not this view's — see `OnboardingWelcomeModifier`.
//
//  See PRD 0007, design C1.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onScan: () -> Void
    let onLater: () -> Void

    var body: some View {
        OnboardingScreenLayout(
            title: Text("onboarding.welcome.title"),
            message: Text("onboarding.welcome.body")
        ) {
            OnboardingPlankView()
        } actions: {
            OnboardingActions(
                primaryTitle: "onboarding.welcome.scan",
                onPrimary: onScan,
                onLater: onLater
            )
        }
    }
}

#Preview {
    OnboardingWelcomeView(onScan: {}, onLater: {})
}
