//
//  WikidataEntityEditingTests.swift
//  ReCIT_iOSTests
//
//  A Wikidata work or person opens in « Modifier l'œuvre » / « Modifier l'auteur·ice » like one
//  of inventaire.io's, and names only Wikidata entities: inventaire.io refuses the link from a
//  `wd:` entity to an `inv:` one.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Editing Wikidata works and people")
struct WikidataEntityEditingTests {

    private func result(_ uri: String) -> SearchResult {
        .init(id: uri, uri: uri, title: uri, score: 1, type: .humans)
    }

    @Test("inventaire.io's entities and Wikidata's open for editing, nothing else")
    func canEdit() {
        #expect(EntityEdit.canEdit(uri: "inv:0123456789abcdef"))
        #expect(EntityEdit.canEdit(uri: "wd:Q42"))
        #expect(EntityEdit.canEdit(uri: "isbn:9782070368228") == false)
        #expect(EntityEdit.canEdit(uri: "") == false)
    }

    @Test("Only a Wikidata entity is restricted to naming Wikidata entities")
    func linksWikidataOnly() {
        #expect(EntityEdit.linksWikidataOnly(uri: "wd:Q42"))
        #expect(EntityEdit.linksWikidataOnly(uri: "inv:0123456789abcdef") == false)
    }

    @Test("The picker of a Wikidata entity keeps Wikidata's results alone")
    func pickerFilter() {
        let results: [SearchResult] = [result("wd:Q42"), result("inv:abc"), result("wd:Q1")]

        #expect(EntityPickerView.candidates(results, wikidataOnly: true).map(\.uri) == ["wd:Q42", "wd:Q1"])
        #expect(EntityPickerView.candidates(results, wikidataOnly: false).map(\.uri) == ["wd:Q42", "inv:abc", "wd:Q1"])
    }

    @Test("A Wikidata work is editable and saves through update-label on its wd: uri")
    func wikidataWorkLabelUpdate() {
        var edit: EntityEdit = .init(
            uri: "wd:Q42",
            labels: ["fr": "Bug, Livre 4"],
            properties: .init(claims: [:], labels: [:], catalogue: .work),
            originalLanguage: "fr"
        )
        #expect(edit.isEditable)

        edit.labels[0].value = "Bug, livre 4"

        #expect(edit.isSaveable)
        #expect(edit.labelUpdates.map(\.uri) == ["wd:Q42"])
    }
}
