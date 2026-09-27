//
//  GroupRowView.swift
//  ReCIT_iOS
//
//  A group and where I stand in it, on one line — `Cell / Group`. Meant to sit inside a
//  `NavigationLink`: the whole row opens the group.
//

import SwiftUI

struct GroupRowView: View {
    let cell: GroupCellView
    let role: GroupRole?

    var body: some View {
        HStack(spacing: .sMedium) {
            cell
            Spacer(minLength: .zero)
            GroupRoleTag(role: role)
        }
    }
}
