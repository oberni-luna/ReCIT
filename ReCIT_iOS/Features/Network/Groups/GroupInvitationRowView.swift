//
//  GroupInvitationRowView.swift
//  ReCIT_iOS
//
//  An invitation to join a group: which group, who asked, and the two answers —
//  `Cell / Group Invitation`. Laid out like `InvitationRowView`, the answers under the group
//  rather than beside it, and for the same reasons: a « yes » wider than a thumb, and a
//  « no » that is tinted and never red — declining destroys nothing.
//

import SwiftUI
import SwiftData

struct GroupInvitationRowView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext

    let group: ReaderGroup
    /// The username of whoever sent the invitation, when the store knows them.
    let invitorName: String?
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: .xSmall) {
                    GroupCellView(group: group)
                    if let invitorName {
                        Text("groups.invited_by \(invitorName)")
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: .small) {
                Button("network.invitation.accept") {
                    groupModel.perform(.accept, on: group.id, modelContext: modelContext)
                }
                .buttonStyle(.pill(.prominent))
                .accessibilityIdentifier("e2e.group.invitation.accept")

                Button("network.invitation.refuse") {
                    groupModel.perform(.decline, on: group.id, modelContext: modelContext)
                }
                .buttonStyle(.pill())
                .accessibilityIdentifier("e2e.group.invitation.refuse")
            }
        }
    }
}
