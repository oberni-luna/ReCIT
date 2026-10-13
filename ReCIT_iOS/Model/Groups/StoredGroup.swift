//
//  StoredGroup.swift
//  ReCIT_iOS
//
//  One of my groups as the store keeps it between launches: admin, member, invited, or asked to
//  join from this device. See PRD 0019 and issue 0103, which reversed the « in memory » choice of
//  feature 0028 so that the groups are there the moment the app opens, and offline.
//
//  **The store's copy, not the domain's.** `ReaderGroup` stays the value every screen and every
//  transition works with — `applying`, `role(of:)`, `memberIds` and their tests did not move.
//  This is only where one is kept: `readerGroup` reads it out, `overwrite(with:)` puts back a
//  value the app computed itself (an optimistic gesture, a setting, or its revert), and
//  `update(from:pictureURL:)` merges what the server sent. Both write in place, so a screen open
//  on the group keeps its object across a sync (ADR 0001).
//
//  **Ids, no relationships.** The five role lists are `GroupMembership` values — who, invited by
//  whom, since when — as inventaire.io stores them. A member is a `User` of the store looked up
//  by id, never a SwiftData relationship: a group names strangers the store may not hold, and
//  purging or upserting one side never has to walk the other (Q11b).
//
//  **Only the groups I hold a role in.** A group opened from a search stays in `GroupModel`'s
//  memory for the launch, as every group did before.
//

import Foundation
import SwiftData

@Model
final class StoredGroup {
    @Attribute(.unique) var _id: String
    /// The document's revision, or `""` when the server did not send one.
    var _rev: String
    var name: String
    var slug: String?
    /// What the group says of itself. `description` is `CustomStringConvertible`'s.
    var groupDescription: String
    /// Already absolute: `GroupModel` resolves `/img/groups/<hash>` before it gets here.
    var pictureURL: String?
    var searchable: Bool
    var open: Bool
    var admins: [GroupMembership]
    var members: [GroupMembership]
    var invited: [GroupMembership]
    var declined: [GroupMembership]
    var requested: [GroupMembership]

    init(
        _id: String,
        _rev: String,
        name: String,
        slug: String?,
        groupDescription: String,
        pictureURL: String?,
        searchable: Bool,
        open: Bool,
        admins: [GroupMembership],
        members: [GroupMembership],
        invited: [GroupMembership],
        declined: [GroupMembership],
        requested: [GroupMembership]
    ) {
        self._id = _id
        self._rev = _rev
        self.name = name
        self.slug = slug
        self.groupDescription = groupDescription
        self.pictureURL = pictureURL
        self.searchable = searchable
        self.open = open
        self.admins = admins
        self.members = members
        self.invited = invited
        self.declined = declined
        self.requested = requested
    }

    /// A group the app computed itself — one I just created, or one a gesture made mine.
    convenience init(group: ReaderGroup) {
        self.init(
            _id: group.id,
            _rev: "",
            name: group.name,
            slug: group.slug,
            groupDescription: group.description,
            pictureURL: group.pictureURL,
            searchable: group.searchable,
            open: group.open,
            admins: group.admins,
            members: group.members,
            invited: group.invited,
            declined: group.declined,
            requested: group.requested
        )
    }

    /// - Parameter pictureURL: The document's `picture`, already made absolute.
    convenience init(dto: GroupDTO, pictureURL: String?) {
        self.init(group: .init(dto: dto, pictureURL: pictureURL))
        _rev = dto._rev ?? ""
    }

    /// The value the screens and the transitions work with.
    var readerGroup: ReaderGroup {
        .init(
            id: _id,
            name: name,
            slug: slug,
            description: groupDescription,
            pictureURL: pictureURL,
            searchable: searchable,
            open: open,
            admins: admins,
            members: members,
            invited: invited,
            declined: declined,
            requested: requested
        )
    }

    /// Merges a document the server just sent, in place.
    ///
    /// Idempotent, and guarded field by field: what the document leaves out is left alone
    /// (ADR 0001). inventaire.io omits `picture` and `description` when there are none, and older
    /// documents predate `open` and the three optional role lists — a sparse answer must not
    /// wipe what the store already knows. The name and the two lists every group has are always
    /// there, and always written.
    ///
    /// - Parameter pictureURL: The document's `picture`, already made absolute.
    func update(from dto: GroupDTO, pictureURL: String?) {
        if let revision = dto._rev {
            _rev = revision
        }
        name = dto.name
        if let slug = dto.slug {
            self.slug = slug
        }
        if let description = dto.description {
            groupDescription = description
        }
        if let pictureURL {
            self.pictureURL = pictureURL
        }
        if let searchable = dto.searchable {
            self.searchable = searchable
        }
        if let open = dto.open {
            self.open = open
        }
        admins = dto.admins
        members = dto.members
        if let invited = dto.invited {
            self.invited = invited
        }
        if let declined = dto.declined {
            self.declined = declined
        }
        if let requested = dto.requested {
            self.requested = requested
        }
    }

    /// Writes back, whole, a value the app computed from this one — the outcome of a gesture or
    /// of a setting, or the previous value when the server refused it. Not a merge: every field
    /// of `group` is the truth the screen should show.
    func overwrite(with group: ReaderGroup) {
        name = group.name
        slug = group.slug
        groupDescription = group.description
        pictureURL = group.pictureURL
        searchable = group.searchable
        open = group.open
        admins = group.admins
        members = group.members
        invited = group.invited
        declined = group.declined
        requested = group.requested
    }
}
