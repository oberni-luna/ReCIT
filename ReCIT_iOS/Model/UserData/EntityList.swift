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
    var explanation: String
    var created: Date
    var updated: Date?
    var visibility: [VisibilityAttributes]
    @Relationship(deleteRule: .cascade) var elements: [EntityListItem]
    var type: EntityListType

    init(_id: String, _rev: String, name: String, explanation: String, created: Date, updated: Date? = nil, visibility: [VisibilityAttributes], elements: [EntityListItem] = [], type: EntityListType) {
        self._id = _id
        self._rev = _rev
        self.name = name
        self.explanation = explanation
        self.created = created
        self.updated = updated
        self.visibility = visibility
        self.elements = elements
        self.type = type
    }

    convenience init(listDTO: ListDTO, baseUrl: String) {
        let updatedDate: Date? = if let updated = listDTO.updated {
            Date(timeIntervalSince1970: updated / 1000)
        } else {
            nil
        }

        self.init(
            _id: listDTO._id,
            _rev: listDTO._rev,
            name: listDTO.name,
            explanation: listDTO.description,
            created: Date(timeIntervalSince1970: listDTO.created),
            updated: updatedDate,
            visibility: listDTO.visibility.compactMap { VisibilityAttributes(rawValue: $0) },
            elements: listDTO.elements?.compactMap {
                .init(listElementDTO: $0, listType: EntityListType(rawValue: listDTO.type) ?? .work, baseUrl: baseUrl)
            } ?? [],
            type: EntityListType(rawValue: listDTO.type) ?? .work
        )
    }

    /// Merges a freshly fetched DTO into this list in place, reconciling its
    /// elements by `_id` (so the object identity — and any view bound to it —
    /// survives a background sync).
    func update(listDTO: ListDTO, baseUrl: String, modelContext: ModelContext) {
        _rev = listDTO._rev
        name = listDTO.name
        explanation = listDTO.description
        updated = listDTO.updated.map { Date(timeIntervalSince1970: $0 / 1000) }
        visibility = listDTO.visibility.compactMap { VisibilityAttributes(rawValue: $0) }
        type = EntityListType(rawValue: listDTO.type) ?? .work

        let elementDTOs: [ListElementDTO] = listDTO.elements ?? []
        let dtoByID: [String: ListElementDTO] = .init(elementDTOs.map { ($0._id, $0) }) { first, _ in first }

        // Drop elements no longer present server-side.
        for element in elements where dtoByID[element._id] == nil {
            modelContext.delete(element)
        }
        elements.removeAll { dtoByID[$0._id] == nil }

        // Update surviving elements and insert the new ones.
        let existingIDs: Set<String> = Set(elements.map(\._id))
        for element in elements {
            guard let dto = dtoByID[element._id] else { continue }
            element.comment = dto.comment ?? ""
            element.ordinal = dto.ordinal
        }
        for dto in elementDTOs where !existingIDs.contains(dto._id) {
            let item: EntityListItem = .init(listElementDTO: dto, listType: type, baseUrl: baseUrl)
            modelContext.insert(item)
            elements.append(item)
        }
    }
}

@Model
public final class EntityListItem {
    @Attribute(.unique) var _id: String
    var comment: String
    var uri: String
    var ordinal: String
    var updated: Date?
    var created: Date
    var entityType: EntityListType
    var list: EntityList?

    init(_id: String, comment: String = "", uri: String, ordinal: String, updated: Date? = nil, created: Date, itemType: EntityListType, list: EntityList? = nil) {
        self._id = _id
        self.comment = comment
        self.uri = uri
        self.ordinal = ordinal
        self.updated = updated
        self.created = created
        self.entityType = itemType
        self.list = list
    }

    convenience init(listElementDTO: ListElementDTO, listType: EntityListType, baseUrl: String) {
        let updatedDate: Date? = if let updated = listElementDTO.updated {
            Date(timeIntervalSince1970: updated / 1000)
        } else {
            nil
        }
        self.init(
            _id: listElementDTO._id,
            comment: listElementDTO.comment ?? "",
            uri: listElementDTO.uri,
            ordinal: listElementDTO.ordinal,
            updated: updatedDate,
            created: Date(timeIntervalSince1970: listElementDTO.created / 1000),
            itemType: listType
        )
    }
}
