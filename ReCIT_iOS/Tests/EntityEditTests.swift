//
//  EntityEditTests.swift
//  ReCIT_iOSTests
//
//  A work and a person as « Modifier l'œuvre » and « Modifier l'auteur·ice » change them: their
//  catalogues, what is read from their claims, and what a change comes to — the people to create
//  first, the claims, then the labels — and what a landed step takes out of the next try.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EntityEdit")
struct EntityEditTests {

    private let workUri: String = "inv:work"
    private let humanUri: String = "inv:human"

    private func work(
        labels: [String: String] = ["fr": "Le Ministère des Rêves"],
        claims: [String: [ClaimValue]] = [:],
        names: [String: String] = [:]
    ) -> EntityEdit {
        .init(
            uri: workUri,
            labels: labels,
            properties: .init(claims: claims, labels: names, catalogue: .work)
        )
    }

    // MARK: - The catalogues

    @Test("A work's and a person's catalogues name each property once")
    func cataloguesHaveNoTwin() {
        for catalogue in [EditionProperty.Catalogue.work, .human] {
            let uris: [String] = catalogue.properties.map(\.uri)
            #expect(Set(uris).count == uris.count)
        }
        #expect(EditionProperty.workDatabases.count == 20)
        #expect(EditionProperty.humanDatabases.count == 29)
        #expect(EditionProperty.humanLinks.count == 11)
        #expect(EditionProperty.workType.choices.count == 6)
        #expect(EditionProperty.workForm.choices.count == 31)
        #expect(EditionProperty.Catalogue.work.property(named: "wdt:P31") == .workType)
        #expect(EditionProperty.Catalogue.human.property(named: "wdt:P31") == nil)
    }

    @Test("A uri is read in its own catalogue: a work's Open Library id is not an edition's")
    func uriPerCatalogue() {
        let workOpenLibrary: EditionProperty = EditionProperty.Catalogue.work.property(named: "wdt:P648")!
        #expect(workOpenLibrary.literal(from: "OL36858W") == "OL36858W")
        #expect(workOpenLibrary.literal(from: "OL61173905M") == nil)

        let humanOpenLibrary: EditionProperty = EditionProperty.Catalogue.human.property(named: "wdt:P648")!
        #expect(humanOpenLibrary.literal(from: "OL396182A") == "OL396182A")

        #expect(EditionProperty.Catalogue.work.property(named: "wdt:P407")?.label == "entity_property.original_language")
        #expect(EditionProperty.Catalogue.edition.property(named: "wdt:P407")?.label == "edition_property.language")
    }

    @Test("Every example the server gives passes its own pattern")
    func examplesPass() {
        for property in EditionProperty.workDatabases + EditionProperty.humanDatabases + EditionProperty.humanLinks {
            guard case .identifier(_, let example) = property.kind else { continue }
            #expect(property.literal(from: example) != nil, "\(property.uri) refuses \(example)")
        }
    }

    @Test("The new kinds of value: a rank sent as a string, a pseudonym, a choice, an ISNI with spaces")
    func newKinds() {
        #expect(EditionProperty.seriesOrdinal.literal(from: " 3 ") == .string("3"))
        #expect(EditionProperty.seriesOrdinal.literal(from: "0") == nil)
        #expect(EditionProperty.seriesOrdinal.literal(from: "trois") == nil)

        #expect(EditionProperty.pseudonym.literal(from: " Vernon Sullivan ") == "Vernon Sullivan")
        #expect(EditionProperty.pseudonym.literal(from: String(repeating: "a", count: 401)) == nil)

        #expect(EditionProperty.workForm.literal(from: "wd:Q8261") == "wd:Q8261")
        #expect(EditionProperty.workForm.literal(from: "wd:Q5") == nil)

        let isni: EditionProperty = EditionProperty.Catalogue.human.property(named: "wdt:P213")!
        #expect(isni.literal(from: "0000 0001 2297 4701") == "0000000122974701")

        #expect(EditionProperty.mainSubject.isEntity)
        #expect(EditionProperty.mainSubject.allowsCreation == false)
        #expect(EditionProperty.author.allowsCreation)
        #expect(EditionProperty.humanDifferentFrom.allowsCreation == false)
    }

    // MARK: - Reading

    @Test("A work's claims are read into its catalogue: entities named, literals kept")
    func readsAWork() {
        let edit: EntityEdit = work(
            claims: [
                "wdt:P31": [.string("wd:Q7725634")],
                "wdt:P7937": [.string("wd:Q8261")],
                "wdt:P50": [.string("inv:milanov")],
                "wdt:P1545": [.string("2")],
                "wdt:P136": [.string("wd:Q24925")],
                "wdt:P212": [.string("978-2-494289-85-7")]
            ],
            names: ["inv:milanov": "Momtchil Milanov"]
        )

        #expect(edit.properties.literal(of: .workType) == "wd:Q7725634")
        #expect(edit.properties.literal(of: .workForm) == "wd:Q8261")
        #expect(edit.properties.literal(of: .seriesOrdinal) == "2")
        #expect(edit.properties.entities(of: .author).map(\.label) == ["Momtchil Milanov"])
        // Unnamed, an entity keeps its uri as its name.
        #expect(edit.properties.entities(of: .genre).map(\.label) == ["wd:Q24925"])
        // An ISBN is no property of a work.
        #expect(edit.properties.values["wdt:P212"] == nil)
        #expect(edit.hasChanges == false)
        #expect(edit.isSaveable == false)
        #expect(edit.editionWork.authors.map(\.uri) == ["inv:milanov"])
    }

