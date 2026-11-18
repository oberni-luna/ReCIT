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

    private let groupId: String?

    @State private var addresses: String
    @State private var message: String = ""

    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.snackBar) private var snackBar: SnackBarAction
    @Environment(UserModel.self) private var userModel: UserModel
    @Environment(GroupModel.self) private var groupModel: GroupModel

    /// - Parameters:
    ///   - initialAddresses: What « Adresses e-mail » opens on.
    ///   - groupId: The group to invite to, `nil` for a friend request.
    init(
        initialAddresses: String,
        groupId: String?
    ) {
        self.groupId = groupId
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
                    EmailInvitationAddressesFooter(list, isForGroup: groupId != nil)
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
                }
            }
        }
    }

    private func send() async {
        let outcome: EmailInvitationOutcome
        do throws(EmailInvitationFailure) {
            outcome = try await userModel.sendEmailInvitations(list, message: message, groupId: groupId)
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
            if let message = failure.message {
                SnackBarView(title: String(localized: message), onDismiss: nil)
            } else if case let .other(error) = failure {
                SnackBarView.error(error)
            }
        }
    }

    /// The readers already on inventaire.io are asked by now; a sync makes them show as such. Its
    /// failure is logged, not shown: the invitation itself has left.
    private func refreshInvitedAccounts() async {
        do {
            if let groupId {
                _ = try await groupModel.fetchGroup(id: groupId, modelContext: modelContext)
            } else {
                try await userModel.syncRelations(modelContext: modelContext)
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
    }
}

#Preview("Ami·e") {
    EmailInvitationSheet(initialAddresses: "marie@exemple.fr", groupId: nil)
        .environment(UserModel(apiService: APIService(env: .production)))
        .environment(GroupModel(apiService: APIService(env: .production)))
}

#Preview("Groupe, adresse mal formée") {
    EmailInvitationSheet(initialAddresses: "marie@", groupId: "group-1")
        .environment(UserModel(apiService: APIService(env: .production)))
        .environment(GroupModel(apiService: APIService(env: .production)))
}
