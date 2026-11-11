//
//  AuthorWorksDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import Foundation

nonisolated
struct AuthorWorkDTO: Codable {
    let uri: String
    let score: Int?
}

nonisolated
struct AuthorWorksDTO: Codable {
    let works: [AuthorWorkDTO]
}
