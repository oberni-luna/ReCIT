//
//  AuthFlowView.swift
//  ReCIT_iOS
//
//  The signed-out branch, and the navigation stack that carries it. The welcome screen is its
//  root, so it is what a logged-out launch opens on — nothing is persisted about having seen it,
//  and nothing should be: `OnboardingStore` is keyed by user id and defends that choice, and
//  before signing in there is no user id to key on. Being signed out *is* the state that needs
//  the pitch.
//
//  The stack never grows past one level, and that is enforced here rather than trusted: both
//  entry points **assign** the path instead of appending to it, so `accueil → connexion →
//  création → connexion → …` cannot be built. It matters most from the sign-in screen, where
//  "Créer un compte" is a change of mind and not a step forward.
//
//  The reset pair (issue 0058) follows the same rule: « Mot de passe oublié ? » replaces the
//  stack, and so does its confirmation. Which is why that confirmation carries an explicit
//  « Retour à la connexion » — the chevron behind it leads to the welcome screen, and a
//  confirmation whose only exit is backwards is a dead end with a link in it.
//
//  See PRD 0010 and issues 0056 and 0058.
//

import SwiftUI

struct AuthFlowView: View {
    let authModel: AuthModel

    @State private var path: [AuthDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onSignIn: { path = [.signIn] },
                onCreateAccount: { path = [.createAccount] }
            )
            .navigationDestination(for: AuthDestination.self) { destination in
                view(for: destination)
            }
        }
    }

    @ViewBuilder
    private func view(for destination: AuthDestination) -> some View {
        switch destination {
        case .signIn:
            LoginView(
                authModel: authModel,
                onCreateAccount: { path = [.createAccount] },
                onForgotPassword: { path = [.forgotPassword] }
            )

        case .createAccount:
            CreateAccountView(authModel: authModel)

        case .forgotPassword:
            ForgotPasswordView(
                authModel: authModel,
                onSubmitted: { address in path = [.passwordResetSent(address: address)] }
            )

        case .passwordResetSent(let address):
            PasswordResetSentView(
                address: address,
                onBackToSignIn: { path = [.signIn] }
            )
        }
    }
}

#Preview {
    AuthFlowView(authModel: .init(authService: .init(config: .init(keychainKey: "preview"))))
}
