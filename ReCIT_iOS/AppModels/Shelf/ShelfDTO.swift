//
//  ShelfDTO.swift
//  ReCIT_iOS
//
//  Decodes inventaire.io `GET /api/shelves?action=by-owners`. The response is a
//  dictionary keyed by shelf id: `{ "shelves": { "<id>": { … } } }`. Private
//  attributes (e.g. visibility) may be stripped for non-owners, so optional fields
//  are decoded defensively. See ADR 0003.
//

import Foundation

struct ShelvesResponseDTO: Codable {
    let shelves: [String: ShelfDTO]
}

/// Response of `?action=by-ids&with-items=true`: the same id-keyed dict, but each
/// shelf carries its `items` as an array of **item id strings** (not objects), which
/// is exactly what's needed to rebuild the local membership relation.
struct ShelvesWithItemsResponseDTO: Codable {
    let shelves: [String: ShelfWithItemsDTO]
}

struct ShelfWithItemsDTO: Codable {
    let _id: String
    let items: [String]?
}

// MARK: - Create

/// Payload for `POST /api/shelves?action=create`. Empty `visibility` means private.
struct NewShelfDTO: Codable {
    let name: String
    let description: String?
    let visibility: [String]
}

/// Payload for `POST /api/shelves?action=update` — only the attributes being changed.
struct UpdateShelfDTO: Codable {
    let shelf: String
    let name: String?
    let description: String?
    let visibility: [String]?
}

// MARK: - Delete

/// Payload for `POST /api/shelves?action=delete`. The endpoint deletes in bulk, so `ids`
/// is an array even for the single étagère the form removes.
///
/// The endpoint also takes a `with-items` flag that deletes the shelf's books along with
/// it. It is deliberately absent from this payload rather than sent as `false`: removing a
/// shelf must never cost the user the record of owning its books, and a field that cannot
/// be set cannot be set by mistake.
struct DeleteShelvesDTO: Codable {
    let ids: [String]
}

// MARK: - Membership

/// Payload for `POST /api/shelves?action=add-items` (and `?action=remove-items`): the
/// étagère and the item ids to file onto it or take off it. Both actions answer with the
/// affected shelves keyed by id, each carrying its post-write `items` id array — i.e.
/// `ShelvesWithItemsResponseDTO`, which is what the write reconciles from.
struct ShelfItemsDTO: Codable {
    let id: String
    let items: [String]
}

/// Shared response of create and update: `{ shelf }`.
struct ShelfResponseDTO: Codable {
    let shelf: ShelfDTO
}

struct ShelfDTO: Codable {
    let _id: String
    let _rev: String
    let name: String
    let slug: String?
    let description: String?
    let owner: String
    let visibility: [String]?
    let color: String?
    let created: Double
    let updated: Double?
}
