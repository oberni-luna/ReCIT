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

    // MARK: - What the ISBN says about the language

    @Test("The ISBN's registration group answers the language question")
    func languageComesFromTheIsbn() async throws {
        let mock: MockAPIService = .init()
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/data/isbn", json: """
        { "groupLang": "fr", "groupLangUri": "wd:Q150", "isValid": true }
        """)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: publicMock)
        let language: EditionLanguage? = await model.editionLanguage(isbn: "978-2-38019-274-1")

        #expect(language == .init(uri: "wd:Q150", code: "fr"))
        // Public endpoint, public service: the session has no business here.
        #expect(mock.recordedRequests.isEmpty)
        #expect(publicMock.recordedRequests.first?.endpoint == "/api/data/isbn?isbn=9782380192741")
    }

    @Test("A group with no language answers nothing rather than guessing")
    func groupWithoutLanguageAnswersNothing() async throws {
        let mock: MockAPIService = .init()
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/data/isbn", json: #"{ "groupLang": null, "groupLangUri": null, "isValid": true }"#)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: publicMock)

        #expect(await model.editionLanguage(isbn: "9782380192741") == nil)
    }

    @Test("A failed lookup answers nothing, and does not fail the publication")
    func failedLanguageLookupIsSwallowed() async throws {
        let mock: MockAPIService = .init()
        let publicMock: MockAPIService = .init()
        publicMock.stub("/api/data/isbn", error: NetworkError.badStatus(code: 500, message: nil))

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: publicMock)

        #expect(await model.editionLanguage(isbn: "9782380192741") == nil)
    }

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

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())
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

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())

        #expect(try await model.createEdition(draft: draft) == "inv:already")
    }

    @Test("An answer with no edition uri fails rather than guessing one")
    func missingUriThrows() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/resolve", json: #"{ "entries": [ { "edition": { "resolved": false } } ] }"#)

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())

        await #expect(throws: NetworkError.self) {
            try await model.createEdition(draft: self.draft)
        }
    }

    @Test("A server error reaches the caller")
    func serverErrorPropagates() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/resolve", error: NetworkError.badStatus(code: 401, message: nil))

        let model: EntityCreationModel = .init(apiService: mock, publicAPIService: MockAPIService())

        await #expect(throws: NetworkError.self) {
            try await model.createEdition(draft: self.draft)
        }
    }
}
