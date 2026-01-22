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
    var subtitle: String?
    var dateOfBirth: Date?
    var dateOfDeath: Date?
    var image: String?

    var works: [Work] = []

    init(uri: String, lastrevid: Int, name: String, dateOfBirth: Date? = nil, dateOfDeath: Date? = nil, image: String? = nil, subtitle: String? = nil) {
        self.uri = uri
        self.lastrevid = lastrevid
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.dateOfDeath = dateOfDeath
        self.image = image
        self.subtitle = subtitle
    }

    convenience init (entityDTO: EntityResultDTO) {
        let imageUrl: String? = if let img = entityDTO.image?["url"] { "\(Constant.imageBaseUrl)\(img)" } else { nil }

        let dateOfBirthString: String? = entityDTO.claims[WikidataProperty.dateOfBirth.rawValue]?.first?.getStringValue()
        let dateOfDeathString: String? = entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.getStringValue()

        self.init(
            uri: entityDTO.uri,
            lastrevid: entityDTO.lastrevid ?? 0,
            name: entityDTO.labels["fr"] ?? entityDTO.labels["en"] ?? "",
            dateOfBirth: dateOfBirthString?.parseToDate(),
            dateOfDeath: dateOfDeathString?.parseToDate(),
            image: imageUrl,
            subtitle: entityDTO.descriptions?["fr"] ?? entityDTO.descriptions?["en"]
        )
    }

    enum Constant {
        static let imageBaseUrl: String = "https://commons.wikimedia.org/wiki/Special:FilePath/"
    }
}



