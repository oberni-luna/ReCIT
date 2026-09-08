//
//  SessionExpiryTests.swift
//  ReCIT_iOSTests
//
//  Pure, no network: the one question `SessionExpiry` answers, and the three answers that must
//  stay "no".
//
//  The case worth the file is `403`. Signing the user out is the cure for a session the server
//  does not recognise, and only for that — applied to a permission the account does not have,
//  it would throw the user onto the login screen for something logging in again cannot fix.
//
//  See issue 0068.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("SessionExpiry")
struct SessionExpiryTests {

    @Test("A 401 is a session the server no longer honours")
    func unauthorizedIsAGoneSession() {
        let error: NetworkError = .badStatus(code: 401, message: "unauthorized api access")

        #expect(SessionExpiry.isSessionGone(error))
    }

    @Test("A 403 is not: it is a session the server recognised and a thing it refused")
    func forbiddenIsNotAGoneSession() {
        #expect(SessionExpiry.isSessionGone(NetworkError.badStatus(code: 403, message: nil)) == false)
    }

    @Test("Neither is a server that broke, nor a phone with no network")
    func otherFailuresAreNotGoneSessions() {
        #expect(SessionExpiry.isSessionGone(NetworkError.badStatus(code: 500, message: nil)) == false)
        #expect(SessionExpiry.isSessionGone(NetworkError.badResponse) == false)
        #expect(SessionExpiry.isSessionGone(NetworkError.transport(underlying: URLError(.timedOut))) == false)
        #expect(SessionExpiry.isSessionGone(URLError(.notConnectedToInternet)) == false)
    }
}
