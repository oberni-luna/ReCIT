//
//  SessionExpiry.swift
//  ReCIT_iOS
//
//  Whether a failure means "the session is gone" rather than "that call did not work".
//
//  Pure, on the pattern of `PostSignupSession`, `FieldAvailability` and `AuthFailure`: no
//  `URLSession`, no keychain, no SwiftUI. One question, answered from a status code.
//
//  It exists because the two are handled in opposite ways. An ordinary failure is retried on
//  the next refresh and leaves the screens as they were. A dead session cannot be retried into
//  working: every following call fails the same way, the first-sync placeholders never clear,
//  and the app sits on "Synchronisation de vos données…" for ever — which is exactly what
//  issue 0068 reported. The answer to that one is to stop claiming the user is signed in.
//
//  `401` only. inventaire.io answers `401 "unauthorized api access"` for a request whose
//  session it does not honour — verified against production, `GET /api/user` with no cookie.
//  A `403` is not the same statement: it is a session the server *did* recognise and a thing it
//  will not let that account do, and signing the user out would be the wrong cure for it.
//
//  See issue 0068.
//

import Foundation

enum SessionExpiry {

    /// Whether this error says the server no longer recognises the session.
    static func isSessionGone(_ error: Error) -> Bool {
        guard case NetworkError.badStatus(let code, _) = error else { return false }

        return code == 401
    }
}
