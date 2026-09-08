//
//  SessionCookie.swift
//  ReCIT_iOS
//
//  Who an `inventaire:session` cookie belongs to, read off the cookie itself.
//
//  Pure, on the pattern of `AuthFailure`, `PostSignupSession`, `FieldAvailability` and
//  `SessionExpiry`: no `URLSession`, no keychain, no jar. One question, answered from a string.
//
//  It exists because the *name* of a session cookie says nothing. inventaire.io sits behind a
//  global `cookie-session` middleware that hands an anonymous session to anyone who asks it a
//  public question, under the very two names a real session uses — which is what issue 0068
//  reported and what made `isLoggedIn()` stop believing the jar. The **value**, though, says
//  everything: it is base64url JSON, and it names a user or it does not.
//
//      GET /api/items/recent-public   →  eyJ0aW1lc3RhbXAiOjE3ODg5MDAwMTAwNjN9
//                                        {"timestamp":1788900010063}
//      POST /api/auth/login           →  eyJ1c2VyIjoiMzY4MjllMjEzODljMjdjNjI5YTMxODFlMzFjMzYzMDEi…
//                                        {"user":"36829e21389c27c629a3181e31c36301","timestamp":…}
//
//  Both verified against production. So a cookie that names a user is a session **this app was
//  given by signing in**, and nothing else can produce one — which is what issue 0069 needed:
//  the keychain is a record of the sessions this build opened, and an install whose session was
//  opened by an earlier build has one in the jar and nothing in the keychain.
//
//  A value that does not decode is `unreadable` rather than anonymous. It is not a licence to
//  assume a session — the caller decides — but it keeps a server that changes its payload from
//  turning into an app that claims a user out of thin air.
//
//  See issues 0068 and 0069.
//

import Foundation

enum SessionCookie {

    /// What a session cookie's payload says about whose session it is.
    enum Owner: Equatable {
        /// A session opened by signing in, carrying the user's document id.
        case user(id: String)
        /// A session the server handed out for free, on a public request.
        case anonymous
        /// Not base64url JSON of the shape this server serialises. Says nothing either way.
        case unreadable
    }

    /// The only field that matters. `timestamp` is there too and is nobody's business here.
    private struct Payload: Decodable {
        let user: String?
    }

    static func owner(ofValue value: String) -> Owner {
        guard let data: Data = base64URLDecoded(value),
              let payload: Payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { return .unreadable }

        guard let user: String = payload.user, user.isEmpty == false else { return .anonymous }

        return .user(id: user)
    }

    /// Whether any of these cookie values is a signed-in session.
    static func namesAUser(_ values: [String]) -> Bool {
        values.contains { value in
            if case .user = owner(ofValue: value) { true } else { false }
        }
    }

    /// base64url, unpadded — which is what `cookie-session` writes and what
    /// `Data(base64Encoded:)` refuses.
    private static func base64URLDecoded(_ value: String) -> Data? {
        var base64: String = value
            .replacing("-", with: "+")
            .replacing("_", with: "/")

        let remainder: Int = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }
}
