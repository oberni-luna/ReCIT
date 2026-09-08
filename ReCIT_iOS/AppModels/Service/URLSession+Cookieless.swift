//
//  URLSession+Cookieless.swift
//  ReCIT_iOS
//
//  The session the app's *public* calls go through — the ones it makes before anybody has
//  signed in.
//
//  inventaire.io sits behind a global `cookie-session` middleware: ask it a public question and
//  it answers with an anonymous session under the two names a real one uses,
//  `inventaire:session` and `inventaire:session.sig`, on `/`, with six months of expiry.
//  Verified against production — `GET /api/items/recent-public`, the one call the welcome
//  screen's cover wall makes, sets both. Left to the shared jar, drawing that wall hands the app
//  a session cookie for an account nobody created.
//
//  `AuthService` no longer believes the jar (it reads the keychain, see `isLoggedIn()`), so this
//  is not what decides who is signed in any more. It is the other half: an app that quietly
//  collects sessions it never asked for is an app whose jar has to be reasoned about at every
//  turn, and pre-login traffic has nothing to gain from cookies in either direction.
//
//  See issue 0068.
//

import Foundation

extension URLSession {
    /// A session that neither sends nor stores cookies.
    ///
    /// **Public endpoints only.** An authenticated call made through this session is an
    /// anonymous one: the session cookies live in the shared jar, and this one does not read it.
    static let cookieless: URLSession = {
        let configuration: URLSessionConfiguration = .default
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = nil

        return .init(configuration: configuration)
    }()
}
