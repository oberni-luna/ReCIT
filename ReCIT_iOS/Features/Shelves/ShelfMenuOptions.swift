//
//  ShelfMenuOptions.swift
//  ReCIT_iOS
//
//  What the book menu should offer about étagères, derived from nothing but two lists.
//  The menu must never propose an action that would do nothing, so filing is offered for
//  the étagères the copy is *not* on and un-filing for the ones it is — two complements
//  over the user's own étagères — each already reduced to the 0 / 1 / many shape the menu
//  renders (silence, an entry naming the étagère, or a submenu).
//
//  Deliberately free of SwiftUI, SwiftData and the network: the filtering and the
//  boundaries are the part that can be got wrong, and this way they can be tested on
//  their own. Views map their `Shelf` objects in and act on the ids that come back.
//  See PRD 0004.
//

import Foundation

struct ShelfMenuOptions: Equatable, Sendable {

    /// One étagère as the menu offers it: the id the write acts on, the name the user reads.
    struct Entry: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
    }

    /// How many entries one side of the menu has, and therefore how it renders.
    enum Shape: Equatable, Sendable {
        /// Nothing to offer — the menu carries no entry at all.
        case empty
        /// A single étagère, named outright so filing takes one tap.
        case single(Entry)
        /// A real choice, fanned out into a submenu.
        case submenu([Entry])

        /// Reduces an already-filtered list to its shape.
        init(_ entries: [Entry]) {
            switch entries.count {
            case 0: self = .empty
            case 1: self = .single(entries[0])
            default: self = .submenu(entries)
            }
        }

        /// The flat list behind the shape, whatever the shape.
        var entries: [Entry] {
            switch self {
            case .empty: []
            case .single(let entry): [entry]
            case .submenu(let entries): entries
            }
        }
    }

    /// The étagères this copy can still be filed onto.
    let add: Shape
    /// The étagères this copy can be taken off.
    let remove: Shape

    /// - Parameters:
    ///   - userShelves: every étagère the user owns, in the order the menu should list them.
    ///   - itemShelves: the étagères this copy is currently filed on.
    ///
    /// Both lists are drawn from `userShelves`, so they are exact complements and can never
    /// overlap. A membership pointing at an étagère the user no longer owns is therefore
    /// dropped rather than offered — there would be nothing to name it with.
    init(userShelves: [Entry], itemShelves: [Entry]) {
        let currentIDs: Set<String> = .init(itemShelves.map(\.id))
        add = .init(userShelves.filter { currentIDs.contains($0.id) == false })
        remove = .init(userShelves.filter { currentIDs.contains($0.id) })
    }
}
