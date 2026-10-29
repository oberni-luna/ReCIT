//
//  ListMoveDestination.swift
//  ReCIT_iOS
//
//  One list an element can be moved into, as « Déplacer dans une autre liste » offers it: a list
//  of the same type as the one the element is in, never that one itself. A list that already
//  holds the element is offered too, but greyed: inventaire.io answers `alreadyInList` and
//  creates nothing, so moving there would only take the element out of the list it is in.
//
//  A value, so the menu never reads SwiftData to decide what to show.
//

import Foundation

struct ListMoveDestination: Identifiable, Hashable {
    let id: String
    let name: String
    let alreadyHolds: Bool

    /// A list as the menu needs to know it.
    struct Candidate {
        let id: String
        let name: String
        let type: EntityListType
        let uris: Set<String>
    }

    /// The lists `uri` can be moved into from `currentListID`, sorted by name.
    static func destinations(
        for uri: String,
        from currentListID: String,
        type: EntityListType,
        among candidates: [Candidate]
    ) -> [ListMoveDestination] {
        candidates
            .filter { $0.id != currentListID && $0.type == type }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { .init(id: $0.id, name: $0.name, alreadyHolds: $0.uris.contains(uri)) }
    }
}
