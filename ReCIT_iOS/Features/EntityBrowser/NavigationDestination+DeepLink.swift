//
//  NavigationDestination+DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

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
}
