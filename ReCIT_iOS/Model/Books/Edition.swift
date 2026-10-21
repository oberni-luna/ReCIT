//
//  Entity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import SwiftData

@Model
public class Edition: Identifiable, Entity {
    @Attribute(.unique) var uri: String

    var title: String
    var subtitle: String?
    var lang: String?
    var authorNames: [String]
    var image: String?
    var series: String?
    var works: [Work] = []
    var extract: WpExtract?

    /// Dominant colour of the cover (hex, e.g. "#7A2E2E"), extracted lazily from the
    /// cover image and persisted so painted shelf spines render without recompute.
    /// `nil` until first computed. See ADR 0003.
    var dominantColorHex: String?

    /// Number of pages (Wikidata P1104), fetched lazily to size the painted spine's
    /// thickness. `nil` until fetched (and when the edition has no such claim).
    var numberOfPages: Int?

    @Relationship(deleteRule: .nullify, inverse: \InventoryItem.edition) var items: [InventoryItem] = []

    var authors: [Author] {
        Array(Set(works.flatMap(\.authors)))
    }

    /// The names a row of books shows under the title: the item snapshot's, in the server's
    /// order, or — for an edition no snapshot has named yet — those of its works' authors.
    ///
    /// The fallback is not decoration. An edition first fetched as an entity (the scanner, the
    /// search, the book screen) has no names: `init(entityDto:)` has none to give. Until a
    /// snapshot fills them in, its row used to show a title and nothing under it.
    var displayedAuthorNames: [String] {
        guard authorNames.isEmpty else { return authorNames }
        return authors.map(\.name)
            .filter { $0.isEmpty == false }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    var workUris: [String] {
        if self.works.isEmpty == false {
            Array(Set(self.works.map(\.uri)))
        } else {
            []
        }
    }

    init(uri: String, title: String, subtitle: String? = nil, lang: String?, authorNames: [String], image: String? = nil, series: String? = nil, items: [InventoryItem] = []) {
        self.uri = uri
        self.title = title
        self.subtitle = subtitle
        self.lang = lang
        self.authorNames = authorNames
        self.image = image
        self.series = series
    }

    convenience init(uri: String, entitySnapshotDTO: EntitySnapshotDTO, apiService: APIServicing, works: [Work] = [], items: [InventoryItem] = []) {
        self.init(
            uri: uri,
            title: entitySnapshotDTO.`entity:title`,
            subtitle: entitySnapshotDTO.`entity:subtitle`,
            lang: entitySnapshotDTO.`entity:lang`,
            authorNames: entitySnapshotDTO.authorNames,
            image: apiService.absoluteImageUrl(entitySnapshotDTO.`entity:image`),
            series: entitySnapshotDTO.`entity:series`
        )
    }

    convenience init(entityDto: EntityResultDTO, apiService: APIServicing) {
        self.init(
            uri: entityDto.uri,
            // Through `EditionTitle`, not `labels["fromclaims"]` alone: an edition mirrored from
            // Wikidata carries its title under `mul`, and reading only `fromclaims` is what used
            // to name 13 % of a work's editions `Unknown` on screen.
            title: EditionTitle.resolve(labels: entityDto.labels, claims: entityDto.claims) ?? "Unknown",
            subtitle: entityDto.descriptions?["fromclaims"],
            lang: entityDto.originalLang,
            authorNames: [],
            image: apiService.absoluteImageUrl(entityDto.image?.url ?? "")
        )
    }

    /// Takes the author names an item's snapshot carries. The entity never gives any, so the
    /// snapshot is their only source; a snapshot that names none leaves the ones held.
    func mergeAuthorNames(from snapshot: EntitySnapshotDTO) {
        let names: [String] = snapshot.authorNames
        guard names.isEmpty == false else { return }
        authorNames = names
    }

    /// Adds the works this edition is not filed under yet. By uri, so asking twice adds nothing.
    func mergeWorks(_ newWorks: [Work]) {
        var known: Set<String> = .init(works.map(\.uri))
        for work in newWorks where known.insert(work.uri).inserted {
            works.append(work)
        }
    }

    /// Updates the stored fields in place from a freshly fetched DTO.
    /// Only non-empty remote values overwrite existing ones, so a sparse
    /// server response never wipes data we already have. The `works`
    /// relationship is handled by the caller.
    func update(entityDto: EntityResultDTO, apiService: APIServicing) {
        if let title = EditionTitle.resolve(labels: entityDto.labels, claims: entityDto.claims) {
            self.title = title
        }
        if let subtitle = entityDto.descriptions?["fromclaims"] {
            self.subtitle = subtitle
        }
        if let lang = entityDto.originalLang {
            self.lang = lang
        }
        if let image = apiService.absoluteImageUrl(entityDto.image?.url ?? ""), !image.isEmpty {
            self.image = image
        }
    }
}
