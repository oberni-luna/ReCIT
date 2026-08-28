//
//  ForgotPasswordView.swift
//  ReCIT_iOS
//
//  « Mot de passe oublié » : a sentence saying what is about to happen, one address, and the
//  button that asks for the link.
//
//  The same rhythm as « Se connecter » and « Créer un compte », which are its neighbours in the
//  same stack — lead sentence, `AuthField`, full-width primary button, and a scrolling form under
//  a pinned button so that at an accessibility text size the button the user came for stays on
//  the screen.
//
//  **This screen never learns whether the address has an account, and it must not look as
//  though it might.** `PasswordResetOutcome` collapses every answer inventaire.io can give onto
//  one confirmation before this view sees it, so there is no branch here to get wrong — the only
//  thing that changes what is drawn is a request that never completed, and that reads as a
//  network failure at the foot of the form, exactly like a sign-in that could not reach the
//  server. It says nothing about the address, because nothing is known about it.
//
//  That failure is written under the form rather than under the field on purpose. An error under
//  the box means "this box is wrong"; an unreachable server is not the address's fault, and
//  putting it there would send somebody hunting for a typo in a perfectly good email.
//
//  See PRD 0010, issue 0058, and the `Mot de passe oublié` frames in the Figma library.
//

import SwiftUI

struct ForgotPasswordView: View {
    let authModel: AuthModel

    /// Where to go once the request has been made. Handed the address so the confirmation can
    /// name it back.
    let onSubmitted: (String) -> Void

    @State private var email: String = ""

    /// The outcome of the last attempt, when it was one worth saying something about. Only ever
    /// `.unreachable` — `.submitted` leaves this screen the moment it happens.
    @State private var outcome: PasswordResetOutcome?

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
        .background(.backgroundDefault)
        .navigationTitle(Text("reset.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: email) {
            outcome = nil
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: .large) {
            Text("reset.lead")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuthField(
                label: "signup.email",
                contentType: .emailAddress,
                isSecure: false,
                keyboardType: .emailAddress,
                text: $email
            )

            if let message = outcome?.message {
                Text(message)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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
        .frame(maxWidth: .infinity)
        .background(.backgroundDefault)
    }

    private func requestLink() async {
        let address: String = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let outcome: PasswordResetOutcome = await authModel.requestPasswordReset(email: address)

        switch outcome {
        case .submitted:
            self.outcome = nil
            onSubmitted(address)

        case .unreachable:
            self.outcome = outcome
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(
            authModel: .init(authService: .init(config: .init(keychainKey: "preview"))),
            onSubmitted: { _ in }
        )
    }
}
