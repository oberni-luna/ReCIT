//
//  ShelfPreviewStore.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  The store the v2 étagère screens are previewed on: one étagère of mine holding two books,
//  and two more books of mine not on it, with the models those screens read from the
//  environment.
//

import SwiftData
import SwiftUI

struct ShelfPreviewStore: PreviewModifier {
    static let shelfId: String = "preview-shelf"
    static let ownerId: String = "me"

    static func makeSharedContext() throws -> ModelContainer {
        let container: ModelContainer = try .init(
            for: Shelf.self,
            InventoryItem.self,
            Edition.self,
            User.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let shelf: Shelf = .mock(
            id: shelfId,
            name: "Polars nordiques",
            slug: "polars-nordiques",
            shelfDescription: "Tout ce qui se passe dans le froid, de Stockholm à Reykjavik.",
            ownerId: ownerId,
            visibility: ["friends"],
            created: .now.addingTimeInterval(-86_400 * 120),
            updated: .now
        )
        container.mainContext.insert(shelf)

        let titles: [(String, String)] = [
            ("Millénium", "Stieg Larsson"),
            ("La Femme en vert", "Arnaldur Indriðason"),
            ("Le Bonhomme de neige", "Jo Nesbø"),
            ("Meurtres à Fjällbacka", "Camilla Läckberg")
        ]
        for (index, (title, author)) in titles.enumerated() {
            let edition: Edition = .init(
                uri: "isbn:preview-\(index)",
                title: title,
                lang: "fr",
                authorNames: [author]
            )
            let item: InventoryItem = .init(
                _id: "preview-item-\(index)",
                _rev: "1",
                transaction: .inventorying,
                visibility: [],
                ownerId: ownerId,
                created: .now.addingTimeInterval(-3_600 * Double(index)),
                updated: nil,
                busy: nil,
                edition: edition
            )
            container.mainContext.insert(item)
            if index < 2 {
                shelf.items.append(item)
            }
        }
        return container
    }

    func body(
        content: Content,
        context: ModelContainer
    ) -> some View {
        let apiService: APIService = .init(env: .production)
        content
            .modelContainer(context)
            .environment(ShelfModel(apiService: apiService))
            .environment(UserModel(apiService: apiService))
    }
}
