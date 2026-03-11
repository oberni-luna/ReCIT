//
//  SearchResult.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/01/2026.
//

import CoreFoundation

struct SearchResult: Identifiable, Hashable {
    let id: String
    let uri: String
    let title: String
    let description: String?
    let imageUrl: String?
    let score: CGFloat
    let type: SearchResultType
    let localItem: InventoryItem?

    init(
        id: String,
        uri: String,
        title: String,
        description: String? = nil,
        imageUrl: String? = nil,
        score: CGFloat,
        type: SearchResultType,
        localItem: InventoryItem? = nil
    ) {
        self.id = id
        self.uri = uri
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.score = score
        self.type = type
        self.localItem = localItem
    }
}

enum SearchResultType: String {
    case works = "works"
    case humans = "humans"
    case genres = "genres"
    case publishers = "publishers"
    case series = "series"
    case collections = "collections"
    case movements = "movements"
    case languages = "languages"
    case users = "users"
    case groups = "groups"
    case shelves = "shelves"
    case lists = "list"
    case inventoryItem = "inventory-item"
    case unknown = ""
}
