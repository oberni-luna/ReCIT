//
//  AuthFailureTests.swift
//  ReCIT_iOSTests
//
//  The rule this whole flow rests on, asserted rather than trusted: inventaire.io answers its
//  errors with English prose written for a developer reading a log, and none of it may reach a
//  French screen.
//
//  Written as a property over adversarial inputs rather than over the three strings production
//  happens to send today. A suite that only checks "invalid password" never surfaces would pass
//  on the day someone adds an `unexpected(message:)` case whose description interpolates the
//  server's sentence — which is precisely the regression worth a suite.
//
//  Pure and network-free, like `OnboardingGateTests` and the sorting suites.
//
//  See PRD 0010 and issue 0056.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("AuthFailure")
struct AuthFailureTests {

    // MARK: - Classifying a status

    @Test("A success is not a failure")
    func successClassifiesToNothing() {
        #expect(AuthFailure.classify(status: 200, serverMessage: nil) == nil)
        #expect(AuthFailure.classify(status: 204, serverMessage: nil) == nil)
        #expect(AuthFailure.classify(status: 299, serverMessage: "loggedIn") == nil)
    }

    @Test("401 and 403 are the credentials being refused")
    func refusalsClassifyToInvalidCredentials() {
        #expect(
            AuthFailure.classify(status: 401, serverMessage: "invalid username or password")
                == .invalidCredentials
        )
        #expect(
            AuthFailure.classify(status: 403, serverMessage: "forbidden")
                == .invalidCredentials
        )
    }

    @Test("Everything else keeps its status and the server's own sentence")
    func otherStatusesClassifyToServer() {
        #expect(
            AuthFailure.classify(status: 400, serverMessage: "missing parameter: password")
                == .server(status: 400, serverMessage: "missing parameter: password")
        )
        #expect(
            AuthFailure.classify(status: 500, serverMessage: nil)
                == .server(status: 500, serverMessage: nil)
        )
        #expect(
            AuthFailure.classify(status: 502, serverMessage: "Bad Gateway")
                == .server(status: 502, serverMessage: "Bad Gateway")
        )
    }

    // MARK: - What the user is told

    @Test("A refusal and an unreachable server do not read the same")
    func refusalAndNetworkReadDifferently() {
        #expect(AuthFailure.invalidCredentials.message.key != AuthFailure.network.message.key)
        #expect(
            String(localized: AuthFailure.invalidCredentials.message)
                != String(localized: AuthFailure.network.message)
        )
    }

    @Test("Everything the user cannot act on falls to the one generic sentence")
    func unactionableFailuresShareOneMessage() {
        let generic: String = String(localized: AuthFailure.server(status: 500, serverMessage: nil).message)

        #expect(String(localized: AuthFailure.noSessionCookies.message) == generic)
        #expect(String(localized: AuthFailure.keychain(status: -25300).message) == generic)
        #expect(
            String(localized: AuthFailure.server(status: 418, serverMessage: "I'm a teapot").message)
                == generic
        )
    }

    // MARK: - The property

    @Test("No status, and no sentence the server can write, ever reaches the screen")
    func theServerSMessageIsNeverShown() {
        // Sentences shaped like the ones inventaire.io actually sends, plus a couple chosen to
        // fail loudly if anything ever interpolates the value into the copy.
        let serverMessages: [String] = [
            "invalid username or password",
            "missing parameter: password",
            "Bad Gateway",
            "user not found",
            "SOMETHING WENT WRONG ON THE SERVER"
        ]
        let statuses: [Int] = [200, 201, 204, 301, 400, 401, 403, 404, 409, 418, 429, 500, 502, 503]

        for status in statuses {
            for serverMessage in serverMessages {
                guard let failure = AuthFailure.classify(status: status, serverMessage: serverMessage) else {
                    continue
                }

                let shown: String = String(localized: failure.message)

                #expect(
                    !shown.localizedStandardContains(serverMessage),
                    "status \(status) surfaced the server's sentence: \(shown)"
                )
                #expect(
                    !shown.contains(String(status)),
                    "status \(status) surfaced its own status code: \(shown)"
                )
            }
        }
    }

    @Test("The local failures say nothing of their own diagnostics either")
    func localFailuresHideTheirDiagnostics() {
        // An `OSStatus` is as meaningless to a reader as an English stack trace, and it used to
        // be printed into the message verbatim.
        let shown: String = String(localized: AuthFailure.keychain(status: -25300).message)

        #expect(!shown.contains("25300"))
    }
}
