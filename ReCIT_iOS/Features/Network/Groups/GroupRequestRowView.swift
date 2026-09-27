//
//  GroupRequestRowView.swift
//  ReCIT_iOS
//
//  A reader asking to join a group I administer — `Cell / Member` Role=Request. The same
//  shape as `InvitationRowView`: the reader, then the two answers under them, the yes
//  prominent, the no tinted and never red.
//

import SwiftUI
import SwiftData

struct GroupRequestRowView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext

    let user: User
    let groupId: String
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            Button(action: onOpen) {
                UserCellView(user: user)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: .small) {
                Button("network.invitation.accept") {
                    groupModel.perform(.acceptRequest, on: groupId, target: user._id, modelContext: modelContext)
                }
                .buttonStyle(.pill(.prominent))
                .accessibilityIdentifier("e2e.group.request.accept")

                Button("network.invitation.refuse") {
                    groupModel.perform(.refuseRequest, on: groupId, target: user._id, modelContext: modelContext)
                }
                .buttonStyle(.pill())
                .accessibilityIdentifier("e2e.group.request.refuse")
            }
        }
    }
}
