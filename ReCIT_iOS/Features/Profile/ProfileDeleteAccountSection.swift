//
//  ProfileDeleteAccountSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 08/11/2026.
//

import SwiftUI

/// The Profil's way to deleting the account.
struct ProfileDeleteAccountSection: View {
    var body: some View {
        Section {
            NavigationLink(value: NavigationDestination.deleteAccount) {
                Text("profile.delete_account")
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundError)
            }
            .accessibilityIdentifier(AccessibilityID.deleteAccount)
        }
    }
}

private extension ProfileDeleteAccountSection {
    enum AccessibilityID {
        static let deleteAccount: String = "e2e.profile.deleteAccount"
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileDeleteAccountSection()
        }
    }
}
