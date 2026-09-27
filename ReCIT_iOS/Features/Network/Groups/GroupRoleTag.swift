//
//  GroupRoleTag.swift
//  ReCIT_iOS
//
//  Where I stand in a group, at the end of its row — `Cell / Group` States Admin and Sent. A
//  member gets nothing: an empty end of line is what says the membership is settled.
//

import SwiftUI

struct GroupRoleTag: View {
    let role: GroupRole?

    var body: some View {
        switch role {
        case .admin:
            Label("groups.role.admin", systemImage: "checkmark.seal")
                .labelStyle(.tag)
        case .requested:
            Label("groups.request.sent", systemImage: "clock")
                .labelStyle(.secondaryTag)
        case .invited:
            Label("groups.invitation.received", systemImage: "envelope")
                .labelStyle(.tag)
        case .member, .declined, .none:
            EmptyView()
        }
    }
}
