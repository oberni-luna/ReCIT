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
//  See PRD 0010 and issue 0056.
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
                onCreateAccount: { path = [.createAccount] }
            )

        case .createAccount:
            CreateAccountPlaceholderView()
        }
    }
}

#Preview {
    AuthFlowView(authModel: .init(authService: .init(config: .init(keychainKey: "preview"))))
}
