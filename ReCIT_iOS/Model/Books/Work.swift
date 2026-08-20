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

    /// Human-readable French genre labels resolved from the work's Wikidata
    /// `wdt:P136` claim. Stored as labels rather than `wd:Q…` uris because the
    /// only consumer is a language model designing a shelf taxonomy, which needs
    /// words. Additive with a default so SwiftData migrates lightly.
    var genres: [String] = []

    /// When the genre backfill last resolved this work, `nil` if never. An empty
    /// `genres` list is ambiguous on its own — Wikidata simply has no genre for
    /// many French mid-list titles — so this marker is what stops a second run
    /// re-fetching a work already known to have none.
    var genresEnrichedAt: Date?

    /// Which reading of the claims produced `genres` — see `GenreClaims.revision`. Additive,
    /// so lightweight migration covers it, and a work carried over from before this property
    /// existed reads as revision 0 and is therefore re-asked once.
    var genresRevision: Int = 0

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

    /// Records the outcome of a genre backfill pass, including the empty one:
    /// "asked, and Wikidata had nothing" is a result worth persisting, not a
    /// failure to retry on every run.
    func applyEnrichedGenres(_ genres: [String]) {
        self.genres = genres
        genresEnrichedAt = .now
        genresRevision = GenreClaims.revision
    }

    enum Constant {
        static let imageBaseUrl: String = "https://inventaire.io"
    }
}
