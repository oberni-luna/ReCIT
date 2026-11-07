//
//  SessionCookieScope.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import Foundation

/// Which cookies in the jar are the session of the backend this build talks to. Their name is not enough:
/// inventaire.io and the Ex-libris backend (`-ExLibrisBackend`) both send `inventaire:session`, and the jar keeps
/// every host's. Read by name alone, a launch on one backend adopted the other's session into its keychain entry,
/// and signing out of one deleted the other's.
struct SessionCookieScope: Sendable {
    /// The base URL's host, `nil` when the base URL has none: then no cookie is a session.
    let host: String?
    let names: Set<String>

    /// - Parameters:
    ///   - baseURL: the base URL the app is configured with, `Env.apiBaseUrl` plus `/api`.
    ///   - names: the cookies that are the session, `AuthService.Config.sessionCookieNames`.
    init(baseURL: String, names: Set<String>) {
        self.host = URL(string: baseURL)?.host()
        self.names = names
    }

    /// RFC 6265's domain match: the cookie's domain is the host itself, or a parent of it.
    ///
    /// - Parameters:
    ///   - cookieDomain: the domain the jar filed the cookie under, with or without its leading dot.
    ///   - host: the host the cookie would be sent to.
    /// - Returns: whether the cookie is sent to `host`.
    static func covers(cookieDomain: String, host: String) -> Bool {
        let domain: String = .init(cookieDomain.lowercased().trimmingPrefix("."))
        let host: String = host.lowercased()

        return !domain.isEmpty && (host == domain || host.hasSuffix(".\(domain)"))
    }

    /// Whether `cookie` is one of the session's names, filed under the base URL's host.
    ///
    /// - Parameter cookie: a cookie from the jar or from the keychain entry.
    /// - Returns: whether it is this backend's session.
    func contains(_ cookie: HTTPCookie) -> Bool {
        guard let host else { return false }

        return names.contains(cookie.name) && Self.covers(cookieDomain: cookie.domain, host: host)
    }

    /// The session cookies among `cookies`, wherever the jar filed them: `.inventaire.io` and `inventaire.io`
    /// are the same session, and a purge that misses one leaves the user signed in after signing out.
    ///
    /// - Parameter cookies: the jar's cookies, or the keychain entry's.
    /// - Returns: those that are this backend's session.
    func filter(_ cookies: [HTTPCookie]) -> [HTTPCookie] {
        cookies.filter(contains)
    }
}
