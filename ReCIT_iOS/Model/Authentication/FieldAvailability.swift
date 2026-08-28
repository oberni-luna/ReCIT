//
//  FieldAvailability.swift
//  ReCIT_iOS
//
//  What a live-checked sign-up field is worth while it is being typed: empty, being checked,
//  free, taken, malformed, or unknown because the check itself did not come back.
//
//  Pure, on the pattern of `OnboardingGate` and the `Model/Sorting/` types: no SwiftUI, no
//  `URLSession`, no keychain. The screen **renders** one of these states and derives none of
//  them — a view that decides for itself whether a name is free is a view that will disagree
//  with the one that asked the server.
//
//  Two things this type exists for, and neither is the happy path.
//
//  **Staleness.** A check is a round trip and typing is not. Ask about "oliv", keep typing, and
//  the answer for "oliv" lands on a field that now reads "olivier" — painting it would tell the
//  user something true about a name they no longer want. So an answer carries the text it was
//  asked about, and one that no longer matches is dropped on the floor. That is the case the
//  suite holds, because it is the one production produces every single time somebody types fast.
//
//  **The server's own rules.** `/auth/username-availability` answers "valid *and* available", so
//  the shape of a username is checked by the only thing that actually knows it. Nothing here
//  restates a naming rule, and nothing here has to be revisited the day inventaire.io changes
//  one. `Outcome.from(status:errorName:serverMessage:)` reads the server's answer as a machine
//  token — an `error_name`, a known phrase — and the prose itself goes no further: what the user
//  reads always comes back through `AuthFailure`, which owns every sentence this flow can show.
//
//  See PRD 0010 and issue 0057.
//

import Foundation

struct FieldAvailability: Equatable, Sendable {

    /// Which of the two live-checked fields this is. It selects the sentence, nothing else —
    /// the two endpoints answer in the same shapes.
    enum Field: Equatable, Sendable {
        case username
        case email
    }

    /// What the field is worth right now.
    enum State: Equatable, Sendable {
        /// Nothing typed yet, or nothing but whitespace. Not an error: a form the user has not
        /// filled in is not a form the user got wrong.
        case empty

        /// Something is typed and the answer for it is not in yet.
        case checking

        /// The server said this one is both well formed and free.
        case available

        /// Somebody already has it.
        case taken

        /// The server would not accept this shape.
        case invalid

        /// The check did not come back — no network, a rate limit, a status nobody planned for.
        /// Deliberately silent on screen and deliberately not `invalid`: the user has done
        /// nothing wrong, and submitting is still the right thing to try.
        case undetermined
    }

    /// What one availability check answered. The service maps HTTP into this and hands it over;
    /// the mapping itself is here so it can be tested without a socket.
    enum Outcome: Equatable, Sendable {
        case available
        case taken
        case invalid
        case undetermined

        /// Reads one availability response.
        ///
        /// Both endpoints answer `200 { status: "available" }` or `400 { status, message,
        /// error_name }`. A malformed value carries `error_name: "invalid_username"`; a value
        /// somebody already has carries no `error_name` at all and only the sentence "this
        /// username is already used" — so the sentence is matched, as a token, and never shown.
        ///
        /// Anything else, `429` included, is `undetermined` rather than a refusal: the field is
        /// not wrong, we simply do not know.
        ///
        /// - Parameters:
        ///   - status: the HTTP status the server answered with.
        ///   - errorName: the `error_name` field of the error body, when it had one.
        ///   - serverMessage: the `message` field of the error body, when it had one.
        static func from(status: Int, errorName: String?, serverMessage: String?) -> Outcome {
            if (200..<300).contains(status) { return .available }

            guard status == 400 else { return .undetermined }

            if let errorName, errorName.hasPrefix("invalid_") { return .invalid }

            guard let serverMessage else { return .undetermined }

            // Machine tokens, matched with `contains` on purpose: this is a protocol string the
            // server wrote, not text a person typed, so the localised comparison the project
            // uses on user input would be the wrong tool here.
            if serverMessage.contains("already used") { return .taken }
            if serverMessage.contains("reserved word") { return .invalid }
            if serverMessage.hasPrefix("invalid ") { return .invalid }

            return .undetermined
        }
    }

    let field: Field

    /// The text the current state describes. Held so an answer can be checked against it.
    private(set) var text: String = ""

    private(set) var state: State = .empty

    init(field: Field) {
        self.field = field
    }

    /// The text a check still owes an answer for, or `nil` when none is outstanding.
    var pendingQuery: String? {
        state == .checking ? text : nil
    }

    /// Whether this field is known to be usable. `undetermined` is not: it is not known to be
    /// anything.
    var isAvailable: Bool {
        state == .available
    }

    /// Whether the server has said no to what is typed. What the submit button is gated on
    /// alongside emptiness — and `undetermined` is deliberately not part of it: a check that did
    /// not come back must never be the reason somebody cannot create their account.
    var isRefused: Bool {
        state == .taken || state == .invalid
    }

    /// Whether the field has been filled in at all. What the submit button is gated on — an
    /// empty field is worth one wasted request against an endpoint that allows five in ten
    /// seconds.
    var isFilled: Bool {
        state != .empty
    }

    /// The failure this state stands for, or `nil` when there is nothing to say. Routed through
    /// `AuthFailure` rather than owning sentences of its own so that every sentence this flow can
    /// show has exactly one owner — and so the property that no server prose ever reaches a
    /// screen keeps covering these three cases too.
    var failure: AuthFailure? {
        switch (field, state) {
        case (.username, .taken): .usernameTaken
        case (.username, .invalid): .usernameInvalid
        case (.email, .taken): .emailTaken
        case (.email, .invalid): .emailInvalid
        default: nil
        }
    }

    /// What the user reads under the field, or `nil` when the field says nothing.
    var message: LocalizedStringResource? {
        failure?.message
    }

    /// The user typed. Whitespace alone is empty — a space is not a username in progress.
    ///
    /// Re-setting the same text is a no-op, which is what lets the screen call this from a task
    /// keyed on the text without knocking a settled answer back to `checking` every time the
    /// view is rebuilt.
    mutating func edited(to newText: String) {
        guard newText != text else { return }

        text = newText
        state = newText.allSatisfy(\.isWhitespace) ? .empty : .checking
    }

    /// Files the answer to a check — **if** it is still the answer to the question on screen.
    ///
    /// - Parameters:
    ///   - outcome: what the check said.
    ///   - query: the text that check was asked about. An answer for anything other than the
    ///     current text is dropped, which is the whole reason this method takes it.
    mutating func apply(_ outcome: Outcome, for query: String) {
        guard query == text else { return }
        guard state != .empty else { return }

        switch outcome {
        case .available: state = .available
        case .taken: state = .taken
        case .invalid: state = .invalid
        case .undetermined: state = .undetermined
        }
    }
}
