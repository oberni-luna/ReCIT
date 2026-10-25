//
//  EditionClaimsTests.swift
//  ReCIT_iOSTests
//
//  Reading an edition to change it: the canonical `inv:` uri behind an `isbn:` one, the claims
//  the form edits — the catalogue's among them —, the hash an upload answers, and the body
//  `update-claim` is sent.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EditionClaims")
struct EditionClaimsTests {

    /// `by-uris?uris=isbn:9782370493002&attributes=info|claims`, as inventaire.io answered it on
    /// 2026-10-25, trimmed to the claims that matter.
    private let answer: String = """
    {
      "entities": {
        "inv:69c1353d3d6a4fb21005c0d7367e1eb4": {
          "uri": "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
          "invId": "69c1353d3d6a4fb21005c0d7367e1eb4",
          "type": "edition",
          "claims": {
            "wdt:P1476": ["Lucioles"],
            "wdt:P1680": ["15 fictions pour des futurs écologiques"],
            "wdt:P212": ["978-2-37049-300-2"],
            "wdt:P957": ["2-37049-300-3"],
            "invp:P2": ["75407f010cff3581bd373cc8ada59ad9259bf17a"],
            "wdt:P1104": [256]
          }
        }
      },
      "redirects": { "isbn:9782370493002": "inv:69c1353d3d6a4fb21005c0d7367e1eb4" }
    }
    """

    private func decode(_ json: String) throws -> [EditionClaims] {
        let dto: EditableEditionsDTO = try JSONDecoder().decode(EditableEditionsDTO.self, from: Data(json.utf8))
        return dto.entities.values.compactMap { EditionClaims(dto: $0) }
    }

    @Test("An ISBN edition is read under the inv: uri it redirects to")
    func readsTheCanonicalEdition() throws {
        let claims: EditionClaims? = try decode(answer).first

        var pages: EditionProperties = .init()
        pages.setLiteral(.integer(256), for: .numberOfPages)

        #expect(claims == .init(
            uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
            title: "Lucioles",
            subtitle: "15 fictions pour des futurs écologiques",
            coverHash: "75407f010cff3581bd373cc8ada59ad9259bf17a",
            isbn: "978-2-37049-300-2",
            isbn10: "2-37049-300-3",
            properties: pages
        ))
        #expect(claims?.normalizedISBN == "9782370493002")
    }

    @Test("The work and the label language are read with the edition")
    func readsWorkAndLanguage() throws {
        let claims: EditionClaims? = try decode("""
        { "entities": { "inv:1": { "uri": "inv:1", "originalLang": "fr",
            "claims": { "wdt:P1476": ["Penss et les plis du monde"], "wdt:P629": ["inv:work"] } } } }
        """).first

        #expect(claims?.workUri == "inv:work")
        #expect(claims?.labelLanguage == "fr")
    }

    @Test("Without an ISBN-13 the ISBN-10 is shown; without a title, an empty one")
    func sparseEdition() throws {
        let claims: EditionClaims? = try decode("""
        { "entities": { "inv:1": { "uri": "inv:1", "claims": { "wdt:P957": ["2-37049-300-3"] } } } }
        """).first

        #expect(claims?.isbn == "2-37049-300-3")
        // Shown once, as the ISBN, not a second time under it.
        #expect(claims?.isbn10 == nil)
        #expect(claims?.title == "")
        #expect(claims?.subtitle == nil)
        #expect(claims?.coverHash == nil)
    }

    @Test("A Wikidata edition is nothing the form can send")
    func wikidataEditionIsNotEditable() throws {
        #expect(try decode("""
        { "entities": { "wd:Q1": { "uri": "wd:Q1", "claims": { "wdt:P1476": ["Le Comte"] } } } }
        """).isEmpty)

        #expect(EditionClaims.canEdit(uri: "wd:Q1") == false)
        #expect(EditionClaims.canEdit(uri: "isbn:9782370493002"))
        #expect(EditionClaims.canEdit(uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4"))
    }

    @Test("An upload's path ends with the hash invp:P2 takes")
    func hashFromUploadPath() {
        let hash: String = "75407f010cff3581bd373cc8ada59ad9259bf17a"

        #expect(EntityImageHash.from("/img/entities/\(hash)") == hash)
        #expect(EntityImageHash.from("https://inventaire.io/img/entities/\(hash)") == hash)
        #expect(EntityImageHash.from("/img/entities/abc123") == nil)
        #expect(EntityImageHash.from("/img/entities/\(hash.uppercased())") == nil)
        #expect(EntityImageHash.from(nil) == nil)
        #expect(EntityImageHash.path(of: hash) == "/img/entities/\(hash)")
    }

    @Test("A missing side of an update is left out of the body, not sent as null")
    func updateBodyOmitsMissingSides() throws {
        let removal: EditionClaimUpdate = .init(uri: "inv:1", property: .subtitle, oldValue: "Tome I", newValue: nil)
        let object: [String: String] = try JSONDecoder().decode(
            [String: String].self,
            from: JSONEncoder().encode(removal)
        )

        #expect(object == ["uri": "inv:1", "property": "wdt:P1680", "old-value": "Tome I"])
    }
}
