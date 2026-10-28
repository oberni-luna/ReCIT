//
//  EntityCreationModelEntityTests.swift
//  ReCIT_iOSTests
//
//  Reading and saving a work or a person on their own, from « Modifier l'œuvre » and « Modifier
//  l'auteur·ice ». What is asserted is what is read, the order of the calls, and what a failure
//  halfway leaves: what landed is not sent again.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EntityCreationModel · changing a work or a person", .serialized)
struct EntityCreationModelEntityTests {

    private let workUri: String = "inv:9f0c7d1e2a3b4c5d6e7f8a9b0c1d2e3f"

    @Test("A work is read cookieless, then the entities it names are labelled")
    func readsAWork() async throws {
        let mock: MockAPIService = .init()
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/entities/by-uris?uris=\(workUri)", json: """
        { "entities": { "\(workUri)": {
            "uri": "\(workUri)", "type": "work", "originalLang": "fr",
            "labels": { "fr": "Le Ministère des Rêves" },
            "claims": { "wdt:P31": ["wd:Q7725634"], "wdt:P50": ["inv:milanov"], "wdt:P1545": ["2"] }
        } } }
        """)
        publicMock.stub("/api/entities/by-uris?uris=inv:milanov", json: """
        { "entities": { "inv:milanov": { "uri": "inv:milanov", "labels": { "fr": "Momtchil Milanov" } } } }
        """)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: publicMock)
        let edit: EntityEdit = try await model.editableEntity(uri: workUri)

        #expect(edit.catalogue == .work)
        #expect(edit.displayName == "Le Ministère des Rêves")
        #expect(edit.properties.entities(of: .author).map(\.label) == ["Momtchil Milanov"])
        #expect(edit.properties.literal(of: .seriesOrdinal) == "2")
        #expect(mock.recordedRequests.isEmpty)
        #expect(publicMock.recordedRequests.count == 2)
    }

    @Test("An edition is not opened as a work")
    func refusesAnEdition() async {
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/entities/by-uris", json: """
        { "entities": { "inv:e": { "uri": "inv:e", "type": "edition", "claims": {} } } }
        """)
        let model: EntityCreationModel = .init(apiService: MockAPIService(), publicAPIService: publicMock)
        await #expect(throws: NetworkError.self) {
            _ = try await model.editableEntity(uri: "inv:e")
        }
    }

    @Test("A person is saved: the person to create, the claims, then the name")
    func savesAPerson() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/update-claim", json: #"{ "ok": true }"#)
        mock.stub("/api/entities/update-label", json: #"{ "ok": true }"#)
        mock.stub("/api/entities", json: #"{ "entity": { "uri": "inv:queneau" } }"#)

        var edit: EntityEdit = .init(uri: "inv:vian", labels: ["fr": "Boris Vian"], properties: .init(catalogue: .human))
        edit.properties.addLiteral("Vernon Sullivan", to: .pseudonym)
        edit.properties.add(.init(label: "Raymond Queneau"), to: .influencedBy)
        edit.labels[0].value = "Boris Vian (1920-1959)"

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())
        let saved: EntityEdit = try await model.saveEntity(edit)

        #expect(mock.recordedRequests.map(\.endpoint) == [
            "/api/entities",
            "/api/entities/update-claim",
            "/api/entities/update-claim",
            "/api/entities/update-label"
        ])
        #expect(saved.hasChanges == false)
        #expect(saved.properties.entities(of: .influencedBy).first?.uri == "inv:queneau")
    }

    @Test("A failure halfway keeps what landed: the retry sends only the rest")
    func failureHalfway() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/update-claim", json: #"{ "ok": true }"#)
        mock.onSend = { index in
            if index == 1 { throw NetworkError.badResponse }
        }

        var edit: EntityEdit = .init(uri: workUri, labels: ["fr": "Lucioles"], properties: .init(catalogue: .work))
        edit.properties.setLiteral("wd:Q1004", for: .workType)
        edit.properties.setLiteral("wd:Q725377", for: .workForm)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())
        var partial: EntityEdit?
        do {
            _ = try await model.saveEntity(edit)
        } catch let failure as EntitySaveFailure {
            partial = failure.edit
        }

        let remaining: EntityEdit = try #require(partial)
        #expect(remaining.claimUpdates == [.init(uri: workUri, property: "wdt:P7937", oldValue: nil, newValue: "wd:Q725377")])

        mock.onSend = nil
        let saved: EntityEdit = try await model.saveEntity(remaining)
        #expect(saved.hasChanges == false)
        #expect(mock.recordedRequests.count == 3)
    }
}
