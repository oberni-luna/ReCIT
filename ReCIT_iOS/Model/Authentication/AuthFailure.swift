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
//  Signing up adds five more, and they are the exception that proves that rule: each one *is*
//  actionable, and each one belongs to exactly one of the three fields. The sign-in screen shows
//  its failure once, under both fields, because a refused password is not attributable; the
//  sign-up screen shows its failures under the field that caused them, because they are. That
//  attribution is `signupField`, and it is a property of this type rather than a guess the view
//  makes from the sentence it was handed.
//
//  See PRD 0010 and issues 0056 and 0057.
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

    /// Somebody already has this username.
    case usernameTaken

    /// The server would not accept the shape of this username. What is wrong with it is not
    /// spelled out on purpose: the naming rules live on the server, the availability endpoint
    /// enforces them, and a client that restates them is a client that will be wrong one day.
    case usernameInvalid

    /// An account already exists for this address.
    case emailTaken

    /// The server would not accept the shape of this address.
    case emailInvalid

    /// The server refused the password. Its own case rather than a generic failure because of
    /// where it lands: iOS offers to generate a strong password on this screen, and somebody
    /// whose *phone* chose the password has no way to make sense of "something went wrong".
    case passwordRejected

    /// Any other refusal from the server. `serverMessage` is the server's own English prose:
    /// kept for logs and for a debugger, never shown.
    case server(status: Int, serverMessage: String?)

    /// Which sign-up field a failure belongs under, when it belongs under one.
    enum SignupField: Equatable, Sendable {
        case username
        case email
        case password
    }

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

    /// The failure a **sign-up** status stands for, or `nil` when the status is a success.
    ///
    /// A second classifier rather than a flag on the first, because the two endpoints do not
    /// answer the same alphabet. A `400` from `/auth/login` is a malformed request nobody can
    /// act on; a `400` from `/auth/signup` is the server naming which of the three fields it
    /// would not take, and throwing that away is throwing away the only thing that lets the
    /// screen point at the right box.
    ///
    /// It reads `error_name` first, which the server sets for every shape refusal, and falls
    /// back to matching the sentence as a token for the ones it does not set — a name already
    /// taken carries no `error_name` at all. Neither string goes any further than this method.
    ///
    /// - Parameters:
    ///   - status: the HTTP status the server answered with.
    ///   - errorName: the `error_name` field of the error body, if it had one.
    ///   - serverMessage: the `message` field of the error body, if it had one.
    static func classifySignup(
        status: Int,
        errorName: String?,
        serverMessage: String?
    ) -> AuthFailure? {
        guard !(200..<300).contains(status) else { return nil }

        guard status == 400 else {
            return classify(status: status, serverMessage: serverMessage)
        }

        switch errorName {
        case "invalid_username": return .usernameInvalid
        case "invalid_email": return .emailInvalid
        case "invalid_password": return .passwordRejected
        default: break
        }

        if let serverMessage {
            // Protocol strings, matched with `contains`: this is the server talking to us, not a
            // person typing, so the localised comparison the project uses on user input is the
            // wrong tool.
            if serverMessage.contains("username is already used") { return .usernameTaken }
            if serverMessage.contains("email is already used") { return .emailTaken }
            if serverMessage.contains("reserved word") { return .usernameInvalid }
        }

        return .server(status: status, serverMessage: serverMessage)
    }

    /// The sign-up field this failure belongs under, or `nil` when it belongs to none of them
    /// and has to be said once for the whole form.
    var signupField: SignupField? {
        switch self {
        case .usernameTaken, .usernameInvalid: .username
        case .emailTaken, .emailInvalid: .email
        case .passwordRejected: .password
        case .invalidCredentials, .network, .noSessionCookies, .keychain, .server: nil
        }
    }

    /// What the user reads. A catalogue resource in every case — there is no branch of this
    /// property that can return a string the server wrote, which is the whole point.
    var message: LocalizedStringResource {
        switch self {
        case .invalidCredentials:
            "auth.error.invalid_credentials"
        case .network:
            "auth.error.network"
        case .usernameTaken:
            "signup.error.username_taken"
        case .usernameInvalid:
            "signup.error.username_invalid"
        case .emailTaken:
            "signup.error.email_taken"
        case .emailInvalid:
            "signup.error.email_invalid"
        case .passwordRejected:
            "signup.error.password_rejected"
        case .noSessionCookies, .keychain, .server:
            "auth.error.generic"
        }
    }
}
