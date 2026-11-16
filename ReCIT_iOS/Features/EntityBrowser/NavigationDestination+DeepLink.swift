//
//  NavigationDestination+DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData

extension NavigationDestination {
    /// The Fiche livre of an edition linked by its `isbn:` uri, which needs no request; `nil` for any
    /// other uri.
    init?(linkedISBN uri: String) {
        guard uri.hasPrefix("isbn:") else { return nil }
        self = .book(anchor: .edition(uri: uri))
    }

    /// The screen for a linked entity inventaire.io described, or `nil` for a type the app has no
    /// screen for. Its own `uri` rather than the one linked: a merged `inv:` entity answers under the
    /// uri it was merged into.
    init?(linkedEntity entity: EntityResultDTO) {
        switch entity.type {
        case "edition":
            self = .book(anchor: .edition(uri: entity.uri))
        case "work":
            // A work is not a book: the book screen picks the edition, as it does for a search
            // result (ADR 0002, Move 3). The label fills the header while it does.
            self = .book(
                anchor: .bestEditionOfWork(
                    uri: entity.uri,
                    title: EntityLabel.resolve(entity.labels, originalLang: entity.originalLang) ?? "",
                    imageUrl: nil
                )
            )
        case "human":
            self = .author(uri: entity.uri)
        default:
            return nil
        }
    }

    /// A linked list, springing to the element linked as « Dans les listes » does, by that
    /// element's entity uri. An element no longer in the list, or none linked, opens the list on
    /// its first element.
    init(
        linkedList list: EntityList,
        elementId: String?
    ) {
        let focused: EntityListItem? = list.elements.first { $0._id == elementId }
        self = .entityList(id: list._id, focusURI: focused?.uri)
    }

    /// A linked copy of a book: the Fiche livre anchored on it when the store holds it, mine or a
    /// friend's, which says whose it is and offers « Emprunter à… » on a friend's; else the Fiche
    /// livre of its edition, which neither shows nor stores anything of a stranger's copy. `nil` when
    /// inventaire.io shows no such copy.
    /// - Parameters:
    ///   - id: The copy's inventaire.io id.
    ///   - inventoryModel: The model reading the copy from the store, or its edition from inventaire.io.
    ///   - modelContext: The store to read.
    /// - Returns: The Fiche livre to push, or `nil`.
    static func linkedItem(
        id: String,
        inventoryModel: InventoryModel,
        modelContext: ModelContext
    ) async -> NavigationDestination? {
        if let item = try? inventoryModel.getOrFetchItem(modelContext: modelContext, itemId: id) {
            return .book(anchor: .item(item))
        }
        guard let uri = try? await inventoryModel.fetchEditionURI(ofItem: id) else { return nil }
        return .book(anchor: .edition(uri: uri))
    }

    /// A linked étagère, mine or a friend's: read from the store, else loaded into it from
    /// inventaire.io. `nil` for anyone else's, which stays out of the store, and for one
    /// inventaire.io does not show.
    /// - Parameters:
    ///   - id: The étagère's inventaire.io id.
    ///   - owners: The readers whose étagères open in the app: me and my friends.
    ///   - shelfModel: The model reading the étagère from the store, or loading it.
    ///   - modelContext: The store to read.
    /// - Returns: The étagère's screen, or `nil`.
    static func linkedShelf(
        id: String,
        ownedByOneOf owners: Set<String>,
        shelfModel: ShelfModel,
        modelContext: ModelContext
    ) async -> NavigationDestination? {
        if shelfModel.localShelf(id: id, modelContext: modelContext) != nil {
            return .shelf(id: id)
        }
        let shelf: Shelf? = try? await shelfModel.fetchShelf(id: id, ownedByOneOf: owners, modelContext: modelContext)
        return shelf.map { .shelf(id: $0._id) }
    }
}
