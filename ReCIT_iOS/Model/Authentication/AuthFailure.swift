//
//  AuthFailure.swift
//  ReCIT_iOS
//
//  Why signing in, or signing out, did not work — and what the user is told about it.
//
//  Pure: no `URLSession`, no SwiftUI, no keychain, on the pattern of `OnboardingGate` and the
//  `Model/Sorting/` types. It takes an HTTP status and the sentence the server wrote, and hands
//  back one of our own cases. That makes the rule this feature is built on a **property of a
//  type** instead of a discipline: inventaire.io answers `{ status, message }` where `message`
//  is English prose written for a developer reading a log, and none of it may reach a French
//  screen.
//
//  The server's sentence is still carried — in `server(serverMessage:)` — because an error value
//  that drops it is an error value nobody can debug. What it is never allowed to do is come back
//  out of `message`, and that is what the suite asserts over arbitrary inputs rather than over
//  the three strings production happens to send today.
//
//  Only two failures are told apart on screen, and deliberately: wrong credentials, which the
//  user fixes by typing again, and an unreachable server, which they fix by finding a network.
//  Everything else is one sentence — a user cannot act on the difference between a 500 and a
//  502, and pretending otherwise means writing copy for statuses nobody has ever seen.
//
//  See PRD 0010 and issue 0056.
//

import Foundation

enum AuthFailure: Error, Equatable, Sendable {

    /// The server refused the username and password it was given.
    case invalidCredentials

    /// The request never completed: no network, a dropped connection, a timeout.
    case network

    /// The server answered `2xx` but set none of the session cookies we sign in with. Not a
    /// refusal — the credentials were accepted — so it reads as a generic failure rather than
    /// sending the user back to re-check a password that was right.
    case noSessionCookies

    /// The session was obtained but could not be written to the keychain, so it would not
    /// survive the next launch. `status` is an `OSStatus`, kept as its underlying `Int32` so
    /// this type owes nothing to `Security`.
    case keychain(status: Int32)

    /// Any other refusal from the server. `serverMessage` is the server's own English prose:
    /// kept for logs and for a debugger, never shown.
    case server(status: Int, serverMessage: String?)

    /// The failure an HTTP status stands for, or `nil` when the status is a success.
    ///
    /// Returning an optional rather than taking "is this a failure?" as a precondition means a
    /// caller asks one question instead of two, and cannot ask them in the wrong order.
    ///
    /// - Parameters:
    ///   - status: the HTTP status code the server answered with.
    ///   - serverMessage: the `message` field of the server's error body, if it had one.
    static func classify(status: Int, serverMessage: String?) -> AuthFailure? {
        guard !(200..<300).contains(status) else { return nil }

        // 401 is what inventaire.io answers a wrong password; 403 covers an account the server
        // will not open a session for. Both are "the credentials you gave are not usable",
        // which is the one thing the user can do something about.
        if status == 401 || status == 403 {
            return .invalidCredentials
        }

        return .server(status: status, serverMessage: serverMessage)
    }

    /// What the user reads. A catalogue resource in every case — there is no branch of this
    /// property that can return a string the server wrote, which is the whole point.
    var message: LocalizedStringResource {
        switch self {
        case .invalidCredentials:
            "auth.error.invalid_credentials"
        case .network:
            "auth.error.network"
        case .noSessionCookies, .keychain, .server:
            "auth.error.generic"
        }
    }
}
