//
//  GroupSearchResultsDTO.swift
//  ReCIT_iOS
//
//  What `GET /api/search?types=groups` answers with: an id, a name, sometimes a description and
//  a picture. Nothing about who is in it or whether it is open — the group's own screen fetches
//  that.
//

import Foundation

struct GroupSearchResultsDTO: Codable {
    let results: [GroupSearchResultDTO]
}

struct GroupSearchResultDTO: Codable {
    let id: String
    let label: String
    let description: String?
    let image: String?
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case description
        case image
        case score = "_score"
    }
}
