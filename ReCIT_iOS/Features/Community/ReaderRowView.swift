//
//  ReaderRowView.swift
//  ReCIT_iOS
//
//  A reader in a list, with where I stand with them at the end of the line — `Cell / Relation`
//  of the « Réseau » Figma pass.
//
//  The row is two targets rather than one: the name opens the reader's profile, the trailing
//  control acts. A single `NavigationLink` wrapping both would have swallowed the gesture, and
//  an « Ajouter » that navigates instead of adding is a button that lies about what it does.
//
//  A friend gets no control at all: there is nothing left to offer, and an empty end of line is
//  what says the relation is settled.
//

import SwiftUI
import SwiftData

struct ReaderRowView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    let user: User
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: .sMedium) {
            Button(action: onOpen) {
                UserCellView(user: user)
            }
            .buttonStyle(.plain)

            Spacer(minLength: .zero)

            trailing
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch user.relation {
        case .none:
            Button("action.add", systemImage: "plus") {
                userModel.requestRelation(with: user, modelContext: modelContext)
            }
            .buttonStyle(.pill())
            .accessibilityIdentifier("e2e.reader.add")

        case .requestSent:
            // A state, not a button: a request is taken back from the reader's profile, where
            // the sentence explaining what cancelling means has room to sit.
            Label("network.request.sent", systemImage: "clock")
                .labelStyle(.secondaryTag)

        case .requestReceived:
            Label("network.invitation.received", systemImage: "envelope")
                .labelStyle(.tag)

        case .friend:
            EmptyView()
        }
    }
}
