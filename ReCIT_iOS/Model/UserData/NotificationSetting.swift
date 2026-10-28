//
//  NotificationSetting.swift
//  ReCIT_iOS
//
//  One of the e-mails inventaire.io can send, named by the key it carries under
//  `settings.notifications` — the list `server/models/attributes/user.ts` declares, in the order
//  « Notifications par e-mail » shows them.
//

import Foundation

enum NotificationSetting: String, CaseIterable, Sendable {
    /// Every e-mail below at once. Off, the others stay as they are but none is sent.
    case global
    case inventoriesActivitySummary = "inventories_activity_summary"
    case friendshipRequest = "friendship_request"
    case friendAcceptedRequest = "friend_accepted_request"
    case groupInvite = "group_invite"
    case groupAcceptRequest = "group_acceptRequest"
    /// Read as « someone asks to join a group I run »: the server's own documentation says « asked
    /// to be a member of a group », which could also mean an invitation — `group_invite` already is.
    case groupJoinRequest = "group_join_request"
    case yourItemWasRequested = "your_item_was_requested"
    case updateOnYourItem = "update_on_your_item"
    case updateOnItemYouRequested = "update_on_item_you_requested"

    /// The `attribute` `PUT /api/user` takes for it.
    var attribute: String {
        "settings.notifications.\(rawValue)"
    }
}
