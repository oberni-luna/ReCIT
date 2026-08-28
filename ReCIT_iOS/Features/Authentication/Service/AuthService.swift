//
//  AuthService.swift
//  ReCIT_iOS
//
//  The edge of the authentication feature: it speaks HTTP, cookies and keychain, and it is the
//  only thing in the app that does. Everything it decides that is not I/O — which failure a
//  status stands for, what the user is told — lives in `AuthFailure`, which is pure and tested
//  without a network.
//
//  The paths are the **documented** ones, `/auth/login` and `/auth/logout`. The `?action=` form
//  this file used is deprecated server-wide; `POST /api/auth/login` was verified by hand against
//  production and answers `200` with `loggedIn` and the two session cookies. No 404 fallback is
//  kept: two authentication paths coexisting is two paths to debug later.
//
//  Set-Cookie is read off the response and written to the injected storage rather than left to
//  `URLSession`'s own jar. In production the two agree — `.shared` session, `.shared` storage —
//  but they only agree by coincidence, and a service handed a storage it then never writes to is
//  a service that cannot be tested and, worse, one whose behaviour depends on which session it
//  was built with.
//
//  See PRD 0010 and issue 0056.
//

import Foundation
import Security

final class AuthService {
    struct Config: Sendable {
        let baseURL: String
        let loginPath: String
        let logoutPath: String
        /// The cookies that *are* the session. Both persistence and the logout purge are scoped
        /// to these names — the purge used to empty the whole jar, which signed the user out of
        /// every other host the app had ever talked to.
        let sessionCookieNames: Set<String>
        /// Keychain key, namespaced per environment by `Env`.
        let keychainKey: String

        init(
            baseURL: String = "https://inventaire.io/api",
            loginPath: String = "/auth/login",
            logoutPath: String = "/auth/logout",
            sessionCookieNames: Set<String> = [
                "inventaire:session",
                "inventaire:session.sig"
            ],
            keychainKey: String = "asso.recits.auth.cookies"
        ) {
            self.baseURL = baseURL
            self.loginPath = loginPath
            self.logoutPath = logoutPath
            self.sessionCookieNames = sessionCookieNames
            self.keychainKey = keychainKey
        }
    }

    /// The shape of an inventaire.io error body. `message` is English prose written by the
    /// server; it is decoded so it can be carried into `AuthFailure.server`, and it goes no
    /// further than that.
    private struct ErrorBody: Decodable {
        let message: String?
    }

    private struct Credentials: Encodable {
        let username: String
        let password: String
    }

    private let cfg: Config
    private let cookieStorage: HTTPCookieStorage
    private let session: URLSession

    init(
        config: Config,
        cookieStorage: HTTPCookieStorage = .shared,
        session: URLSession = .shared
    ) {
        self.cfg = config
        self.cookieStorage = cookieStorage
        self.session = session

        restoreCookiesFromKeychain()
    }

    // MARK: - Public API

    func isLoggedIn() -> Bool {
        hasValidSessionCookies()
    }

    /// Opens a session for these credentials and persists it, or throws an `AuthFailure`.
    func login(username: String, password: String) async throws(AuthFailure) {
        var request: URLRequest = .init(url: URL(string: cfg.baseURL + cfg.loginPath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(Credentials(username: username, password: password))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .network
        }

        guard let http = response as? HTTPURLResponse else {
            throw .server(status: 0, serverMessage: nil)
        }

        if let failure = AuthFailure.classify(status: http.statusCode, serverMessage: serverMessage(in: data)) {
            throw failure
        }

        absorbCookies(from: http)

        guard hasValidSessionCookies() else { throw .noSessionCookies }

        try persistCookiesToKeychain()
    }

    /// Closes the session: tells the server, then forgets it locally whatever the server said.
    ///
    /// The network call is best-effort on purpose — a user who taps "se déconnecter" on a plane
    /// must still end up signed out of this phone.
    func logout() async {
        var request: URLRequest = .init(url: URL(string: cfg.baseURL + cfg.logoutPath)!)
        request.httpMethod = "POST"

        _ = try? await session.data(for: request)

        clearSessionCookies()
        deleteCookiesFromKeychain()
    }

    // MARK: - Cookies

    /// Reads `Set-Cookie` off the response into our own jar.
    private func absorbCookies(from response: HTTPURLResponse) {
        guard let url = response.url,
              let headers = response.allHeaderFields as? [String: String]
        else { return }

        let cookies: [HTTPCookie] = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        for cookie in cookies {
            cookieStorage.setCookie(cookie)
        }
    }

    /// Signed in as long as one unexpired session cookie is held. Some session cookies carry no
    /// expiry at all, which is not the same thing as being expired.
    private func hasValidSessionCookies() -> Bool {
        let now: Date = .init()
        return sessionCookies().contains { cookie in
            cookie.expiresDate.map { $0 > now } ?? true
        }
    }

    /// The session cookies currently held, wherever the jar filed them. Matched by name rather
    /// than by the jar's own URL matching: a cookie set for `.inventaire.io` and one set for
    /// `inventaire.io` are the same session, and a purge that misses one leaves the user signed
    /// in after signing out.
    private func sessionCookies() -> [HTTPCookie] {
        (cookieStorage.cookies ?? []).filter { cfg.sessionCookieNames.contains($0.name) }
    }

    private func persistCookiesToKeychain() throws(AuthFailure) {
        let jar: [HTTPCookie] = sessionCookies()
        guard !jar.isEmpty else { throw .noSessionCookies }

        // `HTTPCookie` is `NSSecureCoding`, so both ends of this round trip require it.
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: jar, requiringSecureCoding: true) else {
            throw .noSessionCookies
        }

        let status: OSStatus = Keychain.saveOrUpdate(key: cfg.keychainKey, data: data)
        guard status == errSecSuccess else { throw .keychain(status: status) }
    }

    private func restoreCookiesFromKeychain() {
        guard let data = Keychain.load(key: cfg.keychainKey) else { return }
        do {
            let unarchiver: NSKeyedUnarchiver = try .init(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
            // The classes by hand rather than `decodeArrayOfObjects(ofClass:)`: `HTTPCookie`
            // supports secure coding but the Swift overlay does not restate the conformance,
            // so the generic form will not compile against it.
            let cookies: [HTTPCookie]? = unarchiver.decodeObject(
                of: [NSArray.self, HTTPCookie.self],
                forKey: NSKeyedArchiveRootObjectKey
            ) as? [HTTPCookie]
            for cookie in cookies ?? [] {
                cookieStorage.setCookie(cookie)
            }
        } catch {
            // An entry we cannot read is an entry we will never read: drop it rather than
            // fail the same way at every launch.
            deleteCookiesFromKeychain()
        }
    }

    /// Deletes **only** the configured session cookies. This used to empty the whole jar, which
    /// meant signing out of Ex-libris also signed the user out of every other host the app had
    /// contacted — persistence already filtered correctly, and the asymmetry was the bug.
    private func clearSessionCookies() {
        for cookie in sessionCookies() {
            cookieStorage.deleteCookie(cookie)
        }
    }

    private func deleteCookiesFromKeychain() {
        _ = Keychain.delete(key: cfg.keychainKey)
    }

    /// The server's own sentence, when the body carries one. Decoded so it can be carried into
    /// the failure for a log; never read by a view.
    private func serverMessage(in data: Data) -> String? {
        try? JSONDecoder().decode(ErrorBody.self, from: data).message
    }
}
