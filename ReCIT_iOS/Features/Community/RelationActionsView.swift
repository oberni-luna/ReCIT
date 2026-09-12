//
//  RelationActionsView.swift
//  ReCIT_iOS
//
//  What one can do about a reader one is not (yet) close to: ask, or take the asking back.
//
//  It is the top half of frames `N4` and `N6` of the « Réseau » Figma pass — the buttons under
//  the profile header, on the screen's own background rather than in a white card, and the
//  sentence that says what the gesture costs. The remaining two states — an invitation received,
//  and an established friendship — are drawn elsewhere.
//
//  Both writes are optimistic (ADR 0001): the state flips here, the call runs in a task owned
//  by `UserModel`, and a refusal puts the previous state back and speaks through the snack bar.
//

import LBSnackBar
import SwiftUI
import SwiftData

struct RelationActionsView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    let user: User

    @State private var isConfirmingRequest: Bool = false

    private var answer: InvitationAnswer {
        .init(userModel: userModel, modelContext: modelContext, snackBar: snackBar)
    }

    var body: some View {
        VStack(spacing: .medium) {
            switch user.relation {
            case .none:
                Button("network.add_to_network") {
                    isConfirmingRequest = true
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("e2e.user.addToNetwork")

                note("network.reciprocal")

            case .requestSent:
                // Inert on purpose: the state is not a gesture. The way back is the button
                // under it, which is the one that acts.
                Button("network.request.sent") {}
                    .buttonStyle(.secondary())
                    .disabled(true)

                Button("network.request.cancel") {
                    userModel.cancelRelation(with: user, modelContext: modelContext)
                }
                .buttonStyle(.destructive())
                .accessibilityIdentifier("e2e.user.cancelRequest")

                note("network.request.no_notification \(user.username)")

            case .requestReceived:
                Button("network.invitation.accept_request") {
                    answer.accept(user)
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("e2e.user.acceptRequest")

                Button("network.invitation.refuse") {
                    answer.refuse(user)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("e2e.user.refuseRequest")

                note("network.invitation.explanation \(user.username)")

            case .friend:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $isConfirmingRequest) {
            RelationRequestSheet(user: user)
                .presentationDetents([.medium])
        }
    }

    private func note(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
