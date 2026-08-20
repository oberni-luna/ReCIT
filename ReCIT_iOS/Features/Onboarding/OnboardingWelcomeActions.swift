//
//  OnboardingWelcomeActions.swift
//  ReCIT_iOS
//
//  The accueil's two answers, at the foot of the screen: the one that starts a scanning session,
//  and the one that hands the app back. Together in one view because the difference in weight
//  between them is a single decision — a second styled button beside the first would read as a
//  choice between two ways in rather than as a way out.
//
//  "Plus tard" is therefore a bare button: findable, and not competing. It carries design-system
//  tokens and adds nothing to the design system — the action text style and the tinted foreground.
//  It appears three times across PRD 0007's screens; a fourth is the point at which it should
//  become a real button style with its Figma counterpart, not before.
//
//  See PRD 0007, design C1.
//

import SwiftUI

struct OnboardingWelcomeActions: View {
    let onScan: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: .medium) {
            Button(action: onScan) {
                Text("onboarding.welcome.scan")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())

            Button("onboarding.welcome.later", action: onLater)
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
                .buttonStyle(.plain)
        }
    }
}

#Preview {
    OnboardingWelcomeActions(onScan: {}, onLater: {})
        .padding(.horizontal, .medium)
}
