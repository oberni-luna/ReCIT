//
//  GenreEnrichmentModelTests.swift
//  ReCIT_iOSTests
//
//  The book screen's way in to a work's genres: two batched `by-uris` round trips, then a write.
//  The write is what issue 0067 crashed on, so the case that matters most is the work that is
//  gone by the time the answers are in.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("GenreEnrichmentModel", .serialized)
struct GenreEnrichmentModelTests {

    private func workEnvelope(_ uri: String, genres: [String]) -> String {
        let claims: String = genres.isEmpty ? "{}" : #"{"wdt:P136":[\#(genres.map { #""\#($0)""# }.joined(separator: ","))]}"#
        return #"{"entities":{"\#(uri)":{"uri":"\#(uri)","lastrevid":1,"type":"work","labels":{"fr":"Livre"},"claims":\#(claims)}}}"#
    }

    private let novelLabel: String = #"{"entities":{"wd:G1":{"uri":"wd:G1","labels":{"fr":"roman"}}}}"#

    private func makeModel(_ mock: MockAPIService) -> GenreEnrichmentModel {
        .init(apiService: mock, entityModel: .init(apiService: mock))
    }

    private func insertWork(_ uri: String, in context: ModelContext) throws -> Work {
        let work: Work = .init(uri: uri, lastrevid: 1, title: "Livre")
        context.insert(work)
        try context.save()
        return work
    }

    @Test("A work's genre uris are resolved to labels and written onto it")
    func enrichesOneWork() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("uris=wd:W1&", json: workEnvelope("wd:W1", genres: ["wd:G1"]))
        mock.stub("uris=wd:G1&", json: novelLabel)
        let work: Work = try insertWork("wd:W1", in: context)

        await makeModel(mock).enrichWorkIfNeeded(work, modelContext: context)

        #expect(work.genres == ["roman"])
        #expect(work.genresEnrichedAt != nil)
    }

    @Test("A work with no genre is stamped as asked, and not asked again")
    func emptyAnswerIsRemembered() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("uris=wd:W1&", json: workEnvelope("wd:W1", genres: []))
        let work: Work = try insertWork("wd:W1", in: context)
        let model: GenreEnrichmentModel = makeModel(mock)

        await model.enrichWorkIfNeeded(work, modelContext: context)
        let requestsAfterFirstVisit: Int = mock.recordedRequests.count
        await model.enrichWorkIfNeeded(work, modelContext: context)

        #expect(work.genres.isEmpty)
        #expect(work.genresEnrichedAt != nil)
        #expect(mock.recordedRequests.count == requestsAfterFirstVisit)
    }

    @Test("A work deleted while its genres are being fetched is skipped, not written to")
    func workGoneDuringTheRoundTrips() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("uris=wd:W1&", json: workEnvelope("wd:W1", genres: ["wd:G1"]))
        mock.stub("uris=wd:G1&", json: novelLabel)
        let work: Work = try insertWork("wd:W1", in: context)

        // Between the two round trips, as the e2e deletion step did.
        mock.onFetch = { endpoint in
            guard endpoint.contains("uris=wd:G1&") else { return }
            context.delete(work)
            try? context.save()
        }

        await makeModel(mock).enrichWorkIfNeeded(work, modelContext: context)

        #expect(work.isStillInTheStore == false)
        #expect(try context.fetch(FetchDescriptor<Work>()).isEmpty)
    }
}
