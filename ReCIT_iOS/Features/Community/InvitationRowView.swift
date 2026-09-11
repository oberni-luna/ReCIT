//
//  InvitationRowView.swift
//  ReCIT_iOS
//
//  An invitation received: who is asking, and the two answers — `Cell / Invitation` of the
//  « Réseau » pass.
//
//  The answers sit **under** the reader rather than beside them: two buttons squeezed at the
//  end of a line would each be worth about seventy points, and the one that says yes has to be
//  wider than a thumb. Accepter is prominent, Refuser is tinted, and neither is destructive —
//  turning an invitation down destroys nothing, and red would make the person asking look like
//  a threat.
//

import SwiftUI
import SwiftData

struct InvitationRowView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    let user: User
    /// Opening the reader's profile, when the list this sits in offers it.
    var onOpen: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            if let onOpen {
                Button(action: onOpen) {
                    UserCellView(user: user)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                UserCellView(user: user)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: .small) {
                Button("network.invitation.accept") {
                    userModel.acceptRelation(with: user, modelContext: modelContext)
                }
                .buttonStyle(.pill(.prominent))
                .accessibilityIdentifier("e2e.invitation.accept")

                Button("network.invitation.refuse") {
                    userModel.discardRelation(with: user, modelContext: modelContext)
                }
                .buttonStyle(.pill())
                .accessibilityIdentifier("e2e.invitation.refuse")
            }
        }
    }
}
