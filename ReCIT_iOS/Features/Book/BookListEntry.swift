//
//  BookListEntry.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import SwiftData

/// One row of the book screen's « Dans les listes »: a list holding the book's work, who made
/// it when it is a friend's, and the work the list opens on.
struct BookListEntry: Identifiable {
    let list: EntityList
    let owner: User?
    let focusURI: String

    var id: PersistentIdentifier { list.id }
}
