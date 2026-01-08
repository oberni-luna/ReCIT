//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Author: Identifiable {
    @Attribute(.unique) var uri: String
    var lastrevid: Int

    var name: String
    var dateOfBirth: Date?
    var dateOfDeath: Date?
    var image: String?

    var works: [Work] = []

    init(uri: String, lastrevid: Int, name: String, dateOfBirth: Date? = nil, dateOfDeath: Date? = nil, image: String? = nil) {
        self.uri = uri
        self.lastrevid = lastrevid
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.dateOfDeath = dateOfDeath
        self.image = image
    }

    convenience init (entityDTO: EntityResultDTO) {
        let imageUrl: String? = if let img = entityDTO.image?["url"] { "\(Constant.imageBaseUrl)\(img)" } else { nil }

        self.init(
            uri: entityDTO.uri,
            lastrevid: entityDTO.lastrevid ?? 0,
            name: entityDTO.labels["fr"] ?? entityDTO.labels["en"] ?? "",
            dateOfBirth: entityDTO.claims[WikidataProperty.dateOfBirth.rawValue]?.first?.parseToDate(),
            dateOfDeath: entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.parseToDate(),
            image: imageUrl
        )
    }

    enum Constant {
        static let imageBaseUrl: String = "https://commons.wikimedia.org/wiki/Special:FilePath/"
    }
}



