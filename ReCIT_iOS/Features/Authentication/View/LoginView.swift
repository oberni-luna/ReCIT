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
//  création → connexion without ever going back.
//
//  The message shown on failure is always ours. `AuthFailure.message` is a catalogue resource in
//  every branch, so the English prose inventaire.io writes in its `message` field has no path to
//  this screen — see the suite on that type.
//
//  See PRD 0010, issue 0056, and the `Se connecter` frames in the Figma library.
//

import SwiftUI

struct LoginView: View {
    let authModel: AuthModel
    let onCreateAccount: () -> Void

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var failure: AuthFailure?

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(spacing: .zero) {
                form

                actionsBar
            }

            ScrollView {
                form
            }
            .frame(idealHeight: .zero, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                actionsBar
            }

            ScrollView {
                VStack(spacing: .zero) {
                    form

                    actionsBar
                }
            }
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
            onCreateAccount: {}
        )
    }
}
