//
//  FieldAvailabilityTests.swift
//  ReCIT_iOSTests
//
//  What a live-checked sign-up field is worth while it is being typed, and above all what it is
//  worth when an answer arrives too late to be about anything.
//
//  Pure and network-free, like `OnboardingGateTests`, `AuthFailureTests` and the sorting suites.
//  Every test here reads the type from the outside — text goes in, a state and a sentence come
//  out — and none of them knows how it stores either.
//
//  See PRD 0010 and issue 0057.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("FieldAvailability")
struct FieldAvailabilityTests {

    // MARK: - Typing

    @Test("A field nobody has touched says nothing and asks nothing")
    func startsEmpty() {
        let field: FieldAvailability = .init(field: .username)

        #expect(field.state == .empty)
        #expect(field.isFilled == false)
        #expect(field.isAvailable == false)
        #expect(field.isRefused == false)
        #expect(field.message == nil)
        #expect(field.pendingQuery == nil)
    }

    @Test("Typing puts a check out for exactly what was typed")
    func typingAsksAQuestion() {
        var field: FieldAvailability = .init(field: .username)

        field.edited(to: "olivier")

        #expect(field.state == .checking)
        #expect(field.pendingQuery == "olivier")
        // Nothing is said while we do not know. A field is not wrong for being unanswered.
        #expect(field.message == nil)
    }

    @Test("Whitespace is not a username in progress")
    func whitespaceIsEmpty() {
        var field: FieldAvailability = .init(field: .username)

        field.edited(to: "   ")

        #expect(field.state == .empty)
        #expect(field.isFilled == false)
        #expect(field.pendingQuery == nil)
    }

    @Test("Clearing a field that had an answer takes the answer away with it")
    func clearingForgetsTheAnswer() {
        var field: FieldAvailability = .init(field: .username)

        field.edited(to: "olivier")
        field.apply(.taken, for: "olivier")
        #expect(field.isRefused)

        field.edited(to: "")

        #expect(field.state == .empty)
        #expect(field.message == nil)
        #expect(field.isRefused == false)
    }

    @Test("Retyping the same text does not throw away the answer we already have")
    func idempotentEdits() {
        var field: FieldAvailability = .init(field: .username)

        field.edited(to: "olivier")
        field.apply(.available, for: "olivier")
        field.edited(to: "olivier")

        #expect(field.state == .available)
        #expect(field.pendingQuery == nil)
    }

    // MARK: - Answers

    @Test("Each answer lands as the state it stands for")
    func answersLand() {
        for (outcome, expected) in [
            (FieldAvailability.Outcome.available, FieldAvailability.State.available),
            (.taken, .taken),
            (.invalid, .invalid),
            (.undetermined, .undetermined)
        ] {
            var field: FieldAvailability = .init(field: .username)
            field.edited(to: "olivier")
            field.apply(outcome, for: "olivier")

            #expect(field.state == expected)
        }
    }

    @Test("Only a free field is a usable one, and only a refused one holds the form back")
    func gatesReadTheRightStates() {
        var free: FieldAvailability = .init(field: .username)
        free.edited(to: "olivier")
        free.apply(.available, for: "olivier")
        #expect(free.isAvailable)
        #expect(free.isRefused == false)

        var taken: FieldAvailability = .init(field: .username)
        taken.edited(to: "olivier")
        taken.apply(.taken, for: "olivier")
        #expect(taken.isRefused)
        #expect(taken.isAvailable == false)

        // The one that matters: a check that did not come back must never be the reason
        // somebody cannot create their account.
        var unknown: FieldAvailability = .init(field: .username)
        unknown.edited(to: "olivier")
        unknown.apply(.undetermined, for: "olivier")
        #expect(unknown.isRefused == false)
        #expect(unknown.isFilled)
        #expect(unknown.message == nil)
    }

    // MARK: - The stale answer

    @Test("An answer for what the field used to say never paints what it says now")
    func staleAnswersAreDropped() {
        var field: FieldAvailability = .init(field: .username)

        field.edited(to: "oliv")
        // The user kept typing while "oliv" was in flight.
        field.edited(to: "olivier")

        field.apply(.taken, for: "oliv")

        // Still waiting on its own answer, and still saying nothing about a name it does not
        // describe.
        #expect(field.state == .checking)
        #expect(field.pendingQuery == "olivier")
        #expect(field.message == nil)
    }

    @Test("The late answer loses even when it arrives after the current one")
    func aLateAnswerCannotOverwriteAFreshOne() {
        var field: FieldAvailability = .init(field: .username)

        field.edited(to: "oliv")
        field.edited(to: "olivier")
        field.apply(.available, for: "olivier")

        // "oliv" finally comes back, long after anybody cared.
        field.apply(.taken, for: "oliv")

        #expect(field.state == .available)
        #expect(field.message == nil)
    }

