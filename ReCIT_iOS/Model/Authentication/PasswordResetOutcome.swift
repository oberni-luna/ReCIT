//
//  PasswordResetOutcome.swift
//  ReCIT_iOS
//
//  What asking for a password-reset link can be worth: the request reached inventaire.io, or it
//  did not. Two outcomes, and **no third one** — there is deliberately no case for "that address
//  has an account" and none for "that address has none".
//
//  This type exists so that the rule the whole screen is built on stops being a discipline.
//
//  **The confirmation must not be an oracle.** It reads « si un compte existe pour cette
//  adresse… », never "email sent" and never "unknown address". Telling the two apart would turn
//  the screen into a way of asking "does this account exist?" about any address somebody cares
//  to type — you would run a list through it and read the answers off the screen.
//
//  And the server *is* an oracle. Its `reset-password` controller looks the address up, sends
//  the mail when it finds a user, and answers `400 { message: "email not found", email }` when
//  it does not — so a client that renders what it is told leaks exactly what must not leak. We
//  do not depend on the server changing its mind: `fromServer(status:serverMessage:)` reads
//  every answer, of every shape, and returns `.submitted` for all of them. The status and the
//  sentence are taken as parameters and dropped on purpose. That is the whole method, and it is
//  what makes "identical whether the address is known or not" a property a test can hold over
//  arbitrary inputs rather than a paragraph in a review.
//
//  The one thing that *is* told apart is a request that never completed. `.unreachable` is not
//  a statement about the address — it says the phone could not reach the server, and it says it
//  through `AuthFailure.network`, which is where every sentence this flow can show already
//  lives.
//
//  Pure, on the pattern of `PostSignupSession` and `FieldAvailability`: no `URLSession`, no
//  SwiftUI, no keychain.
//
//  See PRD 0010 and issue 0058.
//

import Foundation

enum PasswordResetOutcome: Equatable, Sendable {

    /// The request reached inventaire.io. Whatever it answered, the user reads one confirmation:
    /// *if* an account exists for this address, a link is on its way.
    case submitted

    /// The request never completed — no network, a dropped connection, a timeout. The only
    /// outcome that is not the confirmation, and it still says nothing about the address.
    case unreachable

    /// Reads the server's answer, and collapses it.
    ///
    /// Both parameters are accepted and neither is read, which is the point rather than an
    /// oversight: a `200` and the `400` that means "email not found" must be indistinguishable
    /// downstream, and the surest way to guarantee that is to have nothing downstream to
    /// distinguish them with.
    ///
    /// - Parameters:
    ///   - status: the HTTP status the server answered with.
    ///   - serverMessage: the `message` field of its body, if it had one. Never shown, and here
    ///     only so that no caller is tempted to read it somewhere this type cannot see.
    static func fromServer(status: Int, serverMessage: String?) -> PasswordResetOutcome {
        .submitted
    }

    /// The outcome of a request that never completed. Named rather than written as `.unreachable`
    /// at the call site so the asymmetry is legible: every server answer goes through
    /// `fromServer`, and this is the only other door into the type.
    static var transportFailure: PasswordResetOutcome {
        .unreachable
    }

    /// The failure this outcome stands for, or `nil` when there is nothing wrong.
    ///
    /// Routed through `AuthFailure` rather than owning a sentence of its own, so that the
    /// property asserted on that type — that no prose inventaire.io writes ever reaches a
    /// screen — keeps covering this path too.
    var failure: AuthFailure? {
        switch self {
        case .submitted: nil
        case .unreachable: .network
        }
    }

    /// What the user reads when the request did not go through, or `nil` when it did.
    var message: LocalizedStringResource? {
        failure?.message
    }

    /// The confirmation, with the address the user typed written into it — or `nil` when there
    /// is no confirmation to give.
    ///
    /// The address is interpolated because the sentence is about *that* address and a
    /// confirmation that does not name it is a confirmation nobody can check for a typo. It is
    /// the user's own text going back to the user; nothing the server said is in here.
    ///
    /// - Parameter address: what was typed into the field.
    func confirmation(for address: String) -> LocalizedStringResource? {
        switch self {
        case .submitted: "reset.sent.body \(address)"
        case .unreachable: nil
        }
    }
}
