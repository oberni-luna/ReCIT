//
//  EditionProperty.swift
//  ReCIT_iOS
//
//  The properties of an edition that « Modifier l'édition » shows beyond its title, subtitle,
//  cover and works: everything inventaire.io accepts on an edition, read on 2026-10-25 from
//  `GET /api/data/properties` (the `subjectTypes` that hold `edition`) and from
//  `properties_per_type.ts` in inventaire-client, which says which ones the website shows and in
//  what order. Figma section `Modifier l'édition · Toutes les données` (`750:2508`).
//
//  Left out, as the website leaves them out: `wdt:P31`, which has a single allowed value for an
//  edition, `invp:P1` and `invp:P3`. Left out here alone: `wdt:P1889` (« différent de »), which
//  names another edition, and `/api/search` cannot search editions to pick one from. The ISBNs
//  are not in the catalogue either: they are shown, never sent — the server lets only an admin
//  change `wdt:P212`, and infers `wdt:P957` from it.
//
//  An identifier's pattern is the server's own (`properties_values_constraints.ts`), so a value
//  refused here would have been refused there, with a less useful message.
//

import Foundation

struct EditionProperty: Hashable, Sendable, Identifiable {

    enum Kind: Hashable, Sendable {
        /// `YYYY`, `YYYY-MM` or `YYYY-MM-DD`: a date only as precise as the book is.
        case date
        /// A positive whole number, sent as a JSON number.
        case integer
        /// One of `EditionFormat`'s six uris.
        case format
        /// An entity found by `/api/search` with this type, or created.
        case entity(SearchResultType)
        /// An identifier in a catalogue, checked against the server's pattern.
        case identifier(pattern: String, example: String)
        /// A web address.
        case url
    }

    /// The section of the form a property is shown in.
    enum Group: Hashable, Sendable {
        case publication
        case format
        case contributors
        case databases
        case links
    }

    let uri: String
    let kind: Kind
    let group: Group
    let isMultivalued: Bool
    /// The catalogue key of its name, as the form prints it above the value.
    let label: String

    var id: String { uri }

    /// The type to search for, for a property whose values are entities.
    var searchType: SearchResultType? {
        guard case .entity(let type) = kind else { return nil }
        return type
    }

    /// Whether an entity nobody has entered can be created from the form: a person, a
    /// publisher, a collection. A language is chosen among those Wikidata has.
    var allowsCreation: Bool {
        switch searchType {
        case .humans, .publishers, .collections: true
        default: false
        }
    }

    /// What the reader typed, made into the value that goes on the wire — or `nil` when the
    /// server would refuse it.
    func literal(from text: String) -> ClaimLiteral? {
        let trimmed: String = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        switch kind {
        case .integer:
            guard let integer = Int(trimmed), integer > 0 else { return nil }
            return .integer(integer)
        case .date:
            return PublicationDate(trimmed).map { .string($0.claim) }
        case .identifier(let pattern, _):
            let value: String = Self.normalize(trimmed, for: uri)
            return Self.matches(value, pattern: pattern) ? .string(value) : nil
        case .url:
            guard let url = URL(string: trimmed),
                  let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
                  url.host() != nil else { return nil }
            return .string(trimmed)
        case .format, .entity:
            return .string(trimmed)
        }
    }

    /// The example the server gives for an identifier, shown under the field.
    var example: String? {
        switch kind {
        case .identifier(_, let example): example
        case .url: "https://"
        default: nil
        }
    }

    /// The small rewrites the server makes before it validates: the BnF's `cb` prefix, the `@` a
    /// Mastodon handle is often copied with.
    private static func normalize(_ value: String, for uri: String) -> String {
        switch uri {
        case "wdt:P268":
            value.hasPrefix("cb") ? String(value.dropFirst(2)) : value
        case "wdt:P4033":
            value.hasPrefix("@") ? String(value.dropFirst()) : value
        default:
            value
        }
    }

    /// `RegExp.test` as the server runs it: the pattern carries its own anchors, or none.
    private static func matches(_ value: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range: NSRange = .init(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range) != nil
    }
}

// MARK: - The catalogue

extension EditionProperty {

    static let publisher: EditionProperty = .init(uri: "wdt:P123", kind: .entity(.publishers), group: .publication, isMultivalued: true, label: "edition_property.publisher")
    static let collection: EditionProperty = .init(uri: "wdt:P195", kind: .entity(.collections), group: .publication, isMultivalued: true, label: "edition_property.collection")
    static let publicationDate: EditionProperty = .init(uri: "wdt:P577", kind: .date, group: .publication, isMultivalued: false, label: "edition_property.publication_date")
    static let language: EditionProperty = .init(uri: "wdt:P407", kind: .entity(.languages), group: .publication, isMultivalued: true, label: "edition_property.language")

    static let format: EditionProperty = .init(uri: "wdt:P437", kind: .format, group: .format, isMultivalued: false, label: "edition_property.format")
    static let numberOfPages: EditionProperty = .init(uri: "wdt:P1104", kind: .integer, group: .format, isMultivalued: false, label: "edition_property.pages")
    static let numberOfVolumes: EditionProperty = .init(uri: "wdt:P2635", kind: .integer, group: .format, isMultivalued: false, label: "edition_property.volumes")

