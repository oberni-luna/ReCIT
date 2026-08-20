//
//  OnboardingActions.swift
//  ReCIT_iOS
//
//  An onboarding screen's two answers, at the foot of it: the one that carries on, and the one
//  that hands the app back. Together in one view because the difference in weight between them
//  is a single decision — a second styled button beside the first would read as a choice between
//  two ways forward rather than as a way out.
//
//  "Plus tard" is therefore a bare button: findable, and not competing. It carries design-system
//  tokens and adds nothing to the design system — the action text style and the tinted
//  foreground. It appears three times across PRD 0007's screens; a fourth is the point at which
//  it should become a real button style with its Figma counterpart, not before. Which is also
//  why the two screens share this view rather than each drawing its own pair: three copies of a
//  button that is deliberately not a button style is how one of them quietly stops matching.
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

            Button("onboarding.later", action: onLater)
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
                .buttonStyle(.plain)
        }
    }
}

#Preview {
    OnboardingActions(primaryTitle: "onboarding.welcome.scan", onPrimary: {}, onLater: {})
        .padding(.horizontal, .medium)
}
