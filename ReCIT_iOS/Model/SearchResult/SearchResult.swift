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
    case unknown = ""
}
