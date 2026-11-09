//
//  ProfileSettingsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 08/11/2026.
//

import SwiftUI

/// The Profil's settings: the account and its connection, then the e-mail notifications.
struct ProfileSettingsSection: View {
    var body: some View {
        Section {
            NavigationLink(value: NavigationDestination.accountSettings) {
                Text("profile.account_settings")
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundTinted)
            }
            .accessibilityIdentifier(AccessibilityID.account)

            NavigationLink(value: NavigationDestination.notificationSettings) {
                Text("profile.notification_settings")
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundTinted)
            }
            .accessibilityIdentifier(AccessibilityID.notifications)
        } header: {
            Text("profile.settings")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
    }
}

private extension ProfileSettingsSection {
    enum AccessibilityID {
        static let account: String = "e2e.profile.account"
        static let notifications: String = "e2e.profile.notifications"
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileSettingsSection()
        }
    }
}
