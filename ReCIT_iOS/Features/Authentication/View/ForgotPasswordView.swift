//
//  ForgotPasswordView.swift
//  ReCIT_iOS
//
//  « Mot de passe oublié » : a sentence saying what is about to happen, one address, and the
//  button that asks for the link.
//
//  **A sheet over the sign-in screen, not a push.** Asking for a link is an errand, not a
//  destination: it interrupts signing in and hands the screen back the moment it is done. A pull
//  down is the way out of it, which is the gesture for "never mind" that a chevron only
//  approximates — and it costs nothing, because there is nothing on this screen to lose but one
//  address.
//
//  It stands on the same green as « Se connecter » and « Créer un compte » — same lead sentence,
//  same `AuthField` with its light box, same pinned button over `AuthActionsBackground`, and the
//  same scrolling form so that at an accessibility text size the button the user came for stays
//  on the screen.
//
//  **Neither outcome is drawn on this screen.** Both are said in a snackbar, which is the app's
//  own voice everywhere else and which outlives the sheet — so the confirmation is still legible
//  after the sheet has gone, and the failure arrives without the form having to grow a paragraph
//  under it. Success dismisses; failure does not, because the address is still typed and asking
//  again is one tap.
//
//  **This screen never learns whether the address has an account, and it must not look as though
//  it might.** `PasswordResetOutcome` collapses every answer inventaire.io can give onto one
//  confirmation before this view sees it, so there is no branch here to get wrong — and the
//  confirmation is still the conditional sentence, « si un compte existe pour cette adresse… »,
//  read out of the type that owns the rule rather than written out here. The only outcome that
//  differs is a request that never completed, and that says nothing about the address either.
//
//  See PRD 0010, issues 0058 and 0059, and the `Mot de passe oublié` frames in the Figma library.
//

import LBSnackBar
import SwiftUI

struct ForgotPasswordView: View {
    let authModel: AuthModel

    @State private var email: String = ""

    @Environment(\.dismiss) var dismiss
    @Environment(\.snackBar) var snackBar

    var body: some View {
        // One arrangement, and not `ViewThatFits` — see the note in `LoginView`: under a keyboard
        // it rebuilds the `TextField` in another branch and the field loses focus as it is tapped.
        ScrollView {
            form
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            actionsBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Behind the keyboard too, like the two screens this one stands beside: a raised
        // keyboard is translucent, and `ignoresSafeAreaEdges` stops at its safe area.
        .background {
            DesignSystem.Color.backgroundTinted.color
                .ignoresSafeArea()
        }
        .navigationTitle(Text("reset.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.Color.backgroundTinted.color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: .large) {
            // `foregroundDefault`, not `foregroundSecondary`: on `green/900` the secondary veil
            // gives 4.5:1, just under AA for a sentence at this size.
            Text("reset.lead")
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuthField(
                label: "signup.email",
                contentType: .emailAddress,
                isSecure: false,
                keyboardType: .emailAddress,
                isOnTinted: true,
                text: $email
            )

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
    }

    private var actionsBar: some View {
        AsyncButton(
            action: requestLink,
            actionOptions: [.showProgressView],
            label: {
                Text("reset.button.send")
                    .frame(maxWidth: .infinity)
            }
        )
        .buttonStyle(.primary())
        .disabled(email.allSatisfy(\.isWhitespace))
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .background { AuthActionsBackground() }
    }

    private func requestLink() async {
        let address: String = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let outcome: PasswordResetOutcome = await authModel.requestPasswordReset(email: address)

        switch outcome {
        case .submitted:
            // Shown before the dismissal, and it survives it: the snackbar lives in a window of
            // its own, above whatever the sheet uncovers on its way out.
            if let confirmation = outcome.confirmation(for: address) {
                snackBar.show {
                    SnackBarView(
                        title: String(localized: "reset.sent.title"),
                        subtitle: String(localized: confirmation),
                        onDismiss: nil
                    )
                }
            }

            dismiss()

        case .unreachable:
            // Not `SnackBarView.error(_:)`, which reads an `Error`'s own description: what the
            // user sees here is `AuthFailure`'s sentence, so nothing inventaire.io wrote can
            // reach the screen by this door either.
            if let message = outcome.message {
                snackBar.show {
                    SnackBarView(title: String(localized: message), onDismiss: nil)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(
            authModel: .init(authService: .init(config: .init(keychainKey: "preview")))
        )
    }
    .preferredColorScheme(.dark)
}
