//
//  LoginView.swift
//  ReCIT_iOS
//
//  « Se connecter » : a lead sentence saying whose account this is, two fields, and the way in.
//
//  It is no longer the app's root — `WelcomeView` is — so it has a navigation bar and a back
//  chevron, and it no longer carries the branding block that used to stand in for a welcome
//  screen. What it keeps is the note under the fields: a sign-in failure belongs to neither
//  field on its own, so it is written once under both rather than attributed to a guess.
//
//  "Créer un compte" **replaces** the stack rather than pushing onto it. From here it is a
//  change of mind, not a step forward, and pushing would let a user build accueil → connexion →
//  création → connexion without ever going back. « Mot de passe oublié ? » (issue 0058) does the
//  same, for the same reason.
//
//  The message shown on failure is always ours. `AuthFailure.message` is a catalogue resource in
//  every branch, so the English prose inventaire.io writes in its `message` field has no path to
//  this screen — see the suite on that type.
//
//  See PRD 0010, issues 0056 and 0058, and the `Se connecter` frames in the Figma library.
//

import SwiftUI

struct LoginView: View {
    let authModel: AuthModel
    let onCreateAccount: () -> Void
    let onForgotPassword: () -> Void

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var failure: AuthFailure?

    var body: some View {
        // One arrangement, deliberately. The form scrolls when it does not fit and sits still
        // when it does, and the actions stay pinned either way.
        //
        // **Not `ViewThatFits`**, which the onboarding screens use for the problem that looks
        // like this one. On a screen with a keyboard it is a focus bug: raising the keyboard
        // shrinks the available height, `ViewThatFits` picks a different branch, and the
        // `TextField` is rebuilt at a different place in the view tree. SwiftUI reads that as a
        // different view, drops the focus and dismisses the keyboard — which made the username
        // field impossible to type into at all. The onboarding screens are safe because nothing
        // on them raises a keyboard.
        ScrollView {
            form
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            actionsBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
        .navigationTitle(Text("login.button.signin"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: .large) {
            Text("login.subtitle")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuthField(
                label: "login.username",
                contentType: .username,
                isSecure: false,
                text: $username
            )

            AuthField(
                label: "login.password",
                contentType: .password,
                isSecure: true,
                text: $password
            )

            if let failure {
                Text(failure.message)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Read back by the end-to-end scenario when the session never opens, so its
                    // report carries what the screen actually said instead of "rien ne s'est
                    // passé".
                    .accessibilityIdentifier("e2e.login.failure")
            }

            // Under the password box, where somebody who has just failed to remember one is
            // already looking — and not in the bar below, which is where the two doors out of
            // this screen live and where a third choice would dilute both.
            Button(action: onForgotPassword) {
                Text("login.button.forgot_password")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundTinted)
            }

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
    }

    private var actionsBar: some View {
        VStack(spacing: .medium) {
            AsyncButton(
                action: signIn,
                actionOptions: [.showProgressView],
                label: {
                    Text("login.button.signin")
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.primary())
            .accessibilityIdentifier("e2e.login.submit")

            Button(action: onCreateAccount) {
                Text("login.button.create_account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary())
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .background(.backgroundDefault)
    }

    private func signIn() async {
        do {
            try await authModel.login(username: username, password: password)
            failure = nil
        } catch {
            failure = error
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(
            authModel: .init(authService: .init(config: .init(keychainKey: "preview"))),
            onCreateAccount: {},
            onForgotPassword: {}
        )
    }
}
