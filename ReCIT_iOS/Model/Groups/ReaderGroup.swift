//
//  ReaderGroup.swift
//  ReCIT_iOS
//
//  A group of readers on inventaire.io — a club, a family, a building — who share their books.
//
//  **A value, not a `@Model`.** Groups live in `GroupModel`, in memory, for this launch: adding
//  a persisted model means a store migration, which this project does not do without asking.
//  Everything a screen needs comes back with one `GET /api/groups` at launch, and a group's
//  members are `User`s of the store, looked up by id. See PRD 0016.
//
//  **The transitions are the server's.** `applying(_:by:on:)` reproduces
//  `groupMembershipActions` in `server/models/group.ts`, down to its shortcuts: a request to an
//  open group lets you in, a request from someone invited or who declined lets them in, an
//  invitation to someone who had asked accepts them. That is what lets every gesture be
//  optimistic (ADR 0001) — the local state it shows is the state the server is about to write,
//  and a refusal puts the previous value back.
//

import Foundation

struct ReaderGroup: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var slug: String?
    var description: String
    var pictureURL: String?
    /// Whether any reader can find it in the search.
    var searchable: Bool
    /// Whether a request lets you in at once, rather than waiting on an admin.
    var open: Bool
    var admins: [GroupMembership]
    var members: [GroupMembership]
    var invited: [GroupMembership]
    var declined: [GroupMembership]
    var requested: [GroupMembership]

    /// The one role `userId` holds, or `nil` for someone the group does not know.
    func role(of userId: String?) -> GroupRole? {
        guard let userId else { return nil }
        if admins.contains(where: { $0.user == userId }) { return .admin }
        if members.contains(where: { $0.user == userId }) { return .member }
        if invited.contains(where: { $0.user == userId }) { return .invited }
        if requested.contains(where: { $0.user == userId }) { return .requested }
        if declined.contains(where: { $0.user == userId }) { return .declined }
        return nil
    }

    /// Admins first, then members: everyone the group's books are shared with.
    var memberIds: [String] {
        admins.map(\.user) + members.map(\.user)
    }

    var memberCount: Int {
        admins.count + members.count
    }

    /// Everyone named anywhere in the document, invitors included — what has to be in the store
    /// for the screens to put a name on each line.
    var everyoneIds: [String] {
        let memberships: [GroupMembership] = admins + members + invited + declined + requested
        let ids: [String] = memberships.map(\.user) + memberships.compactMap(\.invitor)
        return Array(Set(ids))
    }

    /// Who invited `userId`, when they are waiting on an invitation.
    func invitor(of userId: String) -> String? {
        invited.first { $0.user == userId }?.invitor
    }

    /// `server/controllers/groups/lib/leave_groups.ts`: anyone may leave, except the only admin
    /// of a group that still has members — they have to name another admin first.
    func canLeave(_ userId: String) -> Bool {
        guard admins.contains(where: { $0.user == userId }) else { return true }
        return admins.count > 1 || members.isEmpty
    }

    /// The group as it will be once `actor` has done `action`, to `target` when the gesture is
    /// about someone else.
    ///
    /// Throws when the server would refuse, so that nothing optimistic is shown for a gesture
    /// that cannot succeed. Rights — who is admin enough to do what — are left to the screens,
    /// which only offer a gesture to someone allowed to make it.
    func applying(
        _ action: GroupAction,
        by actor: String,
        on target: String? = nil,
        at timestamp: Double = Date.now.timeIntervalSince1970 * 1000
    ) throws -> ReaderGroup {
        var group: ReaderGroup = self
        switch action {
        case .invite:
            guard let target else { throw GroupTransitionError.missingTarget }
            switch role(of: target) {
            case .requested:
                try group.move(target, from: \.requested, to: \.members)
            case .declined:
                throw GroupTransitionError.alreadyDeclined
            case .some:
                throw GroupTransitionError.alreadyInGroup
            case .none:
                group.invited.append(.init(user: target, invitor: actor, timestamp: timestamp))
            }

        case .accept:
            try group.move(actor, from: \.invited, to: \.members)

        case .decline:
            try group.move(actor, from: \.invited, to: \.declined)

        case .request:
            switch role(of: actor) {
            case .invited:
                try group.move(actor, from: \.invited, to: \.members)
            case .declined:
                try group.move(actor, from: \.declined, to: \.members)
            case .some:
                throw GroupTransitionError.alreadyInGroup
            case .none:
                let membership: GroupMembership = .init(user: actor, invitor: nil, timestamp: timestamp)
                if open {
                    group.members.append(membership)
                } else {
                    group.requested.append(membership)
                }
            }

        case .cancelRequest:
            try group.remove(actor, from: \.requested)

        case .acceptRequest:
            guard let target else { throw GroupTransitionError.missingTarget }
            try group.move(target, from: \.requested, to: \.members)

        case .refuseRequest:
            guard let target else { throw GroupTransitionError.missingTarget }
            try group.remove(target, from: \.requested)

        case .makeAdmin:
            guard let target else { throw GroupTransitionError.missingTarget }
            try group.move(target, from: \.members, to: \.admins)

        case .kick:
            guard let target else { throw GroupTransitionError.missingTarget }
            try group.remove(target, from: \.members)

        case .leave:
            guard canLeave(actor) else { throw GroupTransitionError.lastAdmin }
            if role(of: actor) == .admin {
                try group.remove(actor, from: \.admins)
            } else {
                try group.remove(actor, from: \.members)
            }
        }
        return group
    }

    private mutating func move(
        _ userId: String,
        from source: WritableKeyPath<ReaderGroup, [GroupMembership]>,
        to destination: WritableKeyPath<ReaderGroup, [GroupMembership]>
    ) throws {
        guard let index = self[keyPath: source].firstIndex(where: { $0.user == userId }) else {
            throw GroupTransitionError.notInExpectedRole
        }
        let membership: GroupMembership = self[keyPath: source].remove(at: index)
        self[keyPath: destination].append(membership)
    }

    private mutating func remove(
        _ userId: String,
        from source: WritableKeyPath<ReaderGroup, [GroupMembership]>
    ) throws {
        guard let index = self[keyPath: source].firstIndex(where: { $0.user == userId }) else {
            throw GroupTransitionError.notInExpectedRole
        }
        self[keyPath: source].remove(at: index)
    }
}
