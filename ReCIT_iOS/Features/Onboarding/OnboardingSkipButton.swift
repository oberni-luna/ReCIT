//
//  OnboardingSkipButton.swift
//  ReCIT_iOS
//
//  The way out of an onboarding screen, in one place. Deliberately not a button style: it
//  carries the action text style and the tinted foreground and adds nothing to the design
//  system, because a fourth occurrence is the point at which it earns a real style with its
//  Figma counterpart — and not before.
//
//  A view rather than repeated modifier chains, for the reason `OnboardingActions` already
//  gives: copies of a button that is deliberately not a button style are how one of them
//  quietly stops matching. The bilan needs it under both of its endings — under the offer to
//  arrange the books, where it reads "Plus tard", and under the reason the arrangement cannot
//  run on this phone, where it reads "Continuer sans ranger" because there is nothing to
//  postpone. So the wording is the parameter, and nothing else is.
//
//  See PRD 0007, designs C1, C2 and C2b.
//

import SwiftUI

struct OnboardingSkipButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .textStyle(.action300)
            .foregroundStyle(.foregroundTinted)
            .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingSkipButton(title: "onboarding.later", action: {})
}
