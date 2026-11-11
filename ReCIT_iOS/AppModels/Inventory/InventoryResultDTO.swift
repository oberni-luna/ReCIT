//
//  InventoryResultDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 02/12/2025.
//

import Foundation

nonisolated
struct InventoryResultDTO: Codable {
    let worksTree: InventoryWorkTreeDTO
    let workUriItemsMap: [String: [String]]
    let totalItems: Int
}

nonisolated
struct InventoryWorkTreeDTO: Codable {
    let author: [String: [String]]
    let genre: [String: [String]]
    let owner: [String: [String: [String]]] // owner -> work -> [itemId]
}
