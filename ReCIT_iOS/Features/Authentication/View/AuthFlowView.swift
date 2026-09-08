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
//  The stack never grows past one level, and that is enforced here rather than trusted: every
//  entry point **assigns** the path instead of appending to it, so `accueil → connexion →
//  création → connexion → …` cannot be built. The sign-in screen no longer offers « Créer un
//  compte » at all — both doors are on the welcome screen — so there are two destinations left,
//  and they are siblings rather than steps.
//
//  Asking for a reset link is **not** one of them (issue 0059). It used to be a pair of pushed
//  screens, the form and its confirmation; it is now a sheet owned by « Se connecter » and a
//  snackbar, so nothing about it reaches this file. That is the point of the change: an errand
//  that hands the screen back is not a place the user navigated to.
//
//  The stack **pins the appearance to dark** (PRD 0011). Every screen it can show is green — the
//  welcome wall under its veil, and the two account forms standing on that same green — so the
//  pin no longer needs to ask which one is on screen. It stays a stack-level statement because
//  the status bar's glyphs only turn white if the *scene* asks for a dark appearance, which
//  cannot be scoped to one view. The reset sheet is presented outside this stack and states it
//  again for itself.
//
//  See PRD 0010, PRD 0011, and issues 0056, 0058 and 0059.
//

import SwiftUI

struct AuthFlowView: View {
    let authModel: AuthModel
    /// The welcome screen's wall of covers. Built by the composition root like every other
    /// model, and held here rather than inside `WelcomeView` so the covers it fetched survive a
    /// trip to the sign-in screen and back.
    let coverWall: CoverWallModel

    @State private var path: [AuthDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                coverWall: coverWall,
                onSignIn: { path = [.signIn] },
                onCreateAccount: { path = [.createAccount] }
            )
            .navigationDestination(for: AuthDestination.self) { destination in
                view(for: destination)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func view(for destination: AuthDestination) -> some View {
        switch destination {
        case .signIn:
            LoginView(authModel: authModel)

        case .createAccount:
            CreateAccountView(authModel: authModel)
        }
    }
}

#Preview {
    AuthFlowView(
        authModel: .init(authService: .init(config: .init(keychainKey: "preview"))),
        coverWall: .init(apiService: APIService(env: .production))
    )
}
