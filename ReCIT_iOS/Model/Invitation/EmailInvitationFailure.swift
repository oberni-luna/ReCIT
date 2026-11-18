//
//  EmailInvitationFailure.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// Why `POST /api/invitations/by-emails` failed. The one refusal worth its own sentence is the
/// quota: inventaire.io takes 250 invitations per reader and answers `429` past them, which no
/// retry will fix today.
nonisolated enum EmailInvitationFailure: Error {
    case rateLimited
    case other(Error)

    /// Classifies what the call threw.
    /// - Parameter error: The error thrown by the request, usually a `NetworkError`.
    init(error: Error) {
        if case .badStatus(code: 429, message: _)? = error as? NetworkError {
            self = .rateLimited
        } else {
            self = .other(error)
        }
    }

    /// The sentence of its own, when the failure has one; `nil` for the others, which the
    /// SnackBar shows through `SnackBarView.error`.
    var message: LocalizedStringResource? {
        switch self {
        case .rateLimited: "network.email_invitation.failure.rate_limited"
        case .other: nil
        }
    }
}
