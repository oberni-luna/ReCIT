//
//  AuthModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation

@MainActor
@Observable
public class AuthModel {
    let authService: AuthService

    public var isAuthenticated: Bool = true
    public var username: String = ""

    init(authService: AuthService) {
        self.authService = authService
        isAuthenticated = authService.isLoggedIn()
    }

    /// Typed, so a screen can render `AuthFailure.message` without first proving the error is
    /// one. That proof used to be a cast with a French fallback behind it, and the fallback was
    /// `localizedDescription` — which is where the server's English prose would have surfaced.
    func login(username: String, password: String) async throws(AuthFailure) {
        do {
            try await authService.login(username: username, password: password)
            self.isAuthenticated = true
            self.username = username
        } catch {
            self.isAuthenticated = false
            throw error
        }
    }

    /// Creates the account and leaves the user signed in, or throws what to say about it.
    ///
    /// The same shape as `login` on purpose: signing up is a way of opening a session, and the
    /// screen that follows cannot tell which door the user came through — which is the point.
    /// The chained sign-in the service may run when no session comes back is invisible from
    /// here; see `PostSignupSession`.
    func signUp(username: String, email: String, password: String) async throws(AuthFailure) {
        do {
            try await authService.signUp(username: username, email: email, password: password)
            self.isAuthenticated = true
            self.username = username
        } catch {
            self.isAuthenticated = false
            throw error
        }
    }

    /// Whether a candidate username is well formed and free. Never throws: an availability check
    /// that does not come back is not a field the user got wrong.
    func usernameAvailability(_ username: String) async -> FieldAvailability.Outcome {
        await authService.usernameAvailability(username)
    }

    /// The same, for an address.
    func emailAvailability(_ email: String) async -> FieldAvailability.Outcome {
        await authService.emailAvailability(email)
    }

    /// Asks for a password-reset link to be mailed to this address.
    ///
    /// Never throws, and never says whether an account exists: `PasswordResetOutcome` tells a
    /// server that answered from a server that could not be reached, and nothing else. The
    /// session is untouched — asking for a link is not a way of signing in.
    func requestPasswordReset(email: String) async -> PasswordResetOutcome {
        await authService.requestPasswordReset(email: email)
    }

    public func logout() async {
        await authService.logout()
        self.isAuthenticated = false
        self.username = ""
    }
}
