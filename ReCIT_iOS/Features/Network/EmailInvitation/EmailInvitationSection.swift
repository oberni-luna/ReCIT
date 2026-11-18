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
    private let target: EmailInvitationTarget
    private let action: () -> Void

    /// - Parameters:
    ///   - target: What the invitation is to, which decides the note.
    ///   - action: Opens « Inviter par e-mail ».
    init(
        _ target: EmailInvitationTarget,
        action: @escaping () -> Void
    ) {
        self.target = target
        self.action = action
    }

    private var note: LocalizedStringKey {
        switch target {
        case .friends: "network.email_invitation.section.note_friend"
        case .group: "network.email_invitation.section.note_group"
        }
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
        EmailInvitationSection(.friends) {}
    }
    .textCase(nil)
    .applyListBackground()
}

#Preview("Groupe") {
    List {
        EmailInvitationSection(.group(id: "group-1")) {}
    }
    .textCase(nil)
    .applyListBackground()
}
