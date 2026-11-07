//
//  AuthServiceSessionScopeTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 07/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

/// The jar keeps inventaire.io's session and the local backend's under the same two names; each `AuthService`
/// holds, adopts and deletes its own base URL's only. Same precautions as `AuthServiceTests`: a keychain key and a
/// jar per test, canned answers from `MockURLProtocol.makeSession(handler:)`.
@Suite(.serialized)
@MainActor
struct AuthServiceSessionScopeTests {
    private static let names: Set<String> = ["inventaire:session", "inventaire:session.sig"]
    private static let inventaireBaseURL: String = "https://inventaire.io/api"
    private static let localBaseURL: String = "http://localhost:8080/api"

    @Test
    func `inventaire's session in the jar is neither held nor adopted under the local backend`() throws {
        let harness: Harness = try makeHarness(
            baseURL: Self.localBaseURL,
            jar: inventaireSession()
        )
        defer { tearDown(harness) }

        #expect(harness.service.isLoggedIn() == false)
        #expect(Keychain.load(key: harness.keychainKey) == nil)
        #expect(harness.service.webSessionCookies().isEmpty)
    }

    @Test
    func `the local backend's session in the jar is neither held nor adopted under inventaire`() throws {
        let harness: Harness = try makeHarness(
            baseURL: Self.inventaireBaseURL,
            jar: localSession()
        )
        defer { tearDown(harness) }

        #expect(harness.service.isLoggedIn() == false)
        #expect(Keychain.load(key: harness.keychainKey) == nil)
    }

    @Test
    func `the local backend's own session is held and adopted`() throws {
        let harness: Harness = try makeHarness(
            baseURL: Self.localBaseURL,
            jar: localSession()
        )
        defer { tearDown(harness) }

        #expect(harness.service.isLoggedIn())
        #expect(Keychain.load(key: harness.keychainKey) != nil)
    }

    @Test
    func `signing out of the local backend leaves inventaire's session in the jar`() async throws {
        let harness: Harness = try makeHarness(
            baseURL: Self.localBaseURL,
            jar: localSession() + inventaireSession()
        )
        defer { tearDown(harness) }

        await harness.service.logout()

        let remaining: [HTTPCookie] = harness.jar.cookies ?? []
        #expect(remaining.count == 2)
        #expect(remaining.allSatisfy { SessionCookieScope.covers(cookieDomain: $0.domain, host: "inventaire.io") })
        #expect(harness.service.isLoggedIn() == false)
    }

    private func makeHarness(
        baseURL: String,
        jar cookies: [HTTPCookie]
    ) throws -> Harness {
        let keychainKey: String = "test.auth.scope.\(UUID().uuidString)"
        let jar: HTTPCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: keychainKey)
        for cookie in jar.cookies ?? [] {
            jar.deleteCookie(cookie)
        }
        for cookie in cookies {
            jar.setCookie(cookie)
        }
        let session: URLSession = MockURLProtocol.makeSession { request in
            let url: URL = try #require(request.url)
            let response: HTTPURLResponse = try #require(
                HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
            )
            return (response, Data("{}".utf8))
        }
        let config: AuthService.Config = .init(baseURL: baseURL, sessionCookieNames: Self.names, keychainKey: keychainKey)
        return .init(
            service: .init(config: config, cookieStorage: jar, session: session),
            jar: jar,
            keychainKey: keychainKey
        )
    }

    private func tearDown(_ harness: Harness) {
        Keychain.delete(key: harness.keychainKey)
        for cookie in harness.jar.cookies ?? [] {
            harness.jar.deleteCookie(cookie)
        }
    }

    /// A signed-in session as inventaire.io sets it, `Domain=inventaire.io`.
    private func inventaireSession() throws -> [HTTPCookie] {
        let url: URL = try #require(URL(string: "https://inventaire.io/api/auth/login"))
        return try cookies(from: url, domain: "; Domain=inventaire.io")
    }

    /// A signed-in session as the local Ex-libris backend sets it: host-only, no `Domain`.
    private func localSession() throws -> [HTTPCookie] {
        let url: URL = try #require(URL(string: "http://localhost:8080/api/auth/login"))
        return try cookies(from: url, domain: "")
    }

    private func cookies(from url: URL, domain: String) throws -> [HTTPCookie] {
        let headers: [String] = [
            "inventaire:session=\(SessionCookieTests.userSession); path=/\(domain); samesite=lax; httponly",
            "inventaire:session.sig=TJn6lEOk0Jk_yNDGdsBlku0LA2ZtDoZv8ad2FR7GqcA; path=/\(domain); samesite=lax; httponly"
        ]
        let cookies: [HTTPCookie] = headers.flatMap { HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": $0], for: url) }
        try #require(cookies.count == 2)
        return cookies
    }
}

private extension AuthServiceSessionScopeTests {
    /// What one test owns and no other shares: its service, its jar, its keychain key.
    struct Harness {
        let service: AuthService
        let jar: HTTPCookieStorage
        let keychainKey: String
    }
}
