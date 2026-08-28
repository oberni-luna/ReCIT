//
//  AuthServiceTests.swift
//  ReCIT_iOSTests
//
//  The edge module, against the mock URL protocol the suite already owns. No production server
//  is contacted here, and nothing is added to the integration suite.
//
//  Three precautions the shape of this service imposes. Its initialiser reads the keychain, so
//  every test writes under a **unique** key and deletes it afterwards — a shared key would let
//  one test restore another's session. Its cookie jar is process-wide by default, so every test
//  injects its own via `sharedCookieStorage(forGroupContainerIdentifier:)`, which hands back a
//  distinct instance per identifier. And the canned responses come from
//  `MockURLProtocol.makeSession(handler:)` rather than the shared handler, because Swift Testing
//  runs top-level suites in parallel and `APIServiceTests` holds that shared handler too.
//
//  The logout case is the one worth the file. Signing out used to empty the whole jar, so a user
//  who signed out of Ex-libris also lost the session of every other host the app had ever talked
//  to. That is invisible on screen and only ever reported as "the other thing logged me out", so
//  it is asserted here.
//
//  See PRD 0010 and issue 0056.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("AuthService", .serialized)
struct AuthServiceTests {

    private static let sessionCookieName: String = "inventaire:session"
    private static let signatureCookieName: String = "inventaire:session.sig"
    private static let sessionSetCookies: [String] = [
        "\(sessionCookieName)=abc; Path=/; Domain=inventaire.io",
        "\(signatureCookieName)=def; Path=/; Domain=inventaire.io"
    ]

    // MARK: - Fixtures

    /// Everything one test needs that another test must not share: its own keychain key, its own
    /// cookie jar, and the service built on both.
    private struct Fixture {
        let keychainKey: String
        let cookieStorage: HTTPCookieStorage
        let service: AuthService
    }

    private func makeFixture(session: URLSession) -> Fixture {
        let keychainKey: String = "test.auth.\(UUID().uuidString)"
        let cookieStorage: HTTPCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: keychainKey)
        for cookie in cookieStorage.cookies ?? [] {
            cookieStorage.deleteCookie(cookie)
        }

