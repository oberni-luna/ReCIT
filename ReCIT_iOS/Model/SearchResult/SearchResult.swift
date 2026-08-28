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

// MARK: - Equality, written out rather than synthesised
//
// `localItem` is a SwiftData `@Model`, and a `@Model` gets its `Hashable` from `PersistentModel`
// — a conformance the macro attaches, which the compiler only sees from another file when both
// land in the same batch of a batch-mode build. Synthesising this conformance therefore compiled
// or did not depending on how the module's files happened to be partitioned that day: adding one
// unrelated file anywhere in the target moved `SearchResult.swift` into a batch without
// `InventoryItem.swift` and the build failed with "type 'SearchResult' does not conform to
// protocol 'Hashable'", pointing at a file nobody had touched. Importing SwiftData here does not
// help — the conformance is not hidden, it is not yet expanded.
//
// Writing the two witnesses out removes the dependency on that conformance entirely. The
// semantics are the ones synthesis gave: every stored property compared, with the model compared
// by identity — which within a `ModelContext`, where objects are uniqued, is the same answer
// `PersistentModel`'s own `==` returns. `hash(into:)` folds only `id`, which is this type's
// identity and is legal for any pair this `==` calls equal.
extension SearchResult {
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
            && lhs.uri == rhs.uri
            && lhs.title == rhs.title
            && lhs.description == rhs.description
            && lhs.imageUrl == rhs.imageUrl
            && lhs.score == rhs.score
            && lhs.type == rhs.type
            && lhs.localItem === rhs.localItem
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
