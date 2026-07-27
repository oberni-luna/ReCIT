//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Work: Identifiable, Entity {
    @Attribute(.unique) var uri: String
    var lastrevid: Int

    var title: String
    var subtitle: String?
    var originalLang: String?
    var image: String?
    var publicationDate: Date?
    var extract: WpExtract?

    @Relationship(inverse: \Author.works) var authors: [Author] = []
    @Relationship(inverse: \Edition.works) var editions: [Edition] = []

    init (uri: String, lastrevid: Int, title: String, originalLang: String? = nil, image: String? = nil, publicationDate: Date? = nil, authors: [Author] = [], editions: [Edition] = [], subtitle: String? = nil) {
        self.uri = uri
        self.lastrevid = lastrevid
        self.title = title
        self.originalLang = originalLang
        self.image = image
        self.publicationDate = publicationDate
        self.authors = authors
        self.editions = editions
        self.subtitle = subtitle
    }

    convenience init (entityDTO: EntityResultDTO, authors: [Author], apiService: APIServicing) {
        let imageUrl: String? = apiService.absoluteImageUrl(entityDTO.image?.url)

        let publicationDateString: String? = entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.getStringValue()

        self.init(
            uri: entityDTO.uri,
            lastrevid: entityDTO.lastrevid ?? 0,
            title: entityDTO.labels["fr"] ?? entityDTO.labels["en"] ?? entityDTO.labels.values.first ?? "Unknown",
            originalLang: entityDTO.originalLang, 
            image: imageUrl,
            publicationDate: publicationDateString?.parseToDate() ??
            publicationDateString?.parseToDate(dateFormat: "YYYY-MM"),
            authors: authors,
            subtitle: entityDTO.descriptions?["fr"] ?? entityDTO.descriptions?["en"]
        )
    }

    /// Updates the stored fields in place from a freshly fetched DTO.
    /// Only non-empty remote values overwrite existing ones, so a sparse
    /// server response never wipes data we already have. Relationships
    /// (authors, editions) are handled by the caller.
    func update(entityDTO: EntityResultDTO, apiService: APIServicing) {
        let publicationDateString: String? = entityDTO.claims[WikidataProperty.dateOfDeath.rawValue]?.first?.getStringValue()

        lastrevid = entityDTO.lastrevid ?? lastrevid
        if let title = entityDTO.labels["fr"] ?? entityDTO.labels["en"] ?? entityDTO.labels.values.first, !title.isEmpty {
            self.title = title
        }
        if let originalLang = entityDTO.originalLang {
            self.originalLang = originalLang
        }
        if let image = apiService.absoluteImageUrl(entityDTO.image?.url), !image.isEmpty {
            self.image = image
        }
        if let publicationDate = publicationDateString?.parseToDate() ?? publicationDateString?.parseToDate(dateFormat: "YYYY-MM") {
            self.publicationDate = publicationDate
        }
        if let subtitle = entityDTO.descriptions?["fr"] ?? entityDTO.descriptions?["en"] {
            self.subtitle = subtitle
        }
    }

    enum Constant {
        static let imageBaseUrl: String = "https://inventaire.io"
    }
}
