//
//  EmailInvitationSheet.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import LBSnackBar
import OSLog
import SwiftData
import SwiftUI

/// « Inviter par e-mail »: addresses and an optional message, sent to inventaire.io, which mails
/// the unknown addresses and sends the known ones a friend request, or the group's invitation.
///
/// Server first (see `UserModel.sendEmailInvitations`): the button spins, a success closes the
/// sheet and says what left, a failure keeps the sheet and what was typed.
struct EmailInvitationSheet: View {
    private static let logger: Logger = .init(subsystem: "asso.recits", category: "emailInvitation")

    private let target: EmailInvitationTarget

    @State private var addresses: String
    @State private var message: String = ""

    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.snackBar) private var snackBar: SnackBarAction
    @Environment(UserModel.self) private var userModel: UserModel
    @Environment(GroupModel.self) private var groupModel: GroupModel

    /// - Parameters:
    ///   - initialAddresses: What « Adresses e-mail » opens on.
    ///   - target: To be friends, or into a group.
    init(
        initialAddresses: String,
        target: EmailInvitationTarget
    ) {
        self.target = target
        _addresses = State(initialValue: initialAddresses)
    }

    private var list: EmailInvitationList {
        .init(addresses, excluding: userModel.myUser?.email)
    }

    var body: some View {
        NavigationStack {
            DesignSystem.Form {
                Section {
                    TextField("network.email_invitation.addresses.prompt", text: $addresses, axis: .vertical)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityIdentifier(AccessibilityID.addresses)
                } header: {
                    Text("network.email_invitation.addresses")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                } footer: {
                    EmailInvitationAddressesFooter(list, target: target)
                }

                Section {
                    TextField("network.email_invitation.message", text: $message, axis: .vertical)
                        .lineLimit(2...5)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityIdentifier(AccessibilityID.message)
                }
            }
            .textCase(nil)
            .formActionBar {
                AsyncButton(
                    action: { await send() },
                    actionOptions: [.showProgressView, .disableButton],
                    label: {
                        Text("network.email_invitation.send")
                            .frame(maxWidth: .infinity)
                    }
                )
                .buttonStyle(.primary())
                .disabled(list.canSend == false)
                .accessibilityIdentifier(AccessibilityID.send)
            }
            .navigationTitle("network.email_invitation.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") { dismiss() }
                        .accessibilityIdentifier(AccessibilityID.close)
                }
            }
        }
    }

    private func send() async {
        let outcome: EmailInvitationOutcome
        do throws(EmailInvitationFailure) {
            outcome = try await userModel.sendEmailInvitations(list, message: message, to: target)
        } catch {
            report(error)
            return
        }

        snackBar.show {
            SnackBarView(title: String(localized: outcome.message), onDismiss: nil)
        }
        dismiss()

        guard outcome.hasExistingAccounts else { return }
        await refreshInvitedAccounts()
    }

    private func report(_ failure: EmailInvitationFailure) {
        snackBar.show {
            switch failure {
            case .rateLimited:
                SnackBarView(title: String(localized: EmailInvitationFailure.rateLimitedMessage), onDismiss: nil)
            case let .other(error):
                SnackBarView.error(error)
            }
        }
    }

    /// The readers already on inventaire.io are asked by now; a sync makes them show as such. Its
    /// failure is logged, not shown: the invitation itself has left.
    private func refreshInvitedAccounts() async {
        do {
            switch target {
            case .friends:
                try await userModel.syncRelations(modelContext: modelContext)
            case let .group(id):
                try await groupModel.fetchGroup(id: id, modelContext: modelContext)
            }
        } catch {
            Self.logger.error("Refresh after an email invitation failed: \(error, privacy: .public)")
        }
    }
}

private extension EmailInvitationSheet {
    enum AccessibilityID {
        static let addresses: String = "e2e.emailInvitation.addresses"
        static let message: String = "e2e.emailInvitation.message"
        static let send: String = "e2e.emailInvitation.send"
        static let close: String = "e2e.emailInvitation.close"
    }
}

#Preview("Ami·e") {
    EmailInvitationSheet(initialAddresses: "marie@exemple.fr", target: .friends)
        .environment(UserModel(apiService: APIService(env: .production)))
        .environment(GroupModel(apiService: APIService(env: .production)))
}

#Preview("Groupe, adresse mal formée") {
    EmailInvitationSheet(initialAddresses: "marie@", target: .group(id: "group-1"))
        .environment(UserModel(apiService: APIService(env: .production)))
        .environment(GroupModel(apiService: APIService(env: .production)))
}
