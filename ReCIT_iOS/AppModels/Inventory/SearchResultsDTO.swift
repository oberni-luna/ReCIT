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
}
