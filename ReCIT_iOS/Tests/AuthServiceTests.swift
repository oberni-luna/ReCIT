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
//  The sign-up cases added for issue 0057 carry the same weight for a different reason. The one
//  worth the file there is the `200` that sets **no** cookie: production never answers that
//  today, since `/auth/signup` serialises the session itself, so the fallback that chains a
//  sign-in is unreachable by hand and would break for every new user at once the day the server
//  changes its mind. Here it is one canned response.
//
//  See PRD 0010 and issues 0056 and 0057.
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

    // MARK: - Signing up

    @Test("A sign-up that comes back with a session signs the user in and persists it")
    func signUpSucceeds() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(
                status: 200,
                body: Data(#"{"ok":true}"#.utf8),
                setCookies: Self.sessionSetCookies
            )
        )
        defer { tearDown(fixture) }

        try await fixture.service.signUp(
            username: "someone",
            email: "someone@example.org",
            password: "a-long-enough-password"
        )

        #expect(fixture.service.isLoggedIn())
        #expect(Keychain.load(key: fixture.keychainKey) != nil)
    }

    @Test("A sign-up that comes back with no session still lands the user signed in")
    func signUpWithoutCookiesChainsASignIn() async throws {
        let recorder: RequestRecorder = .init()
        // The branch production does not produce: the account is created and nothing is set,
        // so only the login that follows can put a session in the jar.
        let routed: URLSession = MockURLProtocol.makeSession { request in
            recorder.record(request)
            let path: String = request.url?.path ?? ""
            let setCookies: [String] = path.hasSuffix("/auth/signup") ? [] : Self.sessionSetCookies
            return (
                Self.response(for: request, status: 200, setCookies: setCookies),
                Data(#"{"ok":true}"#.utf8)
            )
        }

        let fixture: Fixture = makeFixture(session: routed)
        defer { tearDown(fixture) }

        try await fixture.service.signUp(
            username: "someone",
            email: "someone@example.org",
            password: "a-long-enough-password"
        )

        // Signed in, persisted, and nobody was asked to type anything twice.
        #expect(fixture.service.isLoggedIn())
        #expect(Keychain.load(key: fixture.keychainKey) != nil)
        #expect(recorder.urls.contains("https://inventaire.io/api/auth/signup"))
        #expect(recorder.urls.contains("https://inventaire.io/api/auth/login"))
    }

    @Test("A refused sign-up names the field it refused")
    func signUpRefusedNamesTheField() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(
                status: 400,
                body: Data(#"{"status":400,"message":"this username is already used"}"#.utf8)
            )
        )
        defer { tearDown(fixture) }

        await #expect(throws: AuthFailure.usernameTaken) {
            try await fixture.service.signUp(
                username: "someone",
                email: "someone@example.org",
                password: "a-long-enough-password"
            )
        }
        #expect(fixture.service.isLoggedIn() == false)
        #expect(Keychain.load(key: fixture.keychainKey) == nil)
    }

    @Test("A sign-up with no network reads as a network failure, not as a refused field")
    func signUpNetworkFailure() async throws {
        let fixture: Fixture = makeFixture(session: makeFailingSession())
        defer { tearDown(fixture) }

        await #expect(throws: AuthFailure.network) {
            try await fixture.service.signUp(
                username: "someone",
                email: "someone@example.org",
                password: "a-long-enough-password"
            )
        }
    }

    @Test("Signing up posts the three fields to the documented path")
    func signUpUsesTheDocumentedPath() async throws {
        let recorder: RequestRecorder = .init()
        let session: URLSession = MockURLProtocol.makeSession { request in
            recorder.record(request)
            return (
                Self.response(for: request, status: 200, setCookies: Self.sessionSetCookies),
                Data(#"{"ok":true}"#.utf8)
            )
        }
        let fixture: Fixture = makeFixture(session: session)
        defer { tearDown(fixture) }

        try await fixture.service.signUp(
            username: "someone",
            email: "someone@example.org",
            password: "a-long-enough-password"
        )

        #expect(recorder.urls == ["https://inventaire.io/api/auth/signup"])
        #expect(recorder.methods == ["POST"])

        let body: [String: String] = try #require(recorder.jsonBodies.first)
        #expect(body["username"] == "someone")
        #expect(body["email"] == "someone@example.org")
        #expect(body["password"] == "a-long-enough-password")
    }

    // MARK: - Checking a field while it is typed

    @Test("A 200 from either availability endpoint is a free field")
    func availabilityReadsASuccess() async throws {
        let fixture: Fixture = makeFixture(
            session: makeSession(
                status: 200,
                body: Data(#"{"username":"someone","status":"available"}"#.utf8)
            )
        )
        defer { tearDown(fixture) }

        #expect(await fixture.service.usernameAvailability("someone") == .available)
        #expect(await fixture.service.emailAvailability("someone@example.org") == .available)
    }

    @Test("A taken value and a malformed one are told apart")
    func availabilityTellsTakenFromInvalid() async throws {
        let taken: Fixture = makeFixture(
            session: makeSession(
                status: 400,
                body: Data(#"{"status":400,"message":"this username is already used"}"#.utf8)
            )
        )
        defer { tearDown(taken) }
        #expect(await taken.service.usernameAvailability("someone") == .taken)

        let invalid: Fixture = makeFixture(
            session: makeSession(
                status: 400,
                body: Data(
                    #"{"status":400,"message":"invalid email: nope","error_name":"invalid_email"}"#.utf8
                )
            )
        )
        defer { tearDown(invalid) }
        #expect(await invalid.service.emailAvailability("nope") == .invalid)
    }

    @Test("A check that cannot be made is not a field the user got wrong")
    func availabilitySurvivesAnUnreachableServer() async throws {
        let fixture: Fixture = makeFixture(session: makeFailingSession())
        defer { tearDown(fixture) }

        #expect(await fixture.service.usernameAvailability("someone") == .undetermined)
        #expect(await fixture.service.emailAvailability("someone@example.org") == .undetermined)
    }

    @Test("Checking a name never signs anybody in")
    func availabilityLeavesTheSessionAlone() async throws {
        let recorder: RequestRecorder = .init()
        // What production actually answers: both availability endpoints hand back an
        // *anonymous* session under the same two cookie names a real session uses. Absorbing
        // them would make the app open on the tabs of an account nobody created.
        let session: URLSession = MockURLProtocol.makeSession { request in
            recorder.record(request)
            return (
                Self.response(for: request, status: 200, setCookies: Self.sessionSetCookies),
                Data(#"{"status":"available"}"#.utf8)
            )
        }
        let fixture: Fixture = makeFixture(session: session)
        defer { tearDown(fixture) }

        _ = await fixture.service.usernameAvailability("someone")
        _ = await fixture.service.emailAvailability("someone@example.org")

        #expect(fixture.service.isLoggedIn() == false)
        #expect(Keychain.load(key: fixture.keychainKey) == nil)
        // And the jar `URLSession` keeps on its own is spared too, which is the half this
        // service cannot undo after the fact.
        #expect(recorder.cookieHandling.allSatisfy { $0 == false })
    }

    @Test("The candidate goes in the query string, on the documented paths")
    func availabilityUsesTheDocumentedPaths() async throws {
        let recorder: RequestRecorder = .init()
        let session: URLSession = MockURLProtocol.makeSession { request in
            recorder.record(request)
            return (
                Self.response(for: request, status: 200, setCookies: []),
                Data(#"{"status":"available"}"#.utf8)
            )
        }
        let fixture: Fixture = makeFixture(session: session)
        defer { tearDown(fixture) }

        _ = await fixture.service.usernameAvailability("some one")
        _ = await fixture.service.emailAvailability("someone@example.org")

        let urls: [String] = recorder.urls
        #expect(urls.contains("https://inventaire.io/api/auth/username-availability?username=some%20one"))
        #expect(urls.contains("https://inventaire.io/api/auth/email-availability?email=someone@example.org"))
        #expect(recorder.methods.allSatisfy { $0 == "GET" })
        #expect(urls.allSatisfy { !$0.contains("action=") })
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

    /// Whether each request let `URLSession` send and store cookies for it.
    var cookieHandling: [Bool] {
        lock.lock()
        defer { lock.unlock() }
        return requests.map(\.httpShouldHandleCookies)
    }

    /// The bodies, decoded. `URLProtocol` empties `httpBody` on the request it hands the
    /// protocol, so the stream is what carries it — reading it is the only way to assert that
    /// the three sign-up fields actually left the phone.
    var jsonBodies: [[String: String]] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap { request in
            guard let data = request.bodyData else { return nil }
            return try? JSONDecoder().decode([String: String].self, from: data)
        }
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }

        var data: Data = .init()
        let size: Int = 4096
        var buffer: [UInt8] = .init(repeating: 0, count: size)
        while stream.hasBytesAvailable {
            let read: Int = stream.read(&buffer, maxLength: size)
            guard read > 0 else { break }
            data.append(contentsOf: buffer[0..<read])
        }
        return data
    }
}