    static let contributors: [EditionProperty] = [
        person("wdt:P655", "edition_property.translator"),
        person("wdt:P110", "edition_property.illustrator"),
        person("wdt:P736", "edition_property.cover_artist"),
        person("wdt:P2679", "edition_property.preface"),
        person("wdt:P2680", "edition_property.afterword"),
        person("wdt:P98", "edition_property.editor")
    ]

    static let databases: [EditionProperty] = [
        database("wdt:P268", "edition_property.bnf", #"^\d{8}[0-9bcdfghjkmnpqrstvwxz]$"#, "123735831"),
        database("wdt:P648", "edition_property.open_library", #"^OL[1-9]\d{0,7}M$"#, "OL61173905M"),
        database("wdt:P1025", "edition_property.sudoc", #"^\d{8}[\dX]$"#, "082962995"),
        database("wdt:P214", "edition_property.viaf", #"^[1-9]\d(\d{0,7}|\d{17,20})$"#, "120062731"),
        database("wdt:P243", "edition_property.oclc", #"^0*[1-9]\d*$"#, "57722711"),
        database("wdt:P675", "edition_property.google_books", #"^[\w-]{12}$"#, "7r14FzJdSuAC"),
        database("wdt:P2969", "edition_property.goodreads", #"^[1-9]\d*$"#, "821987"),
        database("wdt:P12351", "edition_property.bookbrainz", #"[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}"#, "e16ac0da-d056-4af1-ab71-f749b035a92e"),
        database("wdt:P6901", "edition_property.noosfere", #"^-?[1-9]\d*$"#, "-322323"),
        database("wdt:P1234", "edition_property.isfdb", #"^[1-9]\d*$"#, "62137"),
        database("wdt:P1292", "edition_property.dnb", #"^\d{8,9}[X\d]?$"#, "450155102"),
        database("wdt:P227", "edition_property.gnd", #"^1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$"#, "4079154-3"),
        database("wdt:P1044", "edition_property.swb", #"^\d{8}[0-9X]$"#, "000619612"),
        database("wdt:P950", "edition_property.bne", #"^(bima|bimo|bipa)\d{10}$"#, "bimo0000459277"),
        database("wdt:P1144", "edition_property.lccn", #"^[a-z]{0,3}\d{6,10}$"#, "11025047"),
        database("wdt:P5199", "edition_property.british_library", #"^\d{9}$"#, "000033859"),
        database("wdt:P1182", "edition_property.libris", #"^[1-9]\d*$"#, "11400617"),
        database("wdt:P1143", "edition_property.bn_argentina", #"^\d{9}$"#, "000188710"),
        database("wdt:P3184", "edition_property.czech_national_bibliography", #"^cnb[0-9]{9}$"#, "cnb000567876"),
        database("wdt:P1844", "edition_property.hathitrust", #"^\d{9}$"#, "012508885"),
        database("wdt:P3155", "edition_property.runeberg", #"^[a-z0-9/.-]+$"#, "aanden"),
        database("wdt:P356", "edition_property.doi", #"(?i)^10.\d{4,9}/[^\s]+$"#, "10.1371/JOURNAL.PONE.0029797")
    ]

    static let links: [EditionProperty] = [
        .init(uri: "wdt:P856", kind: .url, group: .links, isMultivalued: true, label: "edition_property.official_website"),
        .init(uri: "wdt:P1581", kind: .url, group: .links, isMultivalued: true, label: "edition_property.blog"),
        link("wdt:P4033", "edition_property.mastodon", #"^\w+@[a-z0-9.-]+[a-z0-9]+$"#, "jz@mamot.fr"),
        link("wdt:P12361", "edition_property.bluesky", #"^[\w\-.]+$"#, "astrokatie.com"),
        link("wdt:P2003", "edition_property.instagram", #"^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$"#, "tienstiens.bd"),
        link("wdt:P2013", "edition_property.facebook", #"^(\d+|[.\w]+)$"#, "billt"),
        link("wdt:P2002", "edition_property.x", #"^\w{1,15}$"#, "EFF"),
        link("wdt:P2397", "edition_property.youtube", #"^UC[\w-]{21}[AQgw]$"#, "UCEbFsO2sM_wjTn44YAgSrrg"),
        link("wdt:P11892", "edition_property.threads", #"^_{0,2}[a-z\d]+((\.|_{1,4}|\._)[a-z\d]+)*_{0,2}$"#, "laradionova"),
        link("wdt:P7085", "edition_property.tiktok", #"^[\w.]{1,24}$"#, "jannat_zubair29")
    ]

    /// Every property of the catalogue, in the order the form shows them.
    static let all: [EditionProperty] = [publisher, collection, publicationDate, language, format, numberOfPages, numberOfVolumes]
        + contributors + databases + links

    static func named(_ uri: String) -> EditionProperty? {
        all.first { $0.uri == uri }
    }

    static func properties(in group: Group) -> [EditionProperty] {
        all.filter { $0.group == group }
    }

    private static func person(_ uri: String, _ label: String) -> EditionProperty {
        .init(uri: uri, kind: .entity(.humans), group: .contributors, isMultivalued: true, label: label)
    }

    private static func database(_ uri: String, _ label: String, _ pattern: String, _ example: String) -> EditionProperty {
        .init(uri: uri, kind: .identifier(pattern: pattern, example: example), group: .databases, isMultivalued: true, label: label)
    }

    private static func link(_ uri: String, _ label: String, _ pattern: String, _ example: String) -> EditionProperty {
        .init(uri: uri, kind: .identifier(pattern: pattern, example: example), group: .links, isMultivalued: true, label: label)
    }
}
