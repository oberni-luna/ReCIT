//
//  ItemsDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 27/08/2025.
//

import Foundation

struct ItemsDTO: Codable {
    let items: [ItemDTO]
    let total: Int
    let offset: Int
}

struct ItemDTO: Codable {
    let _id: String
    let _rev: String
    let entity: String
    let transaction: String
    let details: String?
    let visibility: [String]?
    let owner: String
    let created: Double
    let updated: Double?
    let busy: Bool
    let snapshot: EntitySnapshotDTO
}

struct EntitySnapshotDTO: Codable {
    let `entity:title`: String
    let `entity:subtitle`: String?
    let `entity:lang`: String?
    let `entity:authors`: String?
    let `entity:image`: String?
    let `entity:series`: String?
    let `entity:ordinal`: String?
}
