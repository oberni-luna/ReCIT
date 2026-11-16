//
//  ListSearchMatch.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData

/// One row of Recherche's Listes section: a list, and the friend who made it when it is not
/// mine — whose picture and name head the row, as in « Dans mon réseau ».
struct ListSearchMatch: Identifiable {
    let list: EntityList
    /// The friend who made the list, `nil` for one of mine.
    let owner: User?

    var id: PersistentIdentifier { list.id }
}
