//
//  AuthDestination.swift
//  ReCIT_iOS
//
//  Where the signed-out branch of the app can go: four screens, and that is the whole map.
//
//  Its own enum rather than `NavigationDestination`, which carries SwiftData payloads and
//  describes the authenticated entity browser — a signed-out user has no store to point at, and
//  a destination type that can only be built from `@Model` values has nothing to offer here.
//
//  All four are reached by **assigning** the path, never by appending to it, so the stack never
//  grows past one level. The reset confirmation is a destination like the others rather than a
//  state inside the form for the same reason the sign-up screen is not a mode of the sign-in
//  one: it is a different screen with a different job, and the way out of it is forward, to
//  signing in, not backwards to the box you just emptied.
//
//  See PRD 0010 and issues 0056 and 0058.
//

enum AuthDestination: Hashable, Sendable {

    /// The form: a username, a password, and a way in.
    case signIn

    /// Account creation: three fields, checked live, and a session at the end of them.
    case createAccount

    /// One address, and a link on its way to it.
    case forgotPassword

    /// The confirmation. It carries the address so the sentence can name it back — and that is
    /// the only thing this payload is for: nothing about whether an account was found travels
    /// with it, because nothing about that is ever known here.
    case passwordResetSent(address: String)
}
