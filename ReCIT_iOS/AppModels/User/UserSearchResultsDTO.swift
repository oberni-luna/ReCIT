//
//  UserSearchResultsDTO.swift
//  ReCIT_iOS
//
//  What `GET /api/search?types=users` answers with.
//
//  Its own DTO rather than `SearchResultDTO`, because a user result has **no `uri`** — only an
//  id, a label, a picture and a score — where `SearchResultDTO.uri` is non-optional. Making
//  that field optional for everyone would have loosened the entity search, which does always
//  carry one, to accommodate a payload that is simply a different shape.
//

import Foundation

struct UserSearchResultsDTO: Codable {
    let results: [UserSearchResultDTO]
}

struct UserSearchResultDTO: Codable {
    let id: String
    let type: String
    let label: String
    let image: String?
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case label
        case image
        case score = "_score"
    }
}
