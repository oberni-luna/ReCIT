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

    /// The illustration's share of the screen's width — the shelf card's own 86%, so the plank
    /// stands where the first étagère will.
    private let illustrationWidthShare: Int = 86

    var body: some View {
        VStack(spacing: .large) {
            Spacer()

            OnboardingPlankView()
                .containerRelativeFrame(
                    .horizontal,
                    count: 100,
                    span: illustrationWidthShare,
                    spacing: .zero
                )

            VStack(spacing: .medium) {
                Text("onboarding.welcome.title")
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)

                Text("onboarding.welcome.body")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            OnboardingWelcomeActions(onScan: onScan, onLater: onLater)
        }
        .padding(.horizontal, .medium)
        .padding(.bottom, .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
    }
}

#Preview {
    OnboardingWelcomeView(onScan: {}, onLater: {})
}
