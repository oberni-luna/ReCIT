//
//  NetworkListEntry.swift
//  ReCIT_iOS
//
//  One row of « Dans mon réseau » in the Lists tab: a friend's list, and the friend who made it,
//  whose picture and name head the row.
//

import SwiftData

struct NetworkListEntry: Identifiable {
    let list: EntityList
    let owner: User

    var id: PersistentIdentifier { list.id }
}
