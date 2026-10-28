//
//  ProfileSaveFailure.swift
//  ReCIT_iOS
//
//  « Enregistrer » stopped part of the way. A profile is written one attribute per request, so
//  there is no saving it all or nothing: what went through before the refusal stays, and this
//  says which one was refused — the next « Enregistrer » sends it and whatever came after.
//

import Foundation

struct ProfileSaveFailure: Error {
    let refused: ProfileChange.Kind
    let landed: [ProfileChange]
    let underlying: Error

    var title: String.LocalizationValue {
        "edit_profile.failure.title"
    }

    var explanation: String.LocalizationValue {
        if refused == .username, isUsernameTaken {
            return "edit_profile.failure.username_taken"
        }

        switch refused {
        case .picture: return "edit_profile.failure.picture"
        case .username: return "edit_profile.failure.username"
        case .bio: return "edit_profile.failure.bio"
        case .position: return "edit_profile.failure.position"
        }
    }

    /// The name went to someone else between the live check and the save. The server says so in
    /// prose (« this username is already used »), the same token `FieldAvailability` reads.
    private var isUsernameTaken: Bool {
        guard case .badStatus(400, let message?)? = underlying as? NetworkError else { return false }
        return message.contains("already used")
    }
}
