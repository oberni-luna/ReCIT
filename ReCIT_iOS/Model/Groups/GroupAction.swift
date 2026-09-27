//
//  GroupAction.swift
//  ReCIT_iOS
//
//  Every membership gesture inventaire.io takes, as the path segment of
//  `PUT /api/groups/<action>` (`server/controllers/groups/groups.ts`).
//

import Foundation

enum GroupAction: String, CaseIterable, Sendable {
    case invite
    case accept
    case decline
    case request
    case cancelRequest = "cancel-request"
    case acceptRequest = "accept-request"
    case refuseRequest = "refuse-request"
    case makeAdmin = "make-admin"
    case kick
    case leave

    /// Whether the gesture is about someone else, and so carries a `user` next to the `group`.
    /// The server's `groupActionsWithOtherUser`.
    var targetsAnotherUser: Bool {
        switch self {
        case .invite, .acceptRequest, .refuseRequest, .makeAdmin, .kick:
            true
        case .accept, .decline, .request, .cancelRequest, .leave:
            false
        }
    }
}
