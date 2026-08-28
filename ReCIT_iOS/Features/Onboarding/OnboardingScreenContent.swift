//
//  OnboardingScreenContent.swift
//  ReCIT_iOS
//
//  What an onboarding screen says, with the answers left out: the illustration, the title, and
//  the sentence under it, centred between two spacers.
//
//  A view of its own because `OnboardingScreenLayout` builds it twice — once standing on its own
//  and once inside a scroll view — and keeps whichever fits the phone it is running on. A second
//  copy of these paddings written out at the call site is how the same screen comes to sit a few
//  points from itself depending on the text size, which is the failure this whole arrangement is
//  meant to prevent.
//
//  The spacers carry no minimum length. They are what centres the block when there is room for
//  it, and inside the scroll view — which proposes no height at all, so they collapse — they must
//  come to nothing rather than push the illustration down by a spacing nobody asked for.
//
//  See PRD 0007, designs C1 and C2.
//

import SwiftUI

struct OnboardingScreenContent<Illustration: View>: View {
    private let title: Text
    private let message: Text
    private let illustration: Illustration

    /// The illustration's share of the screen's width — the shelf card's own 86%, so the plank
    /// stands where the first étagère will. Measured against the screen and not against the
    /// padded column, so it is the same 86% whether or not a scroll view is in the way.
    private let illustrationWidthShare: Int = 86

    init(
        title: Text,
        message: Text,
        illustration: Illustration
    ) {
        self.title = title
        self.message = message
        self.illustration = illustration
    }

    var body: some View {
        VStack(spacing: .large) {
            Spacer(minLength: .zero)

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

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingScreenContent(
        title: Text(verbatim: "Vos livres, sur vos étagères"),
        message: Text(verbatim: "Scannez les codes-barres à la chaîne."),
        illustration: OnboardingPlankView()
    )
}
