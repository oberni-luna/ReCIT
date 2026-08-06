//
//  Shelf.swift
//  ReCIT_iOS
//
//  A user's inventaire.io "shelf" (étagère): a metadata document grouping owned
//  items. Membership lives on the item (`InventoryItem.shelves`), resolved into a
//  many-to-many relationship at sync time. See ADR 0003.
//

import Foundation
import SwiftData

@Model
public final class Shelf {

    @Attribute(.unique) var _id: String
    var _rev: String
    var name: String
    var slug: String
    var shelfDescription: String
    var ownerId: String
    var visibility: [String]
    /// Server-provided shelf colour (hex), used for plank/accent tinting. Optional
    /// because private-attribute filtering can omit it for non-owners.
    var colorHex: String?
    var created: Date
    var updated: Date?

    /// Books filed on this shelf. Built from each item's server `shelves` id array
    /// during inventory sync. A book on several shelves appears on each (by design).
    @Relationship var items: [InventoryItem] = []

    init(
        _id: String,
        _rev: String,
        name: String,
        slug: String,
        shelfDescription: String,
        ownerId: String,
        visibility: [String],
        colorHex: String?,
        created: Date,
        updated: Date?
    ) {
        self._id = _id
        self._rev = _rev
        self.name = name
        self.slug = slug
        self.shelfDescription = shelfDescription
        self.ownerId = ownerId
        self.visibility = visibility
        self.colorHex = colorHex
        self.created = created
        self.updated = updated
    }

    convenience init(dto: ShelfDTO) {
        self.init(
            _id: dto._id,
            _rev: dto._rev,
            name: dto.name,
            slug: dto.slug ?? "",
            shelfDescription: dto.description ?? "",
            ownerId: dto.owner,
            visibility: dto.visibility ?? [],
            colorHex: dto.color,
            created: Date(timeIntervalSince1970: dto.created / 1000),
            updated: dto.updated.map { Date(timeIntervalSince1970: $0 / 1000) }
        )
    }

    /// Merges a freshly fetched DTO in place (identity preserved so open shelf views
    /// stay reactive). Non-nil guarded so a sparse payload never wipes good local data.
    func update(from dto: ShelfDTO) {
        _rev = dto._rev
        name = dto.name
        if let slug = dto.slug { self.slug = slug }
        if let description = dto.description { shelfDescription = description }
        if let visibility = dto.visibility { self.visibility = visibility }
        if let color = dto.color { colorHex = color }
        created = Date(timeIntervalSince1970: dto.created / 1000)
        updated = dto.updated.map { Date(timeIntervalSince1970: $0 / 1000) }
    }
}
