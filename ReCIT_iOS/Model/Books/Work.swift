//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Work: Identifiable {
    @Attribute(.unique) var uri: String
    var lastrevid: Int

    var title: String
    var originalLang: String?
    var image: String?
    var publicationDate: Date?

    @Relationship(inverse: \Author.works) var authors: [Author] = []
    @Relationship(inverse: \Edition.works) var editions: [Edition] = []

    init (uri: String, lastrevid: Int, title: String, originalLang: String? = nil, image: String? = nil, publicationDate: Date? = nil, authors: [Author] = [], editions: [Edition] = []) {
        self.uri = uri
        self.lastrevid = lastrevid
        self.title = title
        self.originalLang = originalLang
        self.image = image
        self.publicationDate = publicationDate
        self.authors = authors
        self.editions = editions
    }

    convenience init (entityDTO: EntityResultDTO, authors: [Author]) {
        let imageUrl: String? = if let img = entityDTO.image?["url"] { "\(Constant.imageBaseUrl)\(img)" } else { nil }

        self.init(
            uri: entityDTO.uri,
            lastrevid: entityDTO.lastrevid ?? 0,
            title: entityDTO.labels["fr"] ?? entityDTO.labels["en"] ?? "",
            originalLang: entityDTO.originalLang, 
            image: imageUrl,
            publicationDate: entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.parseToDate() ??
                entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.parseToDate(dateFormat: "YYYY-MM"),
            authors: authors
        )
    }

    enum Constant {
        static let imageBaseUrl: String = "https://inventaire.io"
    }
}
