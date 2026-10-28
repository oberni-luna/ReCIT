//
//  ChangePasswordView.swift
//  ReCIT_iOS
//
//  « Mot de passe » (`A7` in the Figma file): the current one, the new one, and « Enregistrer »,
//  server first. Under them, « Mot de passe oublié ? » for the reader who changes it because they
//  no longer know it — the same reset link the sign-in screen sends.
//

import LBSnackBar
import SwiftUI

struct ChangePasswordView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AuthModel.self) private var authModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.snackBar) private var snackBar

    @State private var current: String = ""
    @State private var new: String = ""
    @State private var failure: PasswordChangeFailure?

    /// `BoundedString(8, 256)` in the server's user validations.
    private static let lengthRange: ClosedRange<Int> = 8...256

    private var canSave: Bool {
        current.isEmpty == false && Self.lengthRange.contains(new.count)
    }

    var body: some View {
        DesignSystem.Form {
            Section {
                SecureField("change_password.current", text: $current)
                    .textContentType(.password)
                    .textStyle(.content300)
                    .accessibilityIdentifier("e2e.changePassword.current")
                    .withLabel(label: "change_password.current")

                SecureField("change_password.new", text: $new)
                    .textContentType(.newPassword)
                    .textStyle(.content300)
                    .accessibilityIdentifier("e2e.changePassword.new")
                    .withLabel(label: "change_password.new")
            } footer: {
                VStack(alignment: .leading, spacing: .xSmall) {
                    if let failure {
                        Text(failure.message)
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundError)
                    }

                    CreateBookSectionFooter("change_password.footer")
                }
            }

            if let email = userModel.account?.email {
                Section {
                    AsyncButton(
                        action: { await requestReset(email: email) },
                        actionOptions: [.showProgressView],
                        label: {
                            Text("change_password.forgot")
                                .textStyle(.action300)
                                .foregroundStyle(.foregroundTinted)
                        }
                    )
                    .accessibilityIdentifier("e2e.changePassword.forgot")
                } footer: {
                    CreateBookSectionFooter("change_password.forgot.footer \(email)")
                }
            }
        }
        .navigationTitle("change_password.title")
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
            .accessibilityIdentifier("e2e.changePassword.save")
        }
        .onChange(of: current) { failure = nil }
    }

    private func save() async {
        do {
            try await userModel.changePassword(current: current, new: new)
            snackBar.show {
                SnackBarView(title: String(localized: "change_password.done"), onDismiss: nil)
            }
            dismiss()
        } catch {
            failure = error
        }
    }

    private func requestReset(email: String) async {
        let outcome: PasswordResetOutcome = await authModel.requestPasswordReset(email: email)
        guard let text = outcome.confirmation(for: email) ?? outcome.message else { return }
        snackBar.show {
            SnackBarView(title: String(localized: text), onDismiss: nil)
        }
    }
}
