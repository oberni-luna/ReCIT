//
//  ProfileAboutInventaireSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 08/11/2026.
//

import SwiftUI

/// The Profil's way to « À propos d'inventaire.io ».
struct ProfileAboutInventaireSection: View {
    var body: some View {
        Section {
            NavigationLink(value: NavigationDestination.aboutInventaire) {
                Text("profile.about_inventaire")
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundTinted)
            }
            .accessibilityIdentifier(AccessibilityID.about)
        }
    }
}

private extension ProfileAboutInventaireSection {
    enum AccessibilityID {
        static let about: String = "e2e.profile.about"
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileAboutInventaireSection()
        }
    }
}
