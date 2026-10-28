//
//  PasswordChangeFailure.swift
//  ReCIT_iOS
//
//  Why `PUT /api/auth/password` refused. The one refusal worth its own sentence is a current
//  password that does not match: the server answers `400 invalid old-password`, and the field to
//  fix is the first one, not the second.
//

import Foundation

enum PasswordChangeFailure: Error, Equatable {
    case wrongCurrentPassword
    case other

    init(error: Error) {
        if case .badStatus(400, let message?)? = error as? NetworkError, message.contains("old-password") {
            self = .wrongCurrentPassword
        } else {
            self = .other
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .wrongCurrentPassword: "change_password.failure.current"
        case .other: "change_password.failure.other"
        }
    }
}
