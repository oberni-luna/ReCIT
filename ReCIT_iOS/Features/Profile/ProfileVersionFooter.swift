//
//  ProfileVersionFooter.swift
//  ReCIT_iOS
//
//  The Profil's last line: « Ex-libris · Version 1.3.0 (10) », small, grey and centred under the
//  last section, on the screen's own background. What someone writing a bug report is asked for,
//  and the one place the app says it.
//

import SwiftUI

struct ProfileVersionFooter: View {
    let version: AppVersion

    var body: some View {
        Text("profile.version \(version.version) \(version.build)")
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier("e2e.profile.version")
    }
}
