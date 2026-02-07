//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Author: Identifiable, Entity {
    @Attribute(.unique) var uri: String
    var lastrevid: Int

    var name: String
    var subtitle: String?
    var dateOfBirth: Date?
    var dateOfDeath: Date?
    var image: String?

    var works: [Work] = []
    var extract: WpExtract?

    var title: String { name }

    init(uri: String, lastrevid: Int, name: String, dateOfBirth: Date? = nil, dateOfDeath: Date? = nil, image: String? = nil, subtitle: String? = nil) {
        self.uri = uri
        self.lastrevid = lastrevid
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.dateOfDeath = dateOfDeath
        self.image = image
        self.subtitle = subtitle
    }

    convenience init (entityDTO: EntityResultDTO, apiService: APIService) {
        let imageUrl: String? = apiService.absoluteImageUrl(entityDTO.image?.url)

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
//        https://inventaire.io/img/remote/192x192/1170121628?href=https%3A%2F%2Fcommons.wikimedia.org%2Fwiki%2FSpecial%3AFilePath%2FFIBD2022Ceremonie%252007b.jpg%3Fwidth%3D1024
        static let imageBaseUrl: String = "https://commons.wikimedia.org/wiki/Special:FilePath/"
    }
}



