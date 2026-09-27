//
//  GroupMemberRowView.swift
//  ReCIT_iOS
//
//  A person seen from a group — `Cell / Member`: the reader's own cell, and their role at the
//  end of the line when it is worth saying.
//

import SwiftUI

struct GroupMemberRowView: View {
    let user: User
    let role: GroupRole

    var body: some View {
        HStack(spacing: .sMedium) {
            UserCellView(user: user)
            Spacer(minLength: .zero)
            switch role {
            case .admin:
                Label("groups.role.admin", systemImage: "checkmark.seal")
                    .labelStyle(.tag)
            case .invited:
                Label("groups.invitation.sent", systemImage: "clock")
                    .labelStyle(.secondaryTag)
            case .member, .requested, .declined:
                EmptyView()
            }
        }
    }
}
