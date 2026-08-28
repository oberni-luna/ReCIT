//
//  PasswordResetOutcomeTests.swift
//  ReCIT_iOSTests
//
//  The rule the reset screen exists to keep, asserted rather than reviewed: the confirmation
//  must not be an oracle.
//
//  The server *is* one. `POST /auth/reset-password` mails the link when it finds a user and
//  answers `400 { message: "email not found", email }` when it does not — so "the two cases look
//  the same" is a property of this app, not a property of inventaire.io, and the only way to
//  keep it is to have nothing downstream that can tell them apart.
//
//  So the suite is written as a property over adversarial inputs rather than over the two
//  answers production sends today. A test that checked `200 → .submitted` and `400 → .submitted`
//  would still pass on the day somebody adds a `notFound` case, which is precisely the
//  regression worth a suite.
//
//  Pure and network-free, like `AuthFailureTests` and `PostSignupSessionTests`.
//
//  See PRD 0010 and issue 0058.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("PasswordResetOutcome")
struct PasswordResetOutcomeTests {

    /// Every status this endpoint could plausibly answer, and a few it never will.
    private static let statuses: [Int] = [
        0, 200, 201, 204, 301, 400, 401, 403, 404, 409, 418, 429, 500, 502, 503
    ]

    /// Sentences shaped like the ones inventaire.io actually writes, plus a couple chosen to
    /// fail loudly if anything ever interpolated one into the copy. The first two are the whole
    /// problem: they are the server saying which of the two cases this is.
    private static let serverMessages: [String?] = [
        nil,
        "email not found",
        "this email is already used",
        "invalid email: nope",
        "Bad Gateway",
        "NO ACCOUNT EXISTS FOR THIS ADDRESS"
    ]

    // MARK: - Collapsing every answer

    @Test("A 200 and a 400 that means 'no such address' are the same outcome")
    func theTwoAnswersProductionSendsAreIndistinguishable() {
        let accepted: PasswordResetOutcome = .fromServer(status: 200, serverMessage: nil)
        let refused: PasswordResetOutcome = .fromServer(status: 400, serverMessage: "email not found")

        #expect(accepted == refused)
        #expect(accepted == .submitted)
    }

    @Test("No status and no sentence the server can send produces anything but the confirmation")
    func everyServerAnswerCollapses() {
        for status in Self.statuses {
            for serverMessage in Self.serverMessages {
                #expect(
                    PasswordResetOutcome.fromServer(status: status, serverMessage: serverMessage)
                        == .submitted,
                    "status \(status) with message \(serverMessage ?? "nil") did not collapse"
                )
            }
        }
    }

    @Test("Only a request that never completed is told apart")
    func aTransportFailureIsTheOneDistinguishableOutcome() {
        #expect(PasswordResetOutcome.transportFailure == .unreachable)
        #expect(PasswordResetOutcome.transportFailure != .submitted)
    }

    // MARK: - What the user reads

    @Test("The confirmation depends on the address and on nothing else")
    func theConfirmationIsTheSameWhicheverAnswerCameBack() throws {
        let address: String = "alice@example.org"

        var confirmations: Set<String> = []
        for status in Self.statuses {
            for serverMessage in Self.serverMessages {
                let outcome: PasswordResetOutcome = .fromServer(
                    status: status,
                    serverMessage: serverMessage
                )
                let sentence: LocalizedStringResource = try #require(outcome.confirmation(for: address))
                confirmations.insert(String(localized: sentence))
            }
        }

        // One sentence for every answer the server can give. Two would be an oracle.
        #expect(confirmations.count == 1)
    }

    @Test("The confirmation names the address back, and says 'if'")
    func theConfirmationIsConditionalAndNamesTheAddress() throws {
        let address: String = "alice@example.org"
        let sentence: String = String(
            localized: try #require(PasswordResetOutcome.submitted.confirmation(for: address))
        )

        #expect(sentence.contains(address))
        // The conditional is the whole point of the sentence: it must not read as a statement
        // that an account was found, in either language the app ships.
        #expect(sentence.localizedStandardContains("if") || sentence.localizedStandardContains("si"))
    }

    @Test("A request that never completed has no confirmation to give")
    func anUnreachableServerConfirmsNothing() {
        #expect(PasswordResetOutcome.unreachable.confirmation(for: "alice@example.org") == nil)
    }

    @Test("A network failure reads as a network failure, and says nothing about the address")
    func anUnreachableServerReadsAsANetworkFailure() throws {
        let address: String = "alice@example.org"
        let outcome: PasswordResetOutcome = .unreachable

        #expect(outcome.failure == .network)

        let shown: String = String(localized: try #require(outcome.message))
        #expect(shown == String(localized: AuthFailure.network.message))
        #expect(!shown.contains(address))
        #expect(!shown.localizedStandardContains("account"))
        #expect(!shown.localizedStandardContains("compte"))
    }

    @Test("The confirmation has nothing to say about a failure, and the failure has no confirmation")
    func theTwoOutcomesDoNotShareASentence() {
        #expect(PasswordResetOutcome.submitted.failure == nil)
        #expect(PasswordResetOutcome.submitted.message == nil)
    }

    // MARK: - The property

    @Test("No sentence the server can write reaches the user from this path")
    func theServerSMessageIsNeverShown() {
        // The address is in the loop too: `email not found` comes back with the address the user
        // typed attached, so a sentence that echoed the server would echo it inside a claim
        // about whether the account exists.
        let address: String = "alice@example.org"

        for status in Self.statuses {
            for serverMessage in Self.serverMessages {
                let outcome: PasswordResetOutcome = .fromServer(
                    status: status,
                    serverMessage: serverMessage
                )

                var shown: [String] = []
                if let confirmation = outcome.confirmation(for: address) {
                    shown.append(String(localized: confirmation))
                }
                if let message = outcome.message {
                    shown.append(String(localized: message))
                }

                for sentence in shown {
                    if let serverMessage {
                        #expect(
                            !sentence.localizedStandardContains(serverMessage),
                            "status \(status) surfaced the server's sentence: \(sentence)"
                        )
                    }
                    #expect(
                        !sentence.contains(String(status)),
                        "status \(status) surfaced its own status code: \(sentence)"
                    )
                }
            }
        }
    }
}