    @Test("The label shown comes first, the others after it")
    func labelsInOrder() {
        let edit: EntityEdit = work(labels: ["en": "The Ministry of Dreams", "bg": "Министерството", "fr": "Le Ministère des Rêves"])
        #expect(edit.labels.map(\.language) == ["fr", "bg", "en"])
        #expect(edit.displayName == "Le Ministère des Rêves")
        #expect(edit.addableLanguages.contains("fr") == false)
        #expect(edit.labelLanguage == "fr")
    }

    // MARK: - What there is to send

    @Test("A person to create goes first, then the claims, then the labels")
    func orderOfTheSteps() {
        var edit: EntityEdit = work()
        edit.properties.setLiteral("wd:Q8261", for: .workForm)
        edit.properties.add(.init(label: "Lucie Durand"), to: .author)
        edit.labels[0].value = "Le Ministère des rêves"
        edit.addLabel(language: "en")
        edit.labels[1].value = "The Ministry of Dreams"

        #expect(edit.isSaveable)
        guard case .createEntity(let id, "Lucie Durand", "fr", .human) = edit.nextStep else {
            Issue.record("expected the author to be created first, got \(String(describing: edit.nextStep))")
            return
        }

        edit.entityCreated(id: id, uri: "inv:lucie")
        #expect(edit.claimUpdates == [
            .init(uri: workUri, property: "wdt:P7937", oldValue: nil, newValue: "wd:Q8261"),
            .init(uri: workUri, property: "wdt:P50", oldValue: nil, newValue: "inv:lucie")
        ])

        for update in edit.claimUpdates {
            #expect(edit.nextStep == .claim(update))
            edit.landed(update)
        }

        #expect(edit.labelUpdates == [
            .init(uri: workUri, lang: "fr", value: "Le Ministère des rêves"),
            .init(uri: workUri, lang: "en", value: "The Ministry of Dreams")
        ])
        edit.landed(edit.labelUpdates[0])
        #expect(edit.nextStep == .label(.init(uri: workUri, lang: "en", value: "The Ministry of Dreams")))
        edit.landed(edit.labelUpdates[0])

        #expect(edit.nextStep == nil)
        #expect(edit.hasChanges == false)
    }

    @Test("A label it had cannot be emptied; an empty new one is not sent")
    func emptyLabels() {
        var edit: EntityEdit = work()
        edit.addLabel(language: "en")
        #expect(edit.hasChanges == false)

        edit.labels[0].value = "  "
        #expect(edit.labelUpdates.isEmpty)
        edit.properties.setLiteral("wd:Q1004", for: .workType)
        #expect(edit.hasChanges)
        #expect(edit.isSaveable == false)
    }

    @Test("A Wikidata entity is never saved")
    func wikidataIsNotSaved() {
        var edit: EntityEdit = .init(
            uri: "wd:Q42",
            labels: ["fr": "Douglas Adams"],
            properties: .init(catalogue: .human)
        )
        edit.properties.addLiteral("Bop Ad", to: .pseudonym)
        #expect(edit.hasChanges)
        #expect(edit.isSaveable == false)
    }

    @Test("A person renamed is shown under the new name without anything to send")
    func renameAPerson() {
        var edit: EntityEdit = work(
            claims: ["wdt:P50": [.string("inv:milanov")]],
            names: ["inv:milanov": "M. Milanov"]
        )
        edit.rename(uri: "inv:milanov", label: "Momtchil Milanov")
        #expect(edit.properties.entities(of: .author).map(\.label) == ["Momtchil Milanov"])
        #expect(edit.hasChanges == false)
    }

    @Test("A work saved replaces its row in the edition, which has nothing more to send")
    func workSavedInTheEdition() {
        var edition: EditionEdit = .init(
            original: .init(uri: "inv:edition", title: "Le Ministère des Rêves", workUris: [workUri]),
            originalWorks: [.init(uri: workUri, title: "Le Ministère des Reves", imageUrl: "/img/cover")]
        )
        let rowId: UUID = edition.works[0].id
        var saved: EntityEdit = work(claims: ["wdt:P50": [.string("inv:milanov")]], names: ["inv:milanov": "Momtchil Milanov"])
        saved.labels[0].value = "Le Ministère des Rêves"

        edition.workSaved(saved.editionWork)

        #expect(edition.works[0].id == rowId)
        #expect(edition.works[0].title == "Le Ministère des Rêves")
        #expect(edition.works[0].authors.map(\.trimmedName) == ["Momtchil Milanov"])
        #expect(edition.works[0].imageUrl == "/img/cover")
        #expect(edition.hasChanges == false)

        edition.rename(uri: "inv:milanov", label: "M. Milanov")
        #expect(edition.works[0].authors.map(\.trimmedName) == ["M. Milanov"])
        #expect(edition.hasChanges == false)
    }
}
