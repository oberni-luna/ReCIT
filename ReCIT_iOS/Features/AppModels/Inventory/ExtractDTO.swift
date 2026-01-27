//
//  ExtractDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import Foundation

struct ExtractDTO: Codable {
    let extract: String
    let url: String
}

struct SummariesDTO: Codable {
    let summaries: [SummaryDTO]
}

struct SummaryDTO: Codable {
    let key: String
    let name: String
    let lang: String
    let link: String
    let sitelink: SitelinkDTO?
}

struct SitelinkDTO: Codable {
    let title: String
    let lang: String
}
