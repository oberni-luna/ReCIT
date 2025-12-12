//
//  List.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//

import Foundation

import Foundation
import SwiftData

enum EntityListType: String, Codable, CaseIterable {
    case work
    case author
    case publisher
}

@Model
public final class EntityList {
    @Attribute(.unique) var _id: String
    var _rev: String
    var name: String
    var created: Date
    var updated: Date?
    var visibility: [VisibilityAttributes]
    var elements: [EntityListItem]
    var type: EntityListType

    init(_id: String, _rev: String, name: String, created: Date, updated: Date? = nil, visibility: [VisibilityAttributes], elements: [EntityListItem] = [], type: EntityListType) {
        self._id = _id
        self._rev = _rev
        self.name = name
        self.created = created
        self.updated = updated
        self.visibility = visibility
        self.elements = elements
        self.type = type
    }

    convenience init(listDTO: ListDTO, baseUrl: String) {
        let updatedDate: Date? = if let updated = listDTO.updated {
            Date(timeIntervalSince1970: updated)
        } else {
            nil
        }

        self.init(
            _id: listDTO._id,
            _rev: listDTO._rev,
            name: listDTO.name,
            created: Date(timeIntervalSince1970: listDTO.created),
            updated: updatedDate,
            visibility: listDTO.visibility.compactMap { VisibilityAttributes(rawValue: $0) ?? .private },
            elements: [],
            type: EntityListType(rawValue: listDTO.type) ?? .work
        )
    }
}

@Model
public final class EntityListItem {
    @Attribute(.unique) var _id: String
    var comment: String?
    var uri: String?
    var ordinal: String
    var item: InventoryItem

    init(_id: String, comment: String? = nil, uri: String? = nil, ordinal: String, item: InventoryItem) {
        self._id = _id
        self.comment = comment
        self.uri = uri
        self.ordinal = ordinal
        self.item = item
    }
}
