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

    convenience init (entityDTO: EntityResultDTO, apiService: APIServicing) {
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

    /// Updates the stored fields in place from a freshly fetched DTO.
    /// Only non-empty remote values overwrite existing ones, so a sparse
    /// server response never wipes data we already have.
    func update(entityDTO: EntityResultDTO, apiService: APIServicing) {
        let dateOfBirthString: String? = entityDTO.claims[WikidataProperty.dateOfBirth.rawValue]?.first?.getStringValue()
        let dateOfDeathString: String? = entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.getStringValue()

        lastrevid = entityDTO.lastrevid ?? lastrevid
        if let name = entityDTO.labels["fr"] ?? entityDTO.labels["en"], !name.isEmpty {
            self.name = name
        }
        if let dateOfBirth = dateOfBirthString?.parseToDate() {
            self.dateOfBirth = dateOfBirth
        }
        if let dateOfDeath = dateOfDeathString?.parseToDate() {
            self.dateOfDeath = dateOfDeath
        }
        if let image = apiService.absoluteImageUrl(entityDTO.image?.url), !image.isEmpty {
            self.image = image
        }
        if let subtitle = entityDTO.descriptions?["fr"] ?? entityDTO.descriptions?["en"] {
            self.subtitle = subtitle
        }
    }

    enum Constant {
//        https://inventaire.io/img/remote/192x192/1170121628?href=https%3A%2F%2Fcommons.wikimedia.org%2Fwiki%2FSpecial%3AFilePath%2FFIBD2022Ceremonie%252007b.jpg%3Fwidth%3D1024
        static let imageBaseUrl: String = "https://commons.wikimedia.org/wiki/Special:FilePath/"
    }
}



