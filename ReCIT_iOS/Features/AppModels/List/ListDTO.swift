//
//  ListDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//

import Foundation

// MARK: List base DTO
struct ListsDTO: Codable {
    let total: Int
    let lists: [ListDTO]
}

struct ListDTO: Codable {
    let _id: String
    let _rev: String
    let name: String
    let created: Double
    let updated: Double?
    let visibility: [String]
    let type: String
}

struct ListElementDTO: Codable {
    let _id: String
    let _rev: String
    let list: String
    let uri: String
    let ordinal: String
    let created: Double
    let updated: Double?
    let comment: String?
}

// MARK: Add to list
struct AddToListDTO: Codable {
    let id: String
    let uris: [String]
}

struct AddToListResponseDTO: Codable {
    let ok: Bool
    let createdElements: [ListElementDTO]
}

// MARK: Create list
struct NewListDTO: Codable {
    let name: String
    let description: String
    let visibility: [String]
    let type: String
}

struct NewListResponseDTO: Codable {
    let list: ListDTO
}


