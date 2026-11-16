//
//  ListScanViewModelTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

/// The list scanner's lookup against a mocked inventaire.io: a book whose work did not come back
/// the first time is not a dead end, « Réessayer » looks it up again.
@MainActor
@Suite
struct ListScanViewModelTests {
    private let code: String = "9791032932025"
    private let workURI: String = "wd:Q190192"

    private var editionJSON: String {
        #"""
        {"entities":{"isbn:\#(code)":{"uri":"isbn:\#(code)","type":"edition","originalLang":"fr","labels":{"fromclaims":"Aqua"},"claims":{"wdt:P1476":["Aqua"],"wdt:P629":["\#(workURI)"]}}}}
        """#
    }

    private var workJSON: String {
        #"""
        {"entities":{"\#(workURI)":{"uri":"\#(workURI)","type":"work","originalLang":"fr","labels":{"fr":"Aqua"},"claims":{}}}}
        """#
    }

    @Test
    func `a book whose work failed to come back is offered once retried`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        // The work's match first: stubs answer by substring, in order, and the edition's would
        // match the work's request too.
        mock.stub("uris=\(workURI)&", error: NetworkError.badResponse)
        mock.stub("uris=isbn:\(code)&", json: editionJSON)
        let entityModel: EntityModel = .init(apiService: mock)
        let sut: ListScanViewModel = .init()

        sut.codeSeen(code, entityModel: entityModel, modelContext: context)
        await sut.lookupTask?.value
        #expect(sut.state == .notFound(code: code))
        #expect(sut.works.isEmpty)

        mock.restub("uris=\(workURI)&", json: workJSON)
        sut.retry(entityModel: entityModel, modelContext: context)
        #expect(sut.state == .lookingUp(code: code))
        await sut.lookupTask?.value

        let book: ScannedBook = try #require(sut.state.book)
        #expect(sut.state == .resolved(book: book))
        #expect(book.code == code)
        #expect(sut.works.map(\.uri) == [workURI])
    }

    @Test
    func `a retry that fails again leaves the row ready to retry`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("uris=\(workURI)&", error: NetworkError.badResponse)
        mock.stub("uris=isbn:\(code)&", json: editionJSON)
        let entityModel: EntityModel = .init(apiService: mock)
        let sut: ListScanViewModel = .init()

        sut.codeSeen(code, entityModel: entityModel, modelContext: context)
        await sut.lookupTask?.value
        sut.retry(entityModel: entityModel, modelContext: context)
        await sut.lookupTask?.value

        #expect(sut.state == .notFound(code: code))
        #expect(mock.recordedRequests.filter { $0.endpoint.contains("uris=isbn:\(code)&") }.count == 2)
    }

    @Test
    func `the same barcode held in frame does not retry by itself`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("uris=\(workURI)&", error: NetworkError.badResponse)
        mock.stub("uris=isbn:\(code)&", json: editionJSON)
        let entityModel: EntityModel = .init(apiService: mock)
        let sut: ListScanViewModel = .init()

        sut.codeSeen(code, entityModel: entityModel, modelContext: context)
        await sut.lookupTask?.value
        sut.codeSeen(code, entityModel: entityModel, modelContext: context)

        #expect(sut.state == .notFound(code: code))
        #expect(mock.recordedRequests.filter { $0.endpoint.contains("uris=isbn:\(code)&") }.count == 1)
    }
}
