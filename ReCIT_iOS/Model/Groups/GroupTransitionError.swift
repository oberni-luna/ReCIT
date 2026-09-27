//
//  GroupTransitionError.swift
//  ReCIT_iOS
//
//  Why a gesture cannot be applied to a group as it stands locally. Each case is a refusal the
//  server would answer too, caught before the call so the optimistic state never lies.
//

import Foundation

enum GroupTransitionError: Error, Equatable {
    /// The person is not in the list the gesture moves them out of.
    case notInExpectedRole
    /// The person already has a role, and the gesture would give them a second one.
    case alreadyInGroup
    /// An invitation turned down cannot be sent again (`user already declined the invitation`).
    case alreadyDeclined
    /// The gesture needs someone else, and none was given.
    case missingTarget
    /// The last admin cannot leave while there are members left.
    case lastAdmin
}
