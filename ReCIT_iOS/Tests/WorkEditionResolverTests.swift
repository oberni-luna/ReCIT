//
//  WorkEditionResolverTests.swift
//  ReCIT_iOSTests
//
//  The two calls that turn a work into one edition, and the three ways they can come back short:
//  no edition at all, more editions than one batch holds, and a `by-uris` that answers about
//  fewer entities than were asked about.
//
//  The case that earns its place is `orderFollowsTheRequestedUris`. The `by-uris` envelope is a
//  dictionary; ranking over its values would make the tie-break depend on hash order, and the
//  same search would open two different books on two runs. The test pins the order to the one
//  `reverse-claims` gave.
//
//  See PRD 0014.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("WorkEditionResolver")
struct WorkEditionResolverTests {

    // MARK: - Fixtures

    private func editionJSON(
        uri: String,
        lang: String?,
        title: String? = "Dune",
        cover: Bool = true
    ) -> String {
        let langField: String = lang.map { #""originalLang":"\#($0)","# } ?? ""
        let imageField: String = cover
            ? #""image":{"url":"/img/entities/abc","file":null,"credit":null},"#
            : ""
        let claims: String = title.map { #""wdt:P1476":["\#($0)"]"# } ?? ""
        return """
        "\(uri)":{"uri":"\(uri)",\(langField)\(imageField)"labels":{"fromclaims":"Dune"},"claims":{\(claims)}}
        """
    }

    private func envelope(_ editions: [String]) -> String {
        #"{"entities":{\#(editions.joined(separator: ","))}}"#
    }

    private func resolver(_ api: MockAPIService) -> WorkEditionResolver {
        .init(apiService: api)
    }

    // MARK: - The happy path

    @Test("It reads reverse-claims, then by-uris, and answers one uri")
    func resolvesTheFrenchEdition() async throws {
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":["inv:en","inv:fr"]}"#)
        api.stub("by-uris", json: envelope([
            editionJSON(uri: "inv:en", lang: "en"),
            editionJSON(uri: "inv:fr", lang: "fr")
        ]))

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:Q190192",
            originalLang: "en"
        )

        #expect(uri == "inv:fr")
        #expect(api.recordedRequests.count == 2)
        #expect(api.recordedRequests[0].endpoint.contains("wdt:P629"))
        #expect(api.recordedRequests[1].endpoint.contains("attributes=info|labels|claims|image"))
    }

    @Test("A held edition wins its tier, and the held set enters by parameter")
    func heldEditionWinsItsTier() async throws {
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":["inv:fr-a","inv:fr-b"]}"#)
        api.stub("by-uris", json: envelope([
            editionJSON(uri: "inv:fr-a", lang: "fr"),
            editionJSON(uri: "inv:fr-b", lang: "fr")
        ]))

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:Q190192",
            originalLang: "en",
            heldEditionUris: ["inv:fr-b"]
        )

        #expect(uri == "inv:fr-b")
    }

    // MARK: - Coming back short

    @Test("A work with no edition answers nil, and never calls by-uris")
    func emptyReverseClaimsAnswersNil() async throws {
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":[]}"#)

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:ghost",
            originalLang: nil
        )

        #expect(uri == nil)
        #expect(api.recordedRequests.count == 1)
    }

    @Test("More editions than one batch holds are fetched in several batches")
    func longListIsBatched() async throws {
        let uris: [String] = (0..<120).map { "inv:\($0)" }
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":[\#(uris.map { #""\#($0)""# }.joined(separator: ","))]}"#)
        // Every batch answers with the same one French edition; what is under test is the number
        // of calls, not what they carry.
        api.stub("by-uris", json: envelope([editionJSON(uri: "inv:7", lang: "fr")]))

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:Q190192",
            originalLang: "en"
        )

        #expect(uri == "inv:7")
        // 1 reverse-claims + ceil(120 / 50) = 3 by-uris
        #expect(api.recordedRequests.count == 4)
    }

    @Test("A by-uris that answers about fewer entities than were asked about still ranks")
    func partialByUrisStillRanks() async throws {
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":["inv:missing","inv:fr"]}"#)
        api.stub("by-uris", json: envelope([editionJSON(uri: "inv:fr", lang: "fr")]))

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:Q190192",
            originalLang: "en"
        )

        #expect(uri == "inv:fr")
    }

    @Test("An entity returned under a key nobody asked for is still a candidate")
    func unrequestedCanonicalUriIsKept() async throws {
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":["isbn:9780000000000"]}"#)
        api.stub("by-uris", json: envelope([editionJSON(uri: "inv:canonical", lang: "fr")]))

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:Q190192",
            originalLang: "en"
        )

        #expect(uri == "inv:canonical")
    }

    @Test("Order follows the requested uris, not the envelope's dictionary")
    func orderFollowsTheRequestedUris() async throws {
        // Two equally good French editions: the tie-break is "whichever came first", so the
        // answer must track the reverse-claims order rather than the JSON's.
        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":["inv:second","inv:first"]}"#)
        api.stub("by-uris", json: envelope([
            editionJSON(uri: "inv:first", lang: "fr"),
            editionJSON(uri: "inv:second", lang: "fr")
        ]))

        let uri: String? = try await resolver(api).bestEditionUri(
            forWorkUri: "wd:Q190192",
            originalLang: "en"
        )

        #expect(uri == "inv:second")
    }

    // MARK: - Failure

    @Test("A network failure is thrown, not swallowed into nil")
    func networkFailurePropagates() async throws {
        let api: MockAPIService = .init()
        api.stub("reverse-claims", error: NetworkError.badStatus(code: 500, message: "boom"))

        await #expect(throws: (any Error).self) {
            try await resolver(api).bestEditionUri(forWorkUri: "wd:Q190192", originalLang: "en")
        }
    }
}