    @Test("An answer that arrives after the field was emptied says nothing")
    func anAnswerForAnEmptiedFieldIsDropped() {
        var field: FieldAvailability = .init(field: .email)

        field.edited(to: "someone@example.org")
        field.edited(to: "")
        field.apply(.taken, for: "someone@example.org")

        #expect(field.state == .empty)
        #expect(field.message == nil)
    }

    // MARK: - What the field says

    @Test("The two fields do not complain in the same words")
    func eachFieldHasItsOwnSentences() throws {
        var username: FieldAvailability = .init(field: .username)
        username.edited(to: "olivier")
        username.apply(.taken, for: "olivier")

        var email: FieldAvailability = .init(field: .email)
        email.edited(to: "someone@example.org")
        email.apply(.taken, for: "someone@example.org")

        let usernameMessage: LocalizedStringResource = try #require(username.message)
        let emailMessage: LocalizedStringResource = try #require(email.message)

        #expect(String(localized: usernameMessage) != String(localized: emailMessage))
        #expect(username.failure == .usernameTaken)
        #expect(email.failure == .emailTaken)
    }

    @Test("A malformed value reads as malformed, not as taken")
    func invalidIsItsOwnSentence() throws {
        var email: FieldAvailability = .init(field: .email)
        email.edited(to: "not-an-email")
        email.apply(.invalid, for: "not-an-email")

        #expect(email.failure == .emailInvalid)

        var taken: FieldAvailability = .init(field: .email)
        taken.edited(to: "someone@example.org")
        taken.apply(.taken, for: "someone@example.org")

        let invalidMessage: LocalizedStringResource = try #require(email.message)
        let takenMessage: LocalizedStringResource = try #require(taken.message)
        #expect(String(localized: invalidMessage) != String(localized: takenMessage))
    }

    // MARK: - Reading the server's answer

    @Test("A 200 is a free field")
    func successIsAvailable() {
        #expect(
            FieldAvailability.Outcome.from(status: 200, errorName: nil, serverMessage: nil)
                == .available
        )
    }

    @Test("The shapes inventaire.io actually answers with are read correctly")
    func the400sAreToldApart() {
        // Captured from the live endpoints: a taken value carries no `error_name` at all, only
        // its sentence; a malformed one carries both.
        #expect(
            FieldAvailability.Outcome.from(
                status: 400,
                errorName: nil,
                serverMessage: "this username is already used"
            ) == .taken
        )
        #expect(
            FieldAvailability.Outcome.from(
                status: 400,
                errorName: nil,
                serverMessage: "this email is already used"
            ) == .taken
        )
        #expect(
            FieldAvailability.Outcome.from(
                status: 400,
                errorName: "invalid_username",
                serverMessage: "invalid username: zz !! bad"
            ) == .invalid
        )
        #expect(
            FieldAvailability.Outcome.from(
                status: 400,
                errorName: "invalid_email",
                serverMessage: "invalid email: not-an-email"
            ) == .invalid
        )
        #expect(
            FieldAvailability.Outcome.from(
                status: 400,
                errorName: nil,
                serverMessage: "reserved words can't be usernames"
            ) == .invalid
        )
    }

    @Test("Anything we cannot read is 'we do not know', never 'you got it wrong'")
    func theUnknownIsNotARefusal() {
        // A rate limit is the one that would hurt: the endpoints answer 429 to a fast typist,
        // and reading that as a refusal would tell somebody their own name is taken.
        #expect(
            FieldAvailability.Outcome.from(status: 429, errorName: nil, serverMessage: "too many requests")
                == .undetermined
        )
        #expect(
            FieldAvailability.Outcome.from(status: 500, errorName: nil, serverMessage: nil)
                == .undetermined
        )
        #expect(
            FieldAvailability.Outcome.from(status: 400, errorName: nil, serverMessage: nil)
                == .undetermined
        )
        #expect(
            FieldAvailability.Outcome.from(status: 400, errorName: nil, serverMessage: "something else entirely")
                == .undetermined
        )
    }

    @Test("No sentence the server can write ever reaches the field")
    func theServerSProseIsNeverShown() {
        let serverMessages: [String] = [
            "this username is already used",
            "this email is already used",
            "invalid username: zz !! bad",
            "invalid email: not-an-email",
            "reserved words can't be usernames",
            "SOMETHING WENT WRONG ON THE SERVER"
        ]
        let statuses: [Int] = [200, 400, 401, 429, 500, 503]

        for status in statuses {
            for serverMessage in serverMessages {
                let outcome: FieldAvailability.Outcome = .from(
                    status: status,
                    errorName: nil,
                    serverMessage: serverMessage
                )

                for field in [FieldAvailability.Field.username, .email] {
                    var availability: FieldAvailability = .init(field: field)
                    availability.edited(to: "candidate")
                    availability.apply(outcome, for: "candidate")

                    guard let message = availability.message else { continue }

                    let shown: String = String(localized: message)
                    #expect(
                        !shown.contains(serverMessage),
                        "status \(status) surfaced the server's sentence: \(shown)"
                    )
                }
            }
        }
    }
}
