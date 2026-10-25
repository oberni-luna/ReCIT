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
    /// The work this is an edition of, `wdt:P629`. `nil` for an edition attached to none.
    var workUri: String?
    /// The language the edition's own labels were written in: the one the labels of a work or
    /// an author created from the form are written in too.
    let labelLanguage: String?

    init(
        uri: String,
        title: String,
        subtitle: String? = nil,
        coverHash: String? = nil,
        isbn: String = "",
        workUri: String? = nil,
        labelLanguage: String? = nil
    ) {
        self.uri = uri
        self.title = title
        self.subtitle = subtitle
        self.coverHash = coverHash
        self.isbn = isbn
        self.workUri = workUri
        self.labelLanguage = labelLanguage
    }

    /// Reads one entity of a `by-uris` answer. Answers `nil` for anything but an `inv:`
    /// edition: there is nothing the form could send about it.
    init?(dto: EditableEditionDTO) {
        guard dto.uri.hasPrefix("inv:") else { return nil }

        self.init(
            uri: dto.uri,
            title: dto.firstValue(of: EditableClaimProperty.title.rawValue) ?? "",
            subtitle: dto.firstValue(of: EditableClaimProperty.subtitle.rawValue),
            coverHash: dto.firstValue(of: EditableClaimProperty.cover.rawValue),
            isbn: dto.firstValue(of: WikidataProperty.isbn13.rawValue)
                ?? dto.firstValue(of: WikidataProperty.isbn10.rawValue)
                ?? "",
            workUri: dto.firstValue(of: EditableClaimProperty.work.rawValue),
            labelLanguage: dto.originalLang
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
