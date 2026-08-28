//
//  PostSignupSession.swift
//  ReCIT_iOS
//
//  What is left to do once inventaire.io has accepted a sign-up: nothing, or one sign-in.
//
//  Pure, and a type rather than an `if` inside the service, for one reason: **production never
//  takes the second branch on demand.** `POST /auth/signup` serialises the session itself and
//  sets the same two cookies a login sets, so the fallback is dead code every day until the day
//  it is not — and on that day it would be broken for every new user at once, silently, with the
//  only symptom being a sign-up that lands on the sign-in screen. A branch nobody can reach by
//  hand is a branch that has to be reachable from a test, and that is what pulling it out of the
//  service buys.
//
//  The rule itself is one line and deliberately reads on presence rather than on the status: a
//  `200` says the account exists, and it says nothing at all about whether we can act as it.
//
//  See PRD 0010 and issue 0057.
//

/// What the sign-up response leaves to do before the user is actually signed in.
enum PostSignupSession: Equatable, Sendable {

    /// The response carried the session cookies. The account is created and the user is in.
    case established

    /// It did not. Sign in with the credentials just typed, before handing back — anything else
    /// makes somebody retype the password they chose ten seconds ago.
    case chainSignIn

    /// What to do next.
    ///
    /// - Parameter hasSessionCookies: whether the jar now holds a usable session cookie, read
    ///   *after* the sign-up response was absorbed.
    static func next(hasSessionCookies: Bool) -> PostSignupSession {
        hasSessionCookies ? .established : .chainSignIn
    }
}
