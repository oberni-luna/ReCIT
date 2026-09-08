//
//  AuthDestination.swift
//  ReCIT_iOS
//
//  Where the signed-out branch of the app can go: two screens, and that is the whole map.
//
//  Its own enum rather than `NavigationDestination`, which carries SwiftData payloads and
//  describes the authenticated entity browser — a signed-out user has no store to point at, and
//  a destination type that can only be built from `@Model` values has nothing to offer here.
//
//  Both are reached by **assigning** the path, never by appending to it, so the stack never grows
//  past one level, and neither is a step towards the other: they are the two doors off the
//  welcome screen.
//
//  Asking for a reset link is deliberately **not** here (issue 0059). It was two cases once — the
//  form and its confirmation — and it is now a sheet over « Se connecter » plus a snackbar. What
//  a user can pull down and hand back is an errand, not a destination, and modelling it as one
//  put a screen behind the chevron that nobody had asked to be on.
//
//  See PRD 0010 and issues 0056, 0058 and 0059.
//

enum AuthDestination: Hashable, Sendable {

    /// The form: a username, a password, and a way in.
    case signIn

    /// Account creation: three fields, checked live, and a session at the end of them.
    case createAccount
}
