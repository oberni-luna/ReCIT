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
//  Signing up (issue 0057) is treated as one more way of signing in, not as a thing of its own:
//  same absorption, same keychain write, same "you are in" at the end. What it adds is the
//  fallback — if the sign-up response carried no session, a login is chained with the
//  credentials just used, so nobody ever retypes a password they chose ten seconds ago. Whether
//  to chain it is `PostSignupSession`'s call, not this file's.
//
//  Asking for a reset link (issue 0058) is the opposite kind of call: it opens no session, it
//  absorbs no cookie, and it reports nothing the server said. `PasswordResetOutcome` owns the
//  reason — the endpoint answers "email not found" for an address nobody registered, and
//  repeating that would answer "does this account exist?" for any address someone types.
//
//  See PRD 0010 and issues 0056, 0057 and 0058.
//

import Foundation
import Security

final class AuthService {
    struct Config: Sendable {
        let baseURL: String
        let loginPath: String
        let logoutPath: String
        let signupPath: String
        /// `GET`, with the candidate in the query string. The endpoint answers "valid **and**
        /// available", which is why no naming rule is written anywhere in this app.
        let usernameAvailabilityPath: String
        let emailAvailabilityPath: String
        /// `POST`, with the address in the body. Public, like the two availability endpoints,
        /// and like them it must never be allowed to hand this app a session.
        let resetPasswordPath: String
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
            signupPath: String = "/auth/signup",
            usernameAvailabilityPath: String = "/auth/username-availability",
            emailAvailabilityPath: String = "/auth/email-availability",
            resetPasswordPath: String = "/auth/reset-password",
            sessionCookieNames: Set<String> = [
                "inventaire:session",
                "inventaire:session.sig"
            ],
            keychainKey: String = "asso.recits.auth.cookies"
        ) {
            self.baseURL = baseURL
            self.loginPath = loginPath
            self.logoutPath = logoutPath
            self.signupPath = signupPath
            self.usernameAvailabilityPath = usernameAvailabilityPath
            self.emailAvailabilityPath = emailAvailabilityPath
            self.resetPasswordPath = resetPasswordPath
            self.sessionCookieNames = sessionCookieNames
            self.keychainKey = keychainKey
        }
    }

    /// The shape of an inventaire.io error body. `message` is English prose written by the
    /// server; it is decoded so it can be carried into `AuthFailure.server`, and it goes no
    /// further than that. `error_name` is the opposite: a stable machine token — `invalid_email`
    /// and friends — which is what the two classifiers actually read.
    private struct ErrorBody: Decodable {
        let message: String?
        let errorName: String?

        enum CodingKeys: String, CodingKey {
            case message
            case errorName = "error_name"
        }
    }

    private struct Credentials: Encodable {
        let username: String
        let password: String
    }

    private struct NewAccount: Encodable {
        let username: String
        let email: String
        let password: String
    }

    private struct Address: Encodable {
        let email: String
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

    /// Creates the account, and leaves the user signed in — never asking them to type any of it
    /// a second time.
    ///
    /// `POST /auth/signup` serialises the session itself today, so the common path is one round
    /// trip. When it does not, `PostSignupSession` says so and a login is chained with the same
    /// credentials. The account exists either way by then: a failure after this point is a
    /// failure to *open a session*, not a failure to create an account, which is why the
    /// fallback is worth having at all.
    func signUp(username: String, email: String, password: String) async throws(AuthFailure) {
        var request: URLRequest = .init(url: URL(string: cfg.baseURL + cfg.signupPath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(
            NewAccount(username: username, email: email, password: password)
        )

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

        let body: ErrorBody? = errorBody(in: data)
        if let failure = AuthFailure.classifySignup(
            status: http.statusCode,
            errorName: body?.errorName,
            serverMessage: body?.message
        ) {
            throw failure
        }

        absorbCookies(from: http)

        switch PostSignupSession.next(hasSessionCookies: hasValidSessionCookies()) {
        case .established:
            try persistCookiesToKeychain()

        case .chainSignIn:
            // The credentials just used, and `login` does the rest — absorption, the check, the
            // keychain write. A branch production does not produce on demand, which is exactly
            // why it goes through the path that is exercised on every launch.
            try await login(username: username, password: password)
        }
    }

    /// Whether this username is both well formed and free, as far as the server is concerned.
    ///
    /// It does not throw. A check that fails is not a field that is wrong — the answer is
    /// `undetermined`, which says nothing on screen and blocks nothing.
    func usernameAvailability(_ username: String) async -> FieldAvailability.Outcome {
        await availability(path: cfg.usernameAvailabilityPath, parameter: "username", value: username)
    }

    /// The same, for an address.
    func emailAvailability(_ email: String) async -> FieldAvailability.Outcome {
        await availability(path: cfg.emailAvailabilityPath, parameter: "email", value: email)
    }

    private func availability(
        path: String,
        parameter: String,
        value: String
    ) async -> FieldAvailability.Outcome {
        guard var components = URLComponents(string: cfg.baseURL + path) else { return .undetermined }
        components.queryItems = [.init(name: parameter, value: value)]
        guard let url = components.url else { return .undetermined }

        var request: URLRequest = .init(url: url)
        request.httpMethod = "GET"
        // **This request must not touch the session, in either direction.** Both availability
        // endpoints are public, and both answer with `Set-Cookie: inventaire:session=…` — an
        // *anonymous* session, under the very names this service reads to decide whether
        // somebody is signed in. Left to `URLSession`'s own jar, typing three letters into the
        // username box would hand the app a session cookie, and the next launch would open on
        // the tabs of an account that does not exist. Verified against production: a `200` from
        // `/auth/username-availability` sets both cookies.
        request.httpShouldHandleCookies = false

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            return .undetermined
        }

        guard let http = response as? HTTPURLResponse else { return .undetermined }

        let body: ErrorBody? = errorBody(in: data)
        return .from(
            status: http.statusCode,
            errorName: body?.errorName,
            serverMessage: body?.message
        )
    }

    /// Asks inventaire.io to mail a reset link to this address.
    ///
    /// It does not throw, and it does not report what the server said, because **what the server
    /// says is the one thing that must not get out**. Its controller looks the address up, mails
    /// the link when it finds a user, and answers `400 { message: "email not found", email }`
    /// when it does not — so passing the answer along would answer "does this account exist?"
    /// for any address somebody types. `PasswordResetOutcome` collapses every answer onto one
    /// confirmation; this method's only job is to tell an answer from no answer at all.
    ///
    /// Like the availability checks, and for the same reason, the request is kept out of the
    /// session in both directions: it is a public endpoint sitting behind the same global
    /// `cookie-session` middleware, its controller never opens a session, and any
    /// `inventaire:session` cookie coming back from it is therefore anonymous — under the very
    /// names this service reads to decide whether somebody is signed in.
    func requestPasswordReset(email: String) async -> PasswordResetOutcome {
        var request: URLRequest = .init(url: URL(string: cfg.baseURL + cfg.resetPasswordPath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(Address(email: email))
        request.httpShouldHandleCookies = false

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            return .transportFailure
        }

        // Anything that came back at all is an answer, and every answer reads the same. A
        // response with no status to read is still a response, so it goes through the same door
        // rather than being reported as a phone that could not reach the network.
        let http: HTTPURLResponse? = response as? HTTPURLResponse
        return .fromServer(status: http?.statusCode ?? 0, serverMessage: serverMessage(in: data))
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
        errorBody(in: data)?.message
    }

    /// The error body, when the response had one that decodes. A success body decodes to a
    /// record with both fields `nil`, which is the same thing as far as every caller is
    /// concerned — the status is what says whether there was a failure at all.
    private func errorBody(in data: Data) -> ErrorBody? {
        try? JSONDecoder().decode(ErrorBody.self, from: data)
    }
}
