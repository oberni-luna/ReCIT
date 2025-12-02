//
//  AuthModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation
import Combine

@MainActor
public class AuthModel: ObservableObject {
    let authService: AuthService

    @Published public var isAuthenticated: Bool = true
    @Published public var username: String = ""

    init(authService: AuthService) {
        self.authService = authService
        isAuthenticated = authService.isLoggedIn()
    }

    public func login(username: String, password: String) async throws {
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
