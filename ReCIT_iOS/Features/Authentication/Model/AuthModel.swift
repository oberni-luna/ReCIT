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

    public func logout() async {
        await authService.logout()
        self.isAuthenticated = false
        self.username = ""
    }
}
