//
//  EmailInvitationSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import SwiftUI

/// « Pas encore sur inventaire.io ? », the section closing the two reader searches: one row
/// opening « Inviter par e-mail », and a note saying where the invitation waits once accepted.
struct EmailInvitationSection: View {
    private let note: LocalizedStringKey
    private let action: () -> Void

    /// - Parameters:
    ///   - note: The footnote: what becomes of the invitation once the address signs up.
    ///   - action: Opens « Inviter par e-mail ».
    init(
        note: LocalizedStringKey,
        action: @escaping () -> Void
    ) {
        self.note = note
        self.action = action
    }

    var body: some View {
        Section {
            Button(action: action) {
                Text("network.email_invitation.open")
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundTinted)
            }
            .accessibilityIdentifier(AccessibilityID.open)
        } header: {
            Text("network.email_invitation.section")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        } footer: {
            GroupNote(note)
        }
    }
}

private extension EmailInvitationSection {
    enum AccessibilityID {
        static let open: String = "e2e.emailInvitation.open"
    }
}

#Preview("Ami·e") {
    List {
        EmailInvitationSection(note: "network.email_invitation.section.note_friend") {}
    }
    .textCase(nil)
    .applyListBackground()
}

#Preview("Groupe") {
    List {
        EmailInvitationSection(note: "network.email_invitation.section.note_group") {}
    }
    .textCase(nil)
    .applyListBackground()
}
