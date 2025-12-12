//
//  EntityResultDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import Foundation

struct EntityResultsDTO: Codable {
    let entities: [String : EntityResultDTO]
}

struct EntityResultDTO: Codable {
    let uri: String
    let lastrevid: Int?
    let type: String
    let originalLang: String?
    let labels: [String: String]
    let descriptions: [String: String]?
    let image: [String: String]?
    let claims: [String: [String]]
}

