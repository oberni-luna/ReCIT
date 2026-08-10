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
