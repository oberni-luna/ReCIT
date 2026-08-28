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
//  See PRD 0010 and issue 0056.
//

enum AuthDestination: Hashable, Sendable {

    /// The form: a username, a password, and a way in.
    case signIn

    /// Account creation: three fields, checked live, and a session at the end of them.
    case createAccount
}
