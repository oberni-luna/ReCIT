//
//  SearchResultsDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//

import Foundation

struct SearchResultsDTO: Codable {
    let results: [SearchResultDTO]
}

struct SearchResultDTO: Codable {
    let id: String
    let type: String
    let uri: String
    let label: String
    let description: String?
    let image: String?
    let score: CGFloat?

    /// The server names the score `_score`. Read as `score`, it was always `nil`, and the sort
    /// by descending score in `SearchModel` had nothing to sort on.
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case uri
        case label
        case description
        case image
        case score = "_score"
    }
}
