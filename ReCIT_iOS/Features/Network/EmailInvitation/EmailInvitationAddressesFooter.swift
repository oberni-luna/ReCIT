//
//  EmailInvitationAddressesFooter.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import SwiftUI

/// What « Adresses e-mail » says under itself: the addresses to fix first, then the limit of one
/// sending, and otherwise where the addresses go.
struct EmailInvitationAddressesFooter: View {
    private let list: EmailInvitationList
    private let target: EmailInvitationTarget

    /// - Parameters:
    ///   - list: The addresses read from the field.
    ///   - target: What the invitation is to, which decides the note.
    init(
        _ list: EmailInvitationList,
        target: EmailInvitationTarget
    ) {
        self.list = list
        self.target = target
    }

    private var note: LocalizedStringKey {
        switch target {
        case .friends: "network.email_invitation.addresses.note_friend"
        case .group: "network.email_invitation.addresses.note_group"
        }
    }

    var body: some View {
        if let malformed = list.malformedAddresses.first {
            Text(
                list.malformedAddresses.count == 1
                    ? "network.email_invitation.malformed_one \(malformed)"
                    : "network.email_invitation.malformed_many \(list.malformedAddresses.formatted(.list(type: .and)))"
            )
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundError)
        } else if list.addresses.count > EmailInvitationList.maximumCount {
            Text("network.email_invitation.too_many \(EmailInvitationList.maximumCount)")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundError)
        } else {
            GroupNote(note)
        }
    }
}

#Preview("Note") {
    EmailInvitationAddressesFooter(.init("marie@exemple.fr", excluding: nil), target: .friends)
        .padding()
}

#Preview("Une adresse mal formée") {
    EmailInvitationAddressesFooter(.init("marie@, lea@exemple.fr", excluding: nil), target: .friends)
        .padding()
}

#Preview("Plusieurs adresses mal formées") {
    EmailInvitationAddressesFooter(.init("marie@ @exemple.fr", excluding: nil), target: .group(id: "group-1"))
        .padding()
}
