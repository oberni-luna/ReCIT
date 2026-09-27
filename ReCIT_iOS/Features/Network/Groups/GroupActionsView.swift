//
//  GroupActionsView.swift
//  ReCIT_iOS
//
//  What I can do about a group from where I stand in it: ask, take the asking back, answer an
//  invitation — the buttons under the header of `A5`, on the screen's own background, with the
//  sentence that says what the gesture means. The same shape as `RelationActionsView` for a
//  reader.
//

import SwiftUI
import SwiftData

struct GroupActionsView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext

    let group: ReaderGroup
    let myRole: GroupRole?
    let invitorName: String?

    var body: some View {
        VStack(spacing: .medium) {
            switch myRole {
            case .none, .declined:
                // An open group lets me in at once; any other waits on an admin — the button
                // says which, since the server does the one or the other.
                Button(group.open ? "groups.join" : "groups.request") {
                    groupModel.perform(.request, on: group.id, modelContext: modelContext)
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("e2e.group.request")

                GroupNote(group.open ? "groups.join.note" : "groups.request.note")

            case .requested:
                Button("groups.request.awaiting") {}
                    .buttonStyle(.secondary())
                    .disabled(true)

                Button("groups.request.cancel") {
                    groupModel.perform(.cancelRequest, on: group.id, modelContext: modelContext)
                }
                .buttonStyle(.destructive())
                .accessibilityIdentifier("e2e.group.cancelRequest")

            case .invited:
                if let invitorName {
                    GroupNote("groups.invited_by \(invitorName)")
                }

                Button("network.invitation.accept") {
                    groupModel.perform(.accept, on: group.id, modelContext: modelContext)
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("e2e.group.accept")

                Button("network.invitation.refuse") {
                    groupModel.perform(.decline, on: group.id, modelContext: modelContext)
                }
                .buttonStyle(.secondary())

            case .admin, .member:
                if let myUserId = groupModel.myUserId, group.canLeave(myUserId) == false {
                    GroupNote("groups.leave.last_admin")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
