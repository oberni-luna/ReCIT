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
    var busy: Bool?
    var details: String
    var searchIndex: String = ""
    var edition: Edition?
    var owner: User?

    var authors: [Author] {
        if let edition, edition.works.flatMap(\.authors).isEmpty == false {
            Array(Set(edition.works.flatMap(\.authors)))
        } else {
            []
        }
    }

    var workUris: [String] {
        if let edition, edition.works.isEmpty == false {
            Array(Set(edition.works.map(\.uri)))
        } else {
            []
        }
    }

    init(_id: String, _rev: String, transaction: TransactionType, visibility: [VisibilityAttributes], ownerId: String, created: Date, updated: Date?, busy: Bool?, details: String = "", edition: Edition) {
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

    convenience init(itemDTO: ItemDTO, forUser: User, apiService: APIService) {
        let updatedDate: Date? = if let updated = itemDTO.updated {
            Date(timeIntervalSince1970: updated / 1000)
        } else {
            nil
        }

        self.init(
            _id: itemDTO._id,
            _rev: itemDTO._rev,
            transaction: TransactionType(rawValue: itemDTO.transaction) ?? .inventorying,
            visibility: itemDTO.visibility?.compactMap { VisibilityAttributes(rawValue: $0) } ?? [],
            ownerId: itemDTO.owner,
            created: Date(timeIntervalSince1970: itemDTO.created / 1000),
            updated: updatedDate,
            busy: itemDTO.busy,
            details: itemDTO.details ?? "",
            edition: Edition(uri: itemDTO.entity, entitySnapshotDTO: itemDTO.snapshot, apiService: apiService, works: [])
        )
        self.owner = forUser
        self.searchIndex = InventoryItem.buildSearchIndex(
            ownerUsername: forUser.username,
            authorNames: itemDTO.snapshot.`entity:authors`?.components(separatedBy: ",") ?? [],
            title: itemDTO.snapshot.`entity:title`,
            subtitle: itemDTO.snapshot.`entity:subtitle`
        )
    }
}

extension InventoryItem {
    /// The characteristics by which the app can sort earthquake data.
    enum FilterParameter: String, CaseIterable, Identifiable {
        case userInventory, othersInventory
        var id: Self { self }
        var name: String { rawValue.capitalized }
    }

    /// Builds a lowercase search index string from item metadata.
    static func buildSearchIndex(
        ownerUsername: String,
        authorNames: [String],
        title: String,
        subtitle: String?
    ) -> String {
        let joined: String = ([ownerUsername] + authorNames + [title] + [subtitle].compactMap { $0 })
            .joined(separator: " ")
            .lowercased()
        return joined.applyingTransform(.stripDiacritics, reverse: false) ?? joined
    }

    /// A filter that checks text in the item's pre-computed search index.
    static func predicate(
        user: User,
        filterParameter: FilterParameter,
        searchText: String
    ) -> Predicate<InventoryItem> {

        let userId: String = user._id
        let cleanSearchText: String = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // The isEmpty check must live outside #Predicate — SwiftData cannot
        // translate String.isEmpty on a captured variable into SQL, which
        // causes the query to silently return no results when text is non-empty.
        guard !cleanSearchText.isEmpty else {
            switch filterParameter {
            case .othersInventory:
                return #Predicate { item in item.ownerId != userId }
            case .userInventory:
                return #Predicate { item in item.ownerId == userId }
            }
        }

        switch filterParameter {
        case .othersInventory:
            return #Predicate { item in
                item.searchIndex.localizedStandardContains(cleanSearchText)
                && item.ownerId != userId
            }
        case .userInventory:
            return #Predicate { item in
                item.searchIndex.localizedStandardContains(cleanSearchText)
                && item.ownerId == userId
            }
        }
    }
}
