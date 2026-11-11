//
//  ExtractDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import Foundation

nonisolated
struct ExtractDTO: Codable {
    let extract: String
    let url: String
}

nonisolated
struct SummariesDTO: Codable {
    let summaries: [SummaryDTO]
}

nonisolated
struct SummaryDTO: Codable {
    let key: String
    let name: String
    let lang: String
    let link: String
    let sitelink: SitelinkDTO?
    let text: String?
}

nonisolated
struct SitelinkDTO: Codable {
    let title: String
    let lang: String
}
