//
//  MemberGesture.swift
//  ReCIT_iOS
//
//  The two things an admin can do to a member that cannot be taken back from the app — which is
//  why each goes through a confirmation. Naming an admin has no inverse on the server at all;
//  removing someone means they have to ask or be invited again.
//

import SwiftUI

enum MemberGesture: Equatable {
    case makeAdmin(User)
    case kick(User)

    var user: User {
        switch self {
        case .makeAdmin(let user), .kick(let user): user
        }
    }

    var action: GroupAction {
        switch self {
        case .makeAdmin: .makeAdmin
        case .kick: .kick
        }
    }
}
