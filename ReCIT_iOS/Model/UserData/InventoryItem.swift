//
//  Item.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/08/2025.
//

import Foundation
import SwiftData

@Model
public final class InventoryItem{

    @Attribute(.unique) var _id: String
    var _rev: String
    var transaction: TransactionType
    var visibility: [VisibilityAttributes]
    var ownerId: String
    var created: Date
    var updated: Date?
    var busy: Bool
    var details: String?
    var edition: Edition?
    var owner: User?

    init(_id: String, _rev: String, transaction: TransactionType, visibility: [VisibilityAttributes], ownerId: String, created: Date, updated: Date?, busy: Bool, details: String? = nil, edition: Edition) {
        self._id = _id
        self._rev = _rev
        self.transaction = transaction
        self.visibility = visibility
        self.ownerId = ownerId
        self.created = created
        self.updated = updated
        self.busy = busy
        self.edition = edition
        self.details = details
    }

    convenience init(itemDTO: ItemDTO, forUser: User, baseUrl: String) {
        let updatedDate: Date? = if let updated = itemDTO.updated {
            Date(timeIntervalSince1970: updated)
        } else {
            nil
        }

        self.init(
            _id: itemDTO._id,
            _rev: itemDTO._rev,
            transaction: TransactionType(rawValue: itemDTO.transaction) ?? .inventorying,
            visibility: itemDTO.visibility?.compactMap { VisibilityAttributes(rawValue: $0) ?? .private } ?? [],
            ownerId: itemDTO.owner,
            created: Date(timeIntervalSince1970: itemDTO.created),
            updated: updatedDate,
            busy: itemDTO.busy,
            details: itemDTO.details,
            edition: Edition(uri: itemDTO.entity, entitySnapshotDTO: itemDTO.snapshot, baseUrl: baseUrl, works: [])
        )
        self.owner = forUser
    }
}
