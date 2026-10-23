//
//  MyGroups.swift
//  ReCIT_iOS
//
//  My groups sorted by where I stand in each — what the Groupes segment lists, section by
//  section, and what the Réseau tab's badge counts.
//
//  A value built from values: the screens read the stored groups through `@Query`, turn them
//  into `ReaderGroup`s, and hand them here with my id. Nothing here knows the store, so the
//  sorting rule is the same for every screen that needs it, and testable without one.
//

import Foundation

struct MyGroups: Equatable {
    /// Invitations waiting on my answer.
    let invitations: [ReaderGroup]
    /// The groups I belong to, as an admin or a member.
    let mine: [ReaderGroup]
    /// The requests to join I sent, waiting on an admin.
    let sentRequests: [ReaderGroup]
    /// The requests to join waiting on me, in the groups I administer.
    let requestsToReview: Int

    /// - Parameters:
    ///   - groups: Every group known, in any order. Those where I hold no role, or declined, are
    ///     left out of every section.
    ///   - me: The signed-in reader, or `nil` before anyone is: then no group is mine.
    init(_ groups: [ReaderGroup], me: String?) {
        let sorted: [ReaderGroup] = groups.sorted { lhs, rhs in
            switch lhs.name.localizedStandardCompare(rhs.name) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: lhs.id < rhs.id
            }
        }
        invitations = sorted.filter { $0.role(of: me) == .invited }
        mine = sorted.filter { $0.role(of: me)?.belongs == true }
        sentRequests = sorted.filter { $0.role(of: me) == .requested }
        requestsToReview = mine.reduce(0) { $0 + $1.requestsToReview(by: me) }
    }

    /// Everything in the Groupes segment that waits on an answer from me — what the Réseau tab's
    /// badge adds to the friends' invitations.
    var pendingCount: Int {
        invitations.count + requestsToReview
    }

    /// No section has anything to show.
    var isEmpty: Bool {
        invitations.isEmpty && mine.isEmpty && sentRequests.isEmpty
    }
}
