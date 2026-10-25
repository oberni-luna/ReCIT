//
//  EditionClaims.swift
//  ReCIT_iOS
//
//  What inventaire.io holds about an edition, as « Modifier l'édition » opens: the values the
//  form starts from, and the old values every change has to name. `update-claim` replaces a
//  value only when it is told which one it replaces, so these are read fresh from the server
//  rather than taken from the local `Edition`, which keeps a display title and an image url.
//
//  The uri is the **canonical** one, `inv:…`: an edition opened from its ISBN is `isbn:…` in
//  the store, and `by-uris` redirects it. `update-claim` takes `inv:` and `wd:` uris only, and
//  a `wd:` edition lives on Wikidata, where editing needs an account this app does not hold —
//  which is why the book screen offers « Modifier » for every edition but those.
//
//  Besides the claims the form has always changed — title, subtitle, cover, work — it holds every
//  other property of the catalogue (`EditionProperties`), its entities named.
//

import Foundation

struct EditionClaims: Equatable, Sendable {
    let uri: String
    var title: String
    var subtitle: String?
    /// The hash `invp:P2` holds, the cover's name in `/img/entities/`.
    var coverHash: String?
    /// As inventaire.io prints it, hyphens included: the ISBN-13, or the ISBN-10 when there is
    /// no other. Empty for an edition with neither.
    let isbn: String
    /// The ISBN-10, when it is shown under an ISBN-13. Never sent: the server infers it.
    let isbn10: String?
    /// The works this is an edition of, `wdt:P629`: one, several for a collection of works, none
    /// for an edition attached to nothing.
    var workUris: [String]
    /// The language the edition's own labels were written in: the one the labels of a work or
    /// an author created from the form are written in too.
    let labelLanguage: String?
    /// The rest of what the edition says: publisher, date, format, contributors, identifiers.
    var properties: EditionProperties

    init(
        uri: String,
        title: String,
        subtitle: String? = nil,
        coverHash: String? = nil,
        isbn: String = "",
        isbn10: String? = nil,
        workUris: [String] = [],
        labelLanguage: String? = nil,
        properties: EditionProperties = .init()
    ) {
        self.uri = uri
        self.title = title
        self.subtitle = subtitle
        self.coverHash = coverHash
        self.isbn = isbn
        self.isbn10 = isbn10
        self.workUris = workUris
        self.labelLanguage = labelLanguage
        self.properties = properties
    }

    /// Reads one entity of a `by-uris` answer, its entity values named with `labels`. Answers
    /// `nil` for anything but an `inv:` edition: there is nothing the form could send about it.
    init?(
        dto: EditableEditionDTO,
        labels: [String: String] = [:]
    ) {
        guard dto.uri.hasPrefix("inv:"), dto.type == nil || dto.type == "edition" else { return nil }

        let isbn13: String? = dto.firstValue(of: WikidataProperty.isbn13.rawValue)
        let isbn10: String? = dto.firstValue(of: WikidataProperty.isbn10.rawValue)

        self.init(
            uri: dto.uri,
            title: dto.firstValue(of: EditableClaimProperty.title.rawValue) ?? "",
            subtitle: dto.firstValue(of: EditableClaimProperty.subtitle.rawValue),
            coverHash: dto.firstValue(of: EditableClaimProperty.cover.rawValue),
            isbn: isbn13 ?? isbn10 ?? "",
            isbn10: isbn13 == nil ? nil : isbn10,
            workUris: dto.claims?[EditableClaimProperty.work.rawValue]?.compactMap { $0.getStringValue() } ?? [],
            labelLanguage: dto.originalLang,
            properties: .init(claims: dto.claims ?? [:], labels: labels)
        )
    }

    /// The ISBN without its separators, the form the image search is asked with.
    var normalizedISBN: String {
        isbn.uppercased().filter { $0.isNumber || $0 == "X" }
    }

    /// Whether the book screen offers to edit the edition behind this uri: every one but a
    /// Wikidata edition.
    static func canEdit(uri: String) -> Bool {
        uri.hasPrefix("wd:") == false
    }
}
