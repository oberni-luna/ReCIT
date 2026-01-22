//
//  NewItemDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/01/2026.
//
import Foundation

struct NewItemDTO: Codable {
    let entity: String
    let details: String?
    let notes: String?
    let transaction: String
    let visibility: [String]
    let shelves: [String]
}
