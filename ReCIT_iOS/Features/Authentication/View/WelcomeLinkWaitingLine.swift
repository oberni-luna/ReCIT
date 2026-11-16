//
//  WelcomeLinkWaitingLine.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// The line under the welcome screen's buttons while an Ex-libris link opened signed out waits
/// for the session (issue 143).
struct WelcomeLinkWaitingLine: View {
    var body: some View {
        Text("welcome.link_waiting")
            .textStyle(.content300)
            .foregroundStyle(.foregroundDefault)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .medium)
            .accessibilityIdentifier(AccessibilityID.line)
    }
}

private extension WelcomeLinkWaitingLine {
    enum AccessibilityID {
        static let line: String = "e2e.welcome.linkWaiting"
    }
}

#Preview {
    WelcomeLinkWaitingLine()
        .preferredColorScheme(.dark)
}
