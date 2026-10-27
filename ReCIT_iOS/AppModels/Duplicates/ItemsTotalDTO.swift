//
//  ItemsTotalDTO.swift
//  ReCIT_iOS
//
//  `GET /api/items/by-entities` read for its count alone: `total` is how many copies of the
//  entities asked this account can see. PRD 0028.
//

import Foundation

struct ItemsTotalDTO: Codable {
    let total: Int
}
