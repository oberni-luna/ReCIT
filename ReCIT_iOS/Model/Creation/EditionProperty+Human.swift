//
//  EditionProperty+Human.swift
//  ReCIT_iOS
//
//  What inventaire.io accepts on a person, read on 2026-10-28 from `GET /api/data/properties`
//  (the `subjectTypes` that hold `human`) and `properties_values_constraints.ts`. « Modifier
//  l'auteur·ice », Figma `A1` (`815:7335`).
//
//  Left out: `wdt:P31`, whose one allowed value is « être humain », `invp:P1` and `invp:P3`. A
//  person's name is a label per language, and their portrait comes from Wikidata — `invp:P2`
//  is an edition's alone.
//

import Foundation

extension EditionProperty {

    // MARK: - L'auteur·ice

    static let pseudonym: EditionProperty = .init(uri: "wdt:P742", kind: .text, group: .general, isMultivalued: true, label: "entity_property.pseudonym")
    static let writingLanguages: EditionProperty = .init(uri: "wdt:P1412", kind: .entity(.languages), group: .general, isMultivalued: true, label: "entity_property.writing_languages")
    static let birthDate: EditionProperty = .init(uri: "wdt:P569", kind: .date, group: .general, isMultivalued: false, label: "entity_property.birth_date")
    static let deathDate: EditionProperty = .init(uri: "wdt:P570", kind: .date, group: .general, isMultivalued: false, label: "entity_property.death_date")

    // MARK: - Courant et influences

    static let movement: EditionProperty = .init(uri: "wdt:P135", kind: .entity(.movements), group: .influences, isMultivalued: true, label: "entity_property.movement")
    static let influencedBy: EditionProperty = person("wdt:P737", "entity_property.influenced_by", group: .influences)

    // MARK: - Databases, links, misc

    static let humanDatabases: [EditionProperty] = [
        database("wdt:P213", "entity_property.isni", #"^[0]{7}[0-9]{8}[0-9X]$"#, "0000000122974701"),
        database("wdt:P268", "edition_property.bnf", #"^\d{8}[0-9bcdfghjkmnpqrstvwxz]$"#, "123735831"),
        database("wdt:P269", "entity_property.idref", #"^\d{8}[\dX]$"#, "026927608"),
        database("wdt:P3630", "entity_property.babelio", #"^\d+$"#, "2615"),
        database("wdt:P648", "edition_property.open_library", #"^OL[1-9]\d{0,7}A$"#, "OL396182A"),
        database("wdt:P2963", "edition_property.goodreads", #"^[1-9]\d*$"#, "428754"),
        database("wdt:P14412", "entity_property.senscritique", #"^[1-9]\d*$"#, "1140742"),
        database("wdt:P214", "edition_property.viaf", #"^[1-9]\d(\d{0,7}|\d{17,20})$"#, "120062731"),
        database("wdt:P227", "edition_property.gnd", #"^1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$"#, "4079154-3"),
        database("wdt:P243", "edition_property.oclc", #"^0*[1-9]\d*$"#, "57722711"),
        database("wdt:P244", "entity_property.library_of_congress", #"^(gf|n|nb|nr|no|ns|sh|sj)([4-9][0-9]|00|20[0-2][0-9])[0-9]{6}$"#, "n79022935"),
        database("wdt:P496", "entity_property.orcid", #"^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$"#, "0000-0002-1003-5675"),
        database("wdt:P4285", "entity_property.theses_fr", #"^\d{8}[\dX]$"#, "026779528"),
        database("wdt:P4369", "entity_property.cairn", #"^[1-9]\d{0,5}$"#, "6930"),
        database("wdt:P1960", "entity_property.google_scholar", #"^[\w-]{12}$"#, "CUO0vDcAAAAJ"),
        database("wdt:P950", "edition_property.bne", #"^XX\d{4,7}$"#, "XX1718747"),
        database("wdt:P5361", "entity_property.bnb", #"^[^ ?.=]{2,80}$"#, "ShakespeareWilliam1564-1616"),
        database("wdt:P349", "entity_property.ndl", #"^(a1|s)?[0-9]?\d{8}$"#, "00564222"),
        database("wdt:P906", "entity_property.selibr", #"^[1-9]\d{4,5}$"#, "207435"),
        database("wdt:P1006", "entity_property.nta", #"^\d{8}(\d|X)$"#, "069071632"),
        database("wdt:P7400", "entity_property.librarything", #"^[^\s/]+$"#, "longemmajde"),
        database("wdt:P1233", "edition_property.isfdb", #"^[1-9]\d{0,5}$"#, "5"),
        database("wdt:P5570", "edition_property.noosfere", #"^-?[1-9]\d*$"#, "16"),
        database("wdt:P5491", "entity_property.bd_gest", #"^[1-9]\d*$"#, "11154"),
        database("wdt:P2607", "edition_property.bookbrainz", #"[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}"#, "5291de51-0ec8-473e-98a3-baf5a7500ef3"),
        database("wdt:P12430", "entity_property.storygraph", #"[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}"#, "9652222f-c517-42c7-bbe6-06e45afaac19"),
        database("wdt:P1982", "entity_property.anime_news_network", #"^[1-9]\d{0,5}$"#, "15"),
        database("wdt:P4084", "entity_property.myanimelist", #"^\d+$"#, "1870"),
        database("wdt:P9707", "entity_property.grand_comics_database", #"^[1-9]\d*$"#, "16448")
    ]

    /// An edition's ten links, and a LinkedIn profile.
    static let humanLinks: [EditionProperty] = links + [
        link("wdt:P6634", "entity_property.linkedin", #"^[\p{L}0-9\-&_'’.]+$"#, "jbkempf")
    ]

    static let humanDifferentFrom: EditionProperty = .init(uri: "wdt:P1889", kind: .entity(.humans), group: .misc, isMultivalued: true, label: "entity_property.different_from")

    /// Every property of a person, in the order « Modifier l'auteur·ice » shows them.
    static let humanProperties: [EditionProperty] = [pseudonym, writingLanguages, birthDate, deathDate, movement, influencedBy]
        + humanDatabases + humanLinks + [humanDifferentFrom]
}
