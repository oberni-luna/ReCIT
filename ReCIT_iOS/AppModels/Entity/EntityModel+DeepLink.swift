//
//  EntityModel+DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 15/11/2026.
//

import Foundation
import SwiftData

extension EntityModel {
    /// The screen for an entity inventaire.io described. Its own `uri` rather than the one linked:
    /// a merged `inv:` entity answers under the uri it was merged into.
    static func destination(for entity: EntityResultDTO) -> NavigationDestination? {
        switch entity.type {
        case "edition":
            .book(anchor: .edition(uri: entity.uri))
        case "work":
            // A work is not a book: the book screen picks the edition, as it does for a search
            // result (ADR 0002, Move 3). The label fills the header while it does.
            .book(
                anchor: .bestEditionOfWork(
                    uri: entity.uri,
                    title: EntityLabel.resolve(entity.labels, originalLang: entity.originalLang) ?? "",
                    imageUrl: nil
                )
            )
        case "human":
            .author(uri: entity.uri)
        default:
            nil
        }
    }

    /// The screen a link to `uri` opens, or `nil` when inventaire.io has no such entity, or one of a
    /// type the app has no screen for. An `isbn:` uri is an edition by construction; any other one —
    /// `wd:`, `inv:` — may be a work, an edition or a person, and only inventaire.io knows which, so
    /// it is asked through `by-uris`, the same request the book screen makes.
    func destination(
        forLinkedURI uri: String,
        modelContext: ModelContext
    ) async throws -> NavigationDestination? {
        if uri.hasPrefix("isbn:") {
            return .book(anchor: .edition(uri: uri))
        }

        guard let entity = try await fetchEntities(modelContext: modelContext, uris: [uri])?.first else {
            return nil
        }
        return Self.destination(for: entity)
    }
}
