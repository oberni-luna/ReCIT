//
//  OnboardingActions.swift
//  ReCIT_iOS
//
//  An onboarding screen's two answers, at the foot of it: the one that carries on, and the one
//  that hands the app back. Together in one view because the difference in weight between them
//  is a single decision — a second styled button beside the first would read as a choice between
//  two ways forward rather than as a way out.
//
//  "Plus tard" is therefore a bare button: findable, and not competing. It lives in
//  `OnboardingSkipButton`, which is where its tokens are — the same reasoning, now that the
//  bilan needs that button under a second ending of its own, where it reads "Continuer sans
//  ranger" and there is no offer above it to pair with.
//
//  Only the leading answer's wording differs between the screens — "Scanner mes livres" on the
//  accueil, "Ranger mes livres" on the bilan — so only that is a parameter.
//
//  See PRD 0007, designs C1 and C2.
//

import SwiftUI

struct OnboardingActions: View {
    let primaryTitle: LocalizedStringKey
    let onPrimary: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: .medium) {
            Button(action: onPrimary) {
                Text(primaryTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())

            OnboardingSkipButton(title: "onboarding.later", action: onLater)
        }
    }
}

#Preview {
    OnboardingActions(primaryTitle: "onboarding.welcome.scan", onPrimary: {}, onLater: {})
        .padding(.horizontal, .medium)
}
