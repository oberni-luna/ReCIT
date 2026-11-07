//
//  SessionCookieScopeTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 07/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct SessionCookieScopeTests {
    private static let names: Set<String> = ["inventaire:session", "inventaire:session.sig"]

    @Test
    func `inventaire's cookies belong to inventaire, with or without the leading dot`() {
        #expect(SessionCookieScope.covers(cookieDomain: "inventaire.io", host: "inventaire.io"))
        #expect(SessionCookieScope.covers(cookieDomain: ".inventaire.io", host: "inventaire.io"))
        #expect(SessionCookieScope.covers(cookieDomain: ".Inventaire.IO", host: "inventaire.io"))
    }

    @Test
    func `the local backend's cookies belong to it and not to inventaire`() {
        #expect(SessionCookieScope.covers(cookieDomain: "localhost", host: "localhost"))
        #expect(SessionCookieScope.covers(cookieDomain: "localhost", host: "inventaire.io") == false)
        #expect(SessionCookieScope.covers(cookieDomain: "inventaire.io", host: "localhost") == false)
    }

    @Test
    func `a parent domain covers its subdomains, never the reverse nor a lookalike`() {
        #expect(SessionCookieScope.covers(cookieDomain: ".inventaire.io", host: "api.inventaire.io"))
        #expect(SessionCookieScope.covers(cookieDomain: "api.inventaire.io", host: "inventaire.io") == false)
        #expect(SessionCookieScope.covers(cookieDomain: "inventaire.io", host: "notinventaire.io") == false)
        #expect(SessionCookieScope.covers(cookieDomain: "", host: "inventaire.io") == false)
    }

    @Test
    func `a session the local backend sets is its own, under its base URL only`() throws {
        let local: SessionCookieScope = .init(baseURL: "http://localhost:8080/api", names: Self.names)
        let inventaire: SessionCookieScope = .init(baseURL: "https://inventaire.io/api", names: Self.names)
        let url: URL = try #require(URL(string: "http://localhost:8080/api/auth/login"))
        let cookie: HTTPCookie = try #require(
            HTTPCookie.cookies(
                withResponseHeaderFields: ["Set-Cookie": "inventaire:session=abc; path=/; samesite=lax; httponly"],
                for: url
            ).first
        )

        #expect(local.contains(cookie))
        #expect(inventaire.contains(cookie) == false)
    }

    @Test
    func `only the session's names are kept, among the base URL's cookies`() throws {
        let scope: SessionCookieScope = .init(baseURL: "https://inventaire.io/api", names: Self.names)
        let cookies: [HTTPCookie] = try [
            ("inventaire:session", ".inventaire.io"),
            ("inventaire:session.sig", "inventaire.io"),
            ("loggedIn", "inventaire.io"),
            ("inventaire:session", "localhost")
        ].map { name, domain in
            try #require(HTTPCookie(properties: [.name: name, .value: "v", .domain: domain, .path: "/"]))
        }

        #expect(scope.filter(cookies).map(\.name) == ["inventaire:session", "inventaire:session.sig"])
    }

    @Test
    func `a base URL without a host holds no session`() throws {
        let scope: SessionCookieScope = .init(baseURL: "not a url", names: Self.names)
        let cookie: HTTPCookie = try #require(
            HTTPCookie(properties: [.name: "inventaire:session", .value: "v", .domain: "inventaire.io", .path: "/"])
        )

        #expect(scope.contains(cookie) == false)
    }
}
