//
//  MembershipMenuEntry.swift
//  ReCIT_iOS
//
//  One line of a membership menu — the "…" submenus that file an entity into a container
//  (an étagère, a liste) or take it back out. Every container the user owns gets an entry,
//  flagged with whether the entity is already in it, so the menu shows the whole set at once
//  and each line says which way it goes.
//
//  Deliberately free of SwiftUI, SwiftData and the network: views map their `Shelf` /
//  `EntityList` objects in and act on the ids that come back.
//

import Foundation

struct MembershipMenuEntry: Identifiable, Equatable, Sendable {

    /// The id the write acts on.
    let id: String
    /// The name the user reads.
    let name: String
    /// Whether the entity is already in this container — which decides the wording and the icon.
    let isMember: Bool

    /// - Parameters:
    ///   - candidates: every container the user owns, in the order the menu should list them.
    ///   - memberIDs: the ids of the containers the entity is currently in.
    ///
    /// Entries are drawn from `candidates` alone, so a membership pointing at a container the
    /// user no longer owns is dropped rather than offered — there would be nothing to name it
    /// with.
    static func entries(
        candidates: [(id: String, name: String)],
        memberIDs: Set<String>
    ) -> [MembershipMenuEntry] {
        candidates.map {
            .init(
                id: $0.id,
                name: $0.name,
                isMember: memberIDs.contains($0.id)
            )
        }
    }
}
