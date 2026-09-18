//
//  EntityCreationModelTests.swift
//  ReCIT_iOSTests
//
//  The one write this app makes into somebody else's database. What is asserted here is what
//  the caller is owed: the canonical uri of the edition, or a failure it can show — never a
//  guess, because an inventory item created from a guessed uri is a book that does not exist.
//
//  See PRD 0015.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EntityCreationModel", .serialized)
struct EntityCreationModelTests {

    private let draft: NewBookDraft = .init(
        isbn: "978-2-38019-274-1",
        title: "La Main gauche de la nuit",
        authorName: "Ursula K. Le Guin"
    )

    @Test("Creating an edition answers with the canonical uri the server gave it")
    func createReturnsTheCanonicalUri() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/resolve", json: """
        {
          "entries": [
            {
              "edition": { "uri": "inv:af24decad82f4699a4092ca6dfc6f2c9", "created": true },
              "works": [ { "uri": "inv:w1", "created": true } ],
              "authors": [ { "uri": "wd:Q182589", "resolved": true } ]
            }
          ]
        }
        """)

        let model: EntityCreationModel = .init(apiService: mock)
        let uri: String = try await model.createEdition(draft: draft)

        #expect(uri == "inv:af24decad82f4699a4092ca6dfc6f2c9")
        #expect(mock.recordedRequests.first?.endpoint == "/api/entities/resolve")
        #expect(mock.recordedRequests.first?.method == "POST")
    }

    /// A reader who publishes a book somebody else added a minute ago gets that one back. The
    /// server resolving instead of creating is the right answer, not an error.
    @Test("An edition the server resolved instead of creating is answered all the same")
    func resolvedEditionIsAccepted() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/resolve", json: """
        { "entries": [ { "edition": { "uri": "inv:already", "resolved": true } } ] }
        """)

        let model: EntityCreationModel = .init(apiService: mock)

        #expect(try await model.createEdition(draft: draft) == "inv:already")
    }

    @Test("An answer with no edition uri fails rather than guessing one")
    func missingUriThrows() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/resolve", json: #"{ "entries": [ { "edition": { "resolved": false } } ] }"#)

        let model: EntityCreationModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            try await model.createEdition(draft: self.draft)
        }
    }

    @Test("A server error reaches the caller")
    func serverErrorPropagates() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/resolve", error: NetworkError.badStatus(code: 401, message: nil))

        let model: EntityCreationModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            try await model.createEdition(draft: self.draft)
        }
    }
}
