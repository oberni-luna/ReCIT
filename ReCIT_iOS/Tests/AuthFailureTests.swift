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
//  Signing up (issue 0057) adds a second classifier, and its own reason to exist: a `400` from
//  `/auth/signup` names which of the three fields the server would not take, and that name is
//  the only thing that lets the screen put the error under the right box. The property above
//  covers those cases too — the sentence the server writes carries the *value* it rejected,
//  which for a password would be the password.
//
//  See PRD 0010 and issues 0056 and 0057.
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

    // MARK: - Classifying a sign-up

    @Test("A sign-up that worked is not a failure")
    func signupSuccessClassifiesToNothing() {
        #expect(AuthFailure.classifySignup(status: 200, errorName: nil, serverMessage: nil) == nil)
    }

    @Test("The server names the field it refused, and the name survives")
    func signupRefusalsAreAttributed() {
        // The shapes captured from the live endpoints: a malformed value carries `error_name`,
        // a taken one carries only its sentence.
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: "invalid_username",
                serverMessage: "invalid username: zz !! bad"
            ) == .usernameInvalid
        )
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: "invalid_email",
                serverMessage: "invalid email: not-an-email"
            ) == .emailInvalid
        )
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: "invalid_password",
                serverMessage: "invalid password: hunter2"
            ) == .passwordRejected
        )
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: nil,
                serverMessage: "this username is already used"
            ) == .usernameTaken
        )
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: nil,
                serverMessage: "this email is already used"
            ) == .emailTaken
        )
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: nil,
                serverMessage: "reserved words can't be usernames"
            ) == .usernameInvalid
        )
    }

    @Test("Each attributed failure knows which box it belongs under")
    func attributionPointsAtOneField() {
        #expect(AuthFailure.usernameTaken.signupField == .username)
        #expect(AuthFailure.usernameInvalid.signupField == .username)
        #expect(AuthFailure.emailTaken.signupField == .email)
        #expect(AuthFailure.emailInvalid.signupField == .email)
        #expect(AuthFailure.passwordRejected.signupField == .password)
    }

    @Test("A failure that belongs to no field claims none")
    func unattributableFailuresPointAtNothing() {
        #expect(AuthFailure.network.signupField == nil)
        #expect(AuthFailure.noSessionCookies.signupField == nil)
        #expect(AuthFailure.keychain(status: -25300).signupField == nil)
        #expect(AuthFailure.server(status: 500, serverMessage: nil).signupField == nil)
        #expect(AuthFailure.invalidCredentials.signupField == nil)
    }

    @Test("A 400 the sign-up classifier cannot attribute is not attributed anyway")
    func unrecognisedSignupRefusalsStayGeneric() {
        #expect(
            AuthFailure.classifySignup(
                status: 400,
                errorName: nil,
                serverMessage: "missing parameter in body: password"
            ) == .server(status: 400, serverMessage: "missing parameter in body: password")
        )
    }

    @Test("Statuses other than 400 mean the same on sign-up as anywhere else")
    func signupFallsBackToTheSharedClassifier() {
        #expect(
            AuthFailure.classifySignup(status: 401, errorName: nil, serverMessage: "nope")
                == .invalidCredentials
        )
        #expect(
            AuthFailure.classifySignup(status: 503, errorName: nil, serverMessage: "down")
                == .server(status: 503, serverMessage: "down")
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

        // The names the server attaches to a refusal, plus none at all.
        let errorNames: [String?] = [nil, "invalid_username", "invalid_email", "invalid_password"]

        for status in statuses {
            for serverMessage in serverMessages {
                var failures: [AuthFailure] = []
                if let failure = AuthFailure.classify(status: status, serverMessage: serverMessage) {
                    failures.append(failure)
                }
                for errorName in errorNames {
                    if let failure = AuthFailure.classifySignup(
                        status: status,
                        errorName: errorName,
                        serverMessage: serverMessage
                    ) {
                        failures.append(failure)
                    }
                }

                for failure in failures {
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
    }

    @Test("The five sign-up refusals each read differently")
    func signupRefusalsReadDifferently() {
        let shown: [String] = [
            AuthFailure.usernameTaken,
            .usernameInvalid,
            .emailTaken,
            .emailInvalid,
            .passwordRejected
        ].map { String(localized: $0.message) }

        #expect(Set(shown).count == shown.count)

        // And none of them falls back to the sentence that says nothing.
        let generic: String = String(localized: AuthFailure.server(status: 500, serverMessage: nil).message)
        #expect(shown.allSatisfy { $0 != generic })
    }

    @Test("A password the server refused never comes back out on screen")
    func aRejectedPasswordIsNotEchoed() {
        // `invalid password: <value>` is the shape the server writes, so the sentence it sends
        // *is* the password. Reaching a screen with it would be worse than unhelpful.
        let password: String = "correct-horse-battery-staple"
        let failure: AuthFailure? = .classifySignup(
            status: 400,
            errorName: "invalid_password",
            serverMessage: "invalid password: \(password)"
        )

        #expect(failure == .passwordRejected)
        #expect(!String(localized: AuthFailure.passwordRejected.message).contains(password))
    }

    @Test("The local failures say nothing of their own diagnostics either")
    func localFailuresHideTheirDiagnostics() {
        // An `OSStatus` is as meaningless to a reader as an English stack trace, and it used to
        // be printed into the message verbatim.
        let shown: String = String(localized: AuthFailure.keychain(status: -25300).message)

        #expect(!shown.contains("25300"))
    }
}
