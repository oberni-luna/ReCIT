//
//  InventoryItemTextAttribute.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation

/// A text the owner writes on a book, under the attribute name `PUT /api/items/bulk-update` takes.
enum InventoryItemTextAttribute: String {
    /// The Commentaire, seen by whoever can see the book.
    case details
    /// The Note privée, seen by the owner alone.
    case notes

    var keyPath: ReferenceWritableKeyPath<InventoryItem, String> {
        switch self {
        case .details: \.details
        case .notes: \.notes
        }
    }
}