        let config: AuthService.Config = .init(
            baseURL: "https://inventaire.io/api",
            sessionCookieNames: [Self.sessionCookieName, Self.signatureCookieName],
            keychainKey: keychainKey
        )
        return .init(
            keychainKey: keychainKey,
            cookieStorage: cookieStorage,
            service: .init(config: config, cookieStorage: cookieStorage, session: session)
        )
    }

    private func tearDown(_ fixture: Fixture) {
        Keychain.delete(key: fixture.keychainKey)
        for cookie in fixture.cookieStorage.cookies ?? [] {
            fixture.cookieStorage.deleteCookie(cookie)
        }
    }

    /// A session that answers every request the same way.
    private func makeSession(
        status: Int,
        body: Data = Data("{}".utf8),
        setCookies: [String] = []
    ) -> URLSession {
        MockURLProtocol.makeSession { request in
            (Self.response(for: request, status: status, setCookies: setCookies), body)
        }
    }

    private func makeFailingSession() -> URLSession {
        MockURLProtocol.makeSession { _ in throw URLError(.notConnectedToInternet) }
    }

    private static func response(
        for request: URLRequest,
        status: Int,
        setCookies: [String]
    ) -> HTTPURLResponse {
        var headers: [String: String] = [:]
        if !setCookies.isEmpty {
            // One header, folded the way `HTTPURLResponse` folds repeated `Set-Cookie` lines.
            headers["Set-Cookie"] = setCookies.joined(separator: ", ")
        }
        return .init(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
    }

    private func cookie(named name: String, value: String, domain: String) -> HTTPCookie {
        HTTPCookie(properties: [.name: name, .value: value, .domain: domain, .path: "/"])!
    }

    // MARK: - Signing in

    @Test("A 200 that sets the session cookies signs the user in and persists them")
    func loginSucceeds() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(
                status: 200,
                body: Data(#"{"loggedIn":true}"#.utf8),
                setCookies: Self.sessionSetCookies
            )
        )
        defer { tearDown(fixture) }

        try await fixture.service.login(username: "someone", password: "secret")

        #expect(fixture.service.isLoggedIn())
        // Persisted, so the next launch restores the session instead of asking again.
        #expect(Keychain.load(key: fixture.keychainKey) != nil)
    }

    @Test("A persisted session is restored into a jar that has forgotten it")
    func aPersistedSessionSurvivesANewService() async throws {
        let session: URLSession = makeSession(status: 200, setCookies: Self.sessionSetCookies)
        let fixture: Fixture = makeFixture(session: session)
        defer { tearDown(fixture) }

        try await fixture.service.login(username: "someone", password: "secret")

        // A fresh jar, as a relaunch would have: only the keychain can put the session back,
        // which is also what asserts the secure-coding round trip at both ends.
        for cookie in fixture.cookieStorage.cookies ?? [] {
            fixture.cookieStorage.deleteCookie(cookie)
        }
        #expect(fixture.cookieStorage.cookies?.isEmpty ?? true)

        let config: AuthService.Config = .init(
            baseURL: "https://inventaire.io/api",
            sessionCookieNames: [Self.sessionCookieName, Self.signatureCookieName],
            keychainKey: fixture.keychainKey
        )
        let restored: AuthService = .init(
            config: config,
            cookieStorage: fixture.cookieStorage,
            session: session
        )

        #expect(restored.isLoggedIn())
    }

    @Test("A refusal is a refusal, and leaves nothing behind")
    func loginRefused() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(
                status: 401,
                body: Data(#"{"status":401,"message":"invalid username or password"}"#.utf8)
            )
        )
        defer { tearDown(fixture) }

        await #expect(throws: AuthFailure.invalidCredentials) {
            try await fixture.service.login(username: "someone", password: "wrong")
        }
        #expect(fixture.service.isLoggedIn() == false)
        #expect(Keychain.load(key: fixture.keychainKey) == nil)
    }

    @Test("A transport failure reads as a network failure, not as a refusal")
    func loginNetworkFailure() async throws {
        let fixture: Fixture = makeFixture(session: makeFailingSession())
        defer { tearDown(fixture) }

        await #expect(throws: AuthFailure.network) {
            try await fixture.service.login(username: "someone", password: "secret")
        }
    }

    @Test("A 200 with no session cookie is not a signed-in user")
    func loginWithoutCookies() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(status: 200, body: Data(#"{"loggedIn":true}"#.utf8))
        )
        defer { tearDown(fixture) }

        await #expect(throws: AuthFailure.noSessionCookies) {
            try await fixture.service.login(username: "someone", password: "secret")
        }
    }

    // MARK: - Signing out

    @Test("Signing out deletes the session cookies and spares every other host's")
    func logoutSparesOtherHosts() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(status: 200, setCookies: Self.sessionSetCookies)
        )
        defer { tearDown(fixture) }

        try await fixture.service.login(username: "someone", password: "secret")

        // Another host the app has talked to. Wikidata is a real one — the entity browser
        // fetches from it — and its session used to be collateral damage of signing out.
        fixture.cookieStorage.setCookie(
            cookie(named: "wikidata_session", value: "keep-me", domain: "wikidata.org")
        )

        await fixture.service.logout()

        let remaining: [HTTPCookie] = fixture.cookieStorage.cookies ?? []
        #expect(remaining.contains { $0.name == "wikidata_session" })
        #expect(remaining.contains { $0.name == Self.sessionCookieName } == false)
        #expect(remaining.contains { $0.name == Self.signatureCookieName } == false)
        #expect(fixture.service.isLoggedIn() == false)
        #expect(Keychain.load(key: fixture.keychainKey) == nil)
    }

    @Test("Signing out with no network still signs the user out of this phone")
    func logoutSurvivesAnUnreachableServer() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(status: 200, setCookies: Self.sessionSetCookies)
        )
        defer { tearDown(fixture) }

        try await fixture.service.login(username: "someone", password: "secret")
        #expect(fixture.service.isLoggedIn())

        // A second service on the same jar and key, whose network is down.
        let offline: AuthService = .init(
            config: .init(
                baseURL: "https://inventaire.io/api",
                sessionCookieNames: [Self.sessionCookieName, Self.signatureCookieName],
                keychainKey: fixture.keychainKey
            ),
            cookieStorage: fixture.cookieStorage,
            session: makeFailingSession()
        )
        await offline.logout()

        #expect(offline.isLoggedIn() == false)
        #expect(Keychain.load(key: fixture.keychainKey) == nil)
    }

    // MARK: - The documented paths

    @Test("Signing in and out post to the documented paths, not to the deprecated ?action= form")
    func authUsesTheDocumentedPaths() async throws {
        let recorder: RequestRecorder = .init()
        let session: URLSession = MockURLProtocol.makeSession { request in
            recorder.record(request)
            return (
                Self.response(for: request, status: 200, setCookies: Self.sessionSetCookies),
                Data("{}".utf8)
            )
        }
        let fixture: Fixture = makeFixture(session: session)
        defer { tearDown(fixture) }

        try await fixture.service.login(username: "someone", password: "secret")
        await fixture.service.logout()

        let urls: [String] = recorder.urls
        #expect(urls.contains("https://inventaire.io/api/auth/login"))
        #expect(urls.contains("https://inventaire.io/api/auth/logout"))
        #expect(urls.allSatisfy { !$0.contains("action=") })
        #expect(recorder.methods.allSatisfy { $0 == "POST" })
    }
}

/// Collects what the service actually sent. A class rather than captured locals because the mock
/// protocol's handler is `@Sendable` and outlives the statement that installed it.
private final class RequestRecorder: @unchecked Sendable {
    private let lock: NSLock = .init()
    private var requests: [URLRequest] = []

    func record(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        requests.append(request)
    }

    var urls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap { $0.url?.absoluteString }
    }

    var methods: [String] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap(\.httpMethod)
    }
}
