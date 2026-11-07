//
//  EnvTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 07/11/2026.
//

import Testing
@testable import ReCIT_iOS

@Suite
struct EnvTests {
    @Test
    func `without the launch argument the app talks to inventaire.io under its usual keychain key`() {
        #expect(Env.production.apiBaseUrl(backendOverride: nil) == "https://inventaire.io")
        #expect(Env.production.keychainKey(backendOverride: nil) == "asso.recits.auth.cookies")
        #expect(Env.development.keychainKey(backendOverride: nil) == "asso.recits.auth.cookies.dev")
    }

    @Test
    func `with the launch argument the app talks to that backend under a suffixed keychain key`() {
        let backend: String = "http://localhost:8080"

        #expect(Env.production.apiBaseUrl(backendOverride: backend) == backend)
        #expect(Env.production.keychainKey(backendOverride: backend) == "asso.recits.auth.cookies.exlibris")
        #expect(Env.development.keychainKey(backendOverride: backend) == "asso.recits.auth.cookies.dev.exlibris")
    }
}
