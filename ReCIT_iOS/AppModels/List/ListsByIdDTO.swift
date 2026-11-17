//
//  ListsByIdDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

/// `GET /api/lists/by-ids`: the lists asked for, keyed by id, where `by-creators` answers an array.
struct ListsByIdDTO: Codable {
    let lists: [String: ListDTO]
}
