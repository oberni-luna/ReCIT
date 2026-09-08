//
//  SessionCookieTests.swift
//  ReCIT_iOSTests
//
//  Pure, no network: the one question `SessionCookie` answers, on the two payloads production
//  actually serialises.
//
//  Both strings below were taken off inventaire.io by hand — the anonymous one from
//  `GET /api/items/recent-public`, which is what the welcome screen's cover wall calls, and the
//  user one out of a signed-in app's cookie jar. They are the reason trusting the jar is safe
//  again: the free session names nobody, and only signing in produces one that names somebody.
//
//  See issues 0068 and 0069.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("SessionCookie")
struct SessionCookieTests {

    /// `{"user":"36829e21389c27c629a3181e31c36301","timestamp":1787493340761}`
    static let userSession: String =
        "eyJ1c2VyIjoiMzY4MjllMjEzODljMjdjNjI5YTMxODFlMzFjMzYzMDEiLCJ0aW1lc3RhbXAiOjE3ODc0OTMzNDA3NjF9"
    /// `{"timestamp":1788900010063}` — what every public endpoint hands out for free.
    static let anonymousSession: String = "eyJ0aW1lc3RhbXAiOjE3ODg5MDAwMTAwNjN9"

    @Test("A signed-in session names its user")
    func userSessionNamesTheUser() {
        #expect(
            SessionCookie.owner(ofValue: Self.userSession)
                == .user(id: "36829e21389c27c629a3181e31c36301")
        )
        #expect(SessionCookie.namesAUser([Self.userSession]))
    }

    @Test("The session every public endpoint hands out names nobody")
    func anonymousSessionNamesNobody() {
        #expect(SessionCookie.owner(ofValue: Self.anonymousSession) == .anonymous)
        #expect(SessionCookie.namesAUser([Self.anonymousSession]) == false)
    }

    @Test("A value that does not decode says nothing either way")
    func unreadableValues() {
        #expect(SessionCookie.owner(ofValue: "abc") == .unreadable)
        #expect(SessionCookie.owner(ofValue: "") == .unreadable)
        // Base64 that is not JSON: `hello world`.
        #expect(SessionCookie.owner(ofValue: "aGVsbG8gd29ybGQ") == .unreadable)
        #expect(SessionCookie.namesAUser(["abc", ""]) == false)
    }

    @Test("An empty user is not a user")
    func emptyUserIsAnonymous() {
        // `{"user":"","timestamp":1}`
        let payload: String = Data(#"{"user":"","timestamp":1}"#.utf8).base64EncodedString()
        #expect(SessionCookie.owner(ofValue: payload) == .anonymous)
    }

    @Test("The signature cookie alongside it is not a payload, and is not mistaken for one")
    func signatureIsNotASession() {
        // The `.sig` cookie's value is a bare HMAC — no JSON, whether or not it happens to
        // decode as base64. It must never be what says somebody is signed in; the pair is read
        // together and it is the payload cookie that answers.
        #expect(SessionCookie.owner(ofValue: "cuCMaGQD6PYluiHJ7c-oZdxJG39Xgf1twwkbtjFOIrE") == .unreadable)
        #expect(SessionCookie.namesAUser(["cuCMaGQD6PYluiHJ7c-oZdxJG39Xgf1twwkbtjFOIrE"]) == false)
        // Together, the pair still answers "yes": one of the two names the user.
        #expect(
            SessionCookie.namesAUser([Self.userSession, "cuCMaGQD6PYluiHJ7c-oZdxJG39Xgf1twwkbtjFOIrE"])
        )
    }
}
