//
//  ChangeEmailView.swift
//  ReCIT_iOS
//
//  « Adresse e-mail » (`A8` in the Figma file): the address in use, the new one checked while it
//  is typed as at sign-up, and « Enregistrer », server first. inventaire.io then mails a link to
//  the new address and holds it unconfirmed until it is opened — « Compte et connexion » says so.
//

import LBSnackBar
import SwiftUI

struct ChangeEmailView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AuthModel.self) private var authModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.snackBar) private var snackBar

    @State private var email: String = ""
    @State private var emailCheck: FieldAvailability = .init(field: .email)

    private static let checkDelay: Duration = .milliseconds(600)

    private var typed: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        typed.contains("@")
            && typed.lowercased() != userModel.account?.email?.lowercased()
            && emailCheck.isRefused == false
    }

    var body: some View {
        DesignSystem.Form {
            Section {
                if let current = userModel.account?.email {
                    Text(current)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "change_email.current")
                }

                TextField("change_email.new", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textStyle(.content300)
                    .accessibilityIdentifier("e2e.changeEmail.new")
                    .withLabel(label: "change_email.new")
            } footer: {
                VStack(alignment: .leading, spacing: .xSmall) {
                    if let message = emailCheck.message {
                        Text(message)
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundError)
                    }

                    CreateBookSectionFooter("change_email.footer")
                }
            }
        }
        .navigationTitle("change_email.title")
        .formActionBar {
            AsyncButton(
                action: save,
                actionOptions: [.showProgressView],
                label: {
                    Text("action.save")
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.primary())
            .disabled(canSave == false)
            .accessibilityIdentifier("e2e.changeEmail.save")
        }
        .task(id: typed) {
            await check()
        }
    }

    private func check() async {
        emailCheck.edited(to: typed)
        guard let query = emailCheck.pendingQuery else { return }

        do {
            try await Task.sleep(for: Self.checkDelay)
        } catch {
            return
        }

        let outcome: FieldAvailability.Outcome = await authModel.emailAvailability(query)
        emailCheck.apply(outcome, for: query)
    }

    private func save() async {
        let address: String = typed
        do {
            try await userModel.changeEmail(to: address)
            snackBar.show {
                SnackBarView(title: String(localized: "change_email.done \(address)"), onDismiss: nil)
            }
            dismiss()
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}
