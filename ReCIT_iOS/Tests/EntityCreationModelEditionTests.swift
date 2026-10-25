//
//  EntityCreationModelEditionTests.swift
//  ReCIT_iOSTests
//
//  Changing an edition that exists, from the book screen's « Modifier ». What is asserted is the
//  order of the calls — the picture before the claim that names it — and what a failure halfway
//  leaves: the claims that landed are not sent again, and the local edition shows them.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EntityCreationModel · changing an edition", .serialized)
struct EntityCreationModelEditionTests {

    private let hash: String = "75407f010cff3581bd373cc8ada59ad9259bf17a"
    private let newHash: String = "0123456789abcdef0123456789abcdef01234567"

    private var original: EditionClaims {
        .init(
            uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
            title: "Lucioles",
            subtitle: nil,
            coverHash: hash,
            isbn: "978-2-37049-300-2"
        )
    }

    private func sentUpdates(_ mock: MockAPIService) throws -> [EditionClaimUpdate] {
        try mock.sentPayloads.map { try JSONDecoder().decode(EditionClaimUpdate.self, from: $0) }
    }

    // MARK: - Reading

    @Test("The edition is read cookieless, under its canonical uri")
    func readsTheEditionPublicly() async throws {
        let mock: MockAPIService = .init()
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/entities/by-uris", json: """
        { "entities": { "inv:69c1353d3d6a4fb21005c0d7367e1eb4": {
            "uri": "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
            "claims": { "wdt:P1476": ["Lucioles"], "invp:P2": ["\(hash)"], "wdt:P212": ["978-2-37049-300-2"] }
        } } }
        """)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: publicMock)
        let claims: EditionClaims = try await model.editableEdition(uri: "isbn:9782370493002")

        #expect(claims == original)
        #expect(mock.recordedRequests.isEmpty)
        #expect(publicMock.recordedRequests.first?.endpoint
            == "/api/entities/by-uris?uris=isbn:9782370493002&attributes=info|claims")
    }

    @Test("An answer with no inv: edition is a failure")
    func wikidataAnswerThrows() async throws {
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/entities/by-uris", json: #"{ "entities": { "wd:Q1": { "uri": "wd:Q1" } } }"#)

        let model: EntityCreationModel = .init(apiService: MockAPIService(), publicAPIService: publicMock)

        await #expect(throws: NetworkError.self) {
            _ = try await model.editableEdition(uri: "wd:Q1")
        }
    }

    // MARK: - Saving

    @Test("The picture goes up first, then each claim, title before cover")
    func savesInOrder() async throws {
        let mock: MockAPIService = .init()
        mock.uploadedImageUrl = "/img/entities/\(newHash)"
        mock.stub("/api/entities/update-claim", json: #"{ "ok": true }"#)

        var edit: EditionEdit = .init(original: original)
        edit.title = "Lucioles II"
        edit.coverData = Data("new".utf8)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())
        let saved: EditionEdit = try await model.saveEdition(edit)

        #expect(mock.recordedRequests.map(\.endpoint) == [
            "/api/images/upload?container=entities",
            "/api/entities/update-claim",
            "/api/entities/update-claim"
        ])
        #expect(mock.recordedRequests.dropFirst().allSatisfy { $0.method == "PUT" })
        #expect(try sentUpdates(mock) == [
            .init(uri: original.uri, property: .title, oldValue: "Lucioles", newValue: "Lucioles II"),
            .init(uri: original.uri, property: .cover, oldValue: hash, newValue: newHash)
        ])
        #expect(saved.hasChanges == false)
        #expect(saved.original.coverHash == newHash)
    }

    @Test("An upload that answers no hash fails before any claim is sent")
    func uploadWithoutHashFails() async throws {
        let mock: MockAPIService = .init()
        mock.uploadedImageUrl = "/img/entities/abc123"

        var edit: EditionEdit = .init(original: original)
        edit.coverData = Data("new".utf8)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())

        await #expect(throws: EditionSaveFailure.self) {
            _ = try await model.saveEdition(edit)
        }
        #expect(mock.sentPayloads.isEmpty)
    }

    @Test("A failure halfway keeps what landed, and the retry sends only the rest")
    func retryFinishesTheChange() async throws {
        let mock: MockAPIService = .init()
        mock.uploadedImageUrl = "/img/entities/\(newHash)"
        mock.stub("/api/entities/update-claim", json: #"{ "ok": true }"#)
        mock.onSend = { index in
            if index == 1 { throw NetworkError.badStatus(code: 500, message: nil) }
        }

        var edit: EditionEdit = .init(original: original)
        edit.title = "Lucioles II"
        edit.coverData = Data("new".utf8)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())

        var halfway: EditionEdit?
        do {
            _ = try await model.saveEdition(edit)
        } catch let failure as EditionSaveFailure {
            halfway = failure.edit
        }

        let partial: EditionEdit = try #require(halfway)
        #expect(partial.original.title == "Lucioles II")
        #expect(partial.uploadedCoverHash == newHash)
        #expect(partial.claimUpdates.map(\.property) == [.cover])

        mock.onSend = nil
        let saved: EditionEdit = try await model.saveEdition(partial)

        // One upload in all: the retry hangs the picture already sent.
        #expect(mock.uploadedImageSizes.count == 1)
        #expect(try sentUpdates(mock).map(\.property) == [.title, .cover, .cover])
        #expect(saved.hasChanges == false)
    }

    // MARK: - The work

    @Test("The work is described with its authors, by name and uri")
    func describesTheWork() async throws {
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/entities/by-uris", json: """
        { "entities": {
            "inv:work": { "uri": "inv:work", "labels": { "fr": "Penss et les plis du monde" },
                          "claims": { "wdt:P50": ["wd:Q3177937"] } },
            "wd:Q3177937": { "uri": "wd:Q3177937", "labels": { "fr": "Jérémie Moreau" } }
        } }
        """)

        let model: EntityCreationModel = .init(apiService: MockAPIService(), publicAPIService: publicMock)
        let work: EditionWork = try await model.describeWork(uri: "inv:work")

        #expect(work.title == "Penss et les plis du monde")
        #expect(work.authors.map(\.uri) == ["wd:Q3177937"])
        #expect(work.authors.map(\.trimmedName) == ["Jérémie Moreau"])
        #expect(publicMock.recordedRequests.first?.endpoint.contains("relatives=wdt:P50") == true)
    }

    @Test("A new work goes up after its new author, then the edition is pointed at it")
    func createsAuthorThenWorkThenClaim() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/update-claim", json: #"{ "ok": true }"#)
        mock.stub("/api/entities", jsonSequence: [
            #"{ "entity": { "uri": "inv:author" } }"#,
            #"{ "entity": { "uri": "inv:work" } }"#
        ])

        var edit: EditionEdit = .init(original: original, originalWork: .init(uri: "inv:old", title: "Lucioles"))
        edit.startNewWork(titled: "Lucioles, l'œuvre")
        edit.addAuthor(.init(name: "Lucie Durand"))

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())
        let saved: EditionEdit = try await model.saveEdition(edit)

        #expect(mock.recordedRequests.map(\.endpoint) == [
            "/api/entities",
            "/api/entities",
            "/api/entities/update-claim"
        ])
        #expect(mock.recordedRequests.map(\.method) == ["POST", "POST", "PUT"])

        let author: EntityCreationRequest = try JSONDecoder().decode(EntityCreationRequest.self, from: mock.sentPayloads[0])
        #expect(author.labels.values.first == "Lucie Durand")
        #expect(author.claims == ["wdt:P31": ["wd:Q5"]])

        let work: EntityCreationRequest = try JSONDecoder().decode(EntityCreationRequest.self, from: mock.sentPayloads[1])
        #expect(work.labels.values.first == "Lucioles, l'œuvre")
        #expect(work.claims == ["wdt:P31": ["wd:Q47461344"], "wdt:P50": ["inv:author"]])

        let claim: EditionClaimUpdate = try JSONDecoder().decode(EditionClaimUpdate.self, from: mock.sentPayloads[2])
        #expect(claim == .init(uri: original.uri, property: .work, oldValue: nil, newValue: "inv:work"))

        #expect(saved.original.workUri == "inv:work")
        #expect(saved.hasChanges == false)
    }

    @Test("A work that fails to be created leaves its author created, and the retry reuses them")
    func failedWorkKeepsItsAuthor() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/update-claim", json: #"{ "ok": true }"#)
        mock.stub("/api/entities", jsonSequence: [#"{ "entity": { "uri": "inv:author" } }"#])
        mock.onSend = { index in
            if index == 1 { throw NetworkError.badStatus(code: 500, message: nil) }
        }

        var edit: EditionEdit = .init(original: original)
        edit.startNewWork(titled: "Lucioles")
        edit.addAuthor(.init(name: "Lucie Durand"))

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())

        var halfway: EditionEdit?
        do {
            _ = try await model.saveEdition(edit)
        } catch let failure as EditionSaveFailure {
            halfway = failure.edit
        }

        let partial: EditionEdit = try #require(halfway)
        #expect(partial.addedAuthors.map(\.uri) == ["inv:author"])
        #expect(partial.nextStep == .createWork(label: "Lucioles", language: partial.labelLanguage, authorUris: ["inv:author"]))
    }

    // MARK: - The local edition

    @Test("Only what moved is written into the local edition")
    func appliesOnlyWhatMoved() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = .init(
            uri: "isbn:9782370493002",
            title: "Lucioles",
            lang: "fr",
            authorNames: [],
            image: "https://test.local/img/entities/from-elsewhere"
        )
        context.insert(edition)

        let model: EntityCreationModel = .init(apiService: MockAPIService(), publicAPIService: MockAPIService())
        let before: EditionClaims = .init(uri: original.uri, title: "Lucioles", coverHash: nil)
        var after: EditionClaims = before
        after.title = "Lucioles II"
        after.subtitle = "Tome I"

        model.apply(after, since: before, to: edition, modelContext: context)

        #expect(edition.title == "Lucioles II")
        #expect(edition.subtitle == "Tome I")
        // No hash before or after: the picture shown came from elsewhere, and stays.
        #expect(edition.image == "https://test.local/img/entities/from-elsewhere")

        var covered: EditionClaims = after
        covered.coverHash = newHash
        model.apply(covered, since: after, to: edition, modelContext: context)

        #expect(edition.image == "https://test.local/img/entities/\(newHash)")
    }
}
