//
//  OnboardingScreenLayout.swift
//  ReCIT_iOS
//
//  The skeleton both onboarding screens stand on: an illustration held off the top and the
//  bottom of the screen, a title and a sentence under it, and the answers at the foot.
//
//  It exists because the two screens are the same screen twice over — the design captures the
//  bilan as "même squelette que C1, même géométrie de bouton" — and a second copy of these
//  paddings is how the accueil and the bilan come to sit a few points apart on the same phone
//  for no reason anyone can name.
//
//  The illustration and the answers are slots rather than parameters. Both are already known to
//  change: the bilan's plank gains the user's own covers, and a phone that cannot arrange books
//  shows a reason where the call to action would be. Neither of those is a variation of a shared
//  shape, so neither is described here.
//
//  Title and message arrive as `Text` rather than as keys: the bilan's title carries a count
//  into a catalogue plural rule, which a plain key cannot express.
//
//  See PRD 0007, designs C1 and C2.
//

import SwiftUI

struct OnboardingScreenLayout<Illustration: View, Actions: View>: View {
    private let title: Text
    private let message: Text
    private let illustration: Illustration
    private let actions: Actions

    /// The illustration's share of the screen's width — the shelf card's own 86%, so the plank
    /// stands where the first étagère will.
    private let illustrationWidthShare: Int = 86

    init(
        title: Text,
        message: Text,
        @ViewBuilder illustration: () -> Illustration,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.illustration = illustration()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: .large) {
            Spacer()

            illustration
                .containerRelativeFrame(
                    .horizontal,
                    count: 100,
                    span: illustrationWidthShare,
                    spacing: .zero
                )

            VStack(spacing: .medium) {
                title
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)

                message
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            actions
        }
        .padding(.horizontal, .medium)
        .padding(.bottom, .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
    }
}

#Preview {
    OnboardingScreenLayout(
        title: Text(verbatim: "Vos livres, sur vos étagères"),
        message: Text(verbatim: "Scannez les codes-barres à la chaîne.")
    ) {
        OnboardingPlankView()
    } actions: {
        OnboardingActions(primaryTitle: "onboarding.welcome.scan", onPrimary: {}, onLater: {})
    }
}
