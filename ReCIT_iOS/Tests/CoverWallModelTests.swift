//
//  CoverWallModelTests.swift
//  ReCIT_iOSTests
//
//  The one call the welcome screen makes before anyone is signed in, against a **real captured
//  answer** from `GET /api/items/recent-public` (2026-09-05, trimmed to three items and kept
//  otherwise verbatim — including the fields the app does not read, which is the point: the
//  wall must not care that an item carries a `details` or a `entity:isbn13`).
//
//  The manners matter as much as the decoding: this model must never empty the screen. A
//  transport failure, a 500, a payload it cannot read — all three leave whatever wall was
//  already up.
//
//  See PRD 0011.
//

import Testing
import Foundation
@testable import ReCIT_iOS

@Suite("CoverWallModel")
@MainActor
struct CoverWallModelTests {

    // MARK: - Decoding a real answer

    @Test func itReadsTheCoversOfARealAnswer() async {
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(Self.realAnswer)),
            defaults: freshDefaults()
        )

        await model.refresh()

        #expect(model.coverPaths == [
            "/img/entities/aad39462d658e8ad98c0af6db893a7270f2b8dbf",
            "/img/entities/a849b14309d1a3c2f70613d234c94e700c8e42e2",
            "/img/entities/b85b1785cd72f085d5ebe1b035689f95c13406ce",
        ])
    }

    /// The endpoint is asked for by path, not by the `?action=` alias inventaire.io deprecated
    /// server-wide — and asked for without a session, since nobody is signed in.
    @Test func itCallsTheEndpointByPath() async {
        let requested: RequestRecorder = .init()
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(Self.realAnswer), recorder: requested),
            defaults: freshDefaults()
        )

        await model.refresh()

        let url: String = requested.lastUrl ?? ""

        #expect(url.contains("/api/items/recent-public"))
        #expect(url.contains("action=") == false)
        #expect(url.contains("limit=60"))
    }

    // MARK: - Manners on failure

    @Test func aTransportFailureLeavesTheWallAlone() async {
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .failure),
            defaults: freshDefaults(),
            coverPaths: ["/img/entities/kept"]
        )

        await model.refresh()

        #expect(model.coverPaths == ["/img/entities/kept"])
    }

    @Test(arguments: [404, 429, 500]) func aServerErrorLeavesTheWallAlone(status: Int) async {
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(Self.realAnswer, status: status)),
            defaults: freshDefaults(),
            coverPaths: ["/img/entities/kept"]
        )

        await model.refresh()

        #expect(model.coverPaths == ["/img/entities/kept"])
    }

    @Test func anUnreadablePayloadLeavesTheWallAlone() async {
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(Data("<html>nope</html>".utf8))),
            defaults: freshDefaults(),
            coverPaths: ["/img/entities/kept"]
        )

        await model.refresh()

        #expect(model.coverPaths == ["/img/entities/kept"])
    }

    /// An answer with no usable cover is not an answer worth showing: the wall that is up stays
    /// up rather than turning into a painted one.
    @Test func anAnswerWithoutCoversLeavesTheWallAlone() async {
        let empty: Data = Data(#"{"items":[{"snapshot":{"entity:title":"Sans couverture"}}]}"#.utf8)
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(empty)),
            defaults: freshDefaults(),
            coverPaths: ["/img/entities/kept"]
        )

        await model.refresh()

        #expect(model.coverPaths == ["/img/entities/kept"])
    }

    @Test func anEmptyFeedLeavesTheWallAlone() async {
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(Data(#"{"items":[]}"#.utf8))),
            defaults: freshDefaults(),
            coverPaths: ["/img/entities/kept"]
        )

        await model.refresh()

        #expect(model.coverPaths == ["/img/entities/kept"])
    }

    // MARK: - Remembering

    /// The point of the cache: a second launch without a network draws yesterday's wall at the
    /// first frame, rather than the painted one.
    @Test func itComesUpOnTheWallItLastDrew() async {
        let defaults: UserDefaults = freshDefaults()
        let first: CoverWallModel = .init(
            apiService: apiService(answering: .success(Self.realAnswer)),
            defaults: defaults
        )
        await first.refresh()

        let second: CoverWallModel = .init(
            apiService: apiService(answering: .failure),
            defaults: defaults
        )

        #expect(second.coverPaths == first.coverPaths)
        #expect(second.coverPaths.count == 3)
    }

    @Test func aFailedRefreshKeepsWhatWasPersisted() async {
        let defaults: UserDefaults = freshDefaults()
        let seeded: CoverWallModel = .init(
            apiService: apiService(answering: .success(Self.realAnswer)),
            defaults: defaults
        )
        await seeded.refresh()

        let offline: CoverWallModel = .init(
            apiService: apiService(answering: .failure),
            defaults: defaults
        )
        await offline.refresh()

        #expect(defaults.stringArray(forKey: CoverWallModel.storageKey)?.count == 3)
        #expect(offline.coverPaths.count == 3)
    }

    @Test func aSuccessfulRefreshReplacesWhatWasPersisted() async {
        let defaults: UserDefaults = freshDefaults()
        defaults.set(["/img/entities/old"], forKey: CoverWallModel.storageKey)

        let model: CoverWallModel = .init(
            apiService: apiService(answering: .success(Self.realAnswer)),
            defaults: defaults
        )
        await model.refresh()

        #expect(defaults.stringArray(forKey: CoverWallModel.storageKey) == model.coverPaths)
        #expect(model.coverPaths.contains("/img/entities/old") == false)
    }

    /// A file on disk is not a promise: an older build could have written a thousand paths, and
    /// a wall does not need them.
    @Test func itCapsWhatItReadsBack() {
        let defaults: UserDefaults = freshDefaults()
        defaults.set((0..<500).map { "/img/entities/\($0)" }, forKey: CoverWallModel.storageKey)

        let model: CoverWallModel = .init(
            apiService: apiService(answering: .failure),
            defaults: defaults
        )

        #expect(model.coverPaths.count == CoverWallCatalog.coverLimit)
    }

    @Test func nothingPersistedIsAPaintedWall() {
        let model: CoverWallModel = .init(
            apiService: apiService(answering: .failure),
            defaults: freshDefaults()
        )

        #expect(model.coverPaths.isEmpty)
    }

    // MARK: - Support

    private enum Answer {
        case success(Data, status: Int = 200)
        case failure
    }

    /// Collects what the model actually put on the wire.
    private final class RequestRecorder: @unchecked Sendable {
        private let lock: NSLock = .init()
        private var url: String?

        var lastUrl: String? {
            lock.lock(); defer { lock.unlock() }
            return url
        }

        func record(_ request: URLRequest) {
            lock.lock(); defer { lock.unlock() }
            url = request.url?.absoluteString
        }
    }

    /// A defaults domain of this test's own. Swift Testing runs suites in parallel, and a
    /// shared `standard` would have one test reading another's wall.
    private func freshDefaults() -> UserDefaults {
        let suite: String = "CoverWallModelTests.\(UUID().uuidString)"
        let defaults: UserDefaults = .init(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        return defaults
    }

    private func apiService(
        answering answer: Answer,
        recorder: RequestRecorder? = nil
    ) -> APIService {
        let session: URLSession = MockURLProtocol.makeSession { request in
            recorder?.record(request)

            switch answer {
            case .success(let data, let status):
                let response: HTTPURLResponse = .init(
                    url: request.url ?? URL(string: "https://inventaire.io")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, data)

            case .failure:
                throw URLError(.notConnectedToInternet)
            }
        }

        return .init(env: .production, session: session)
    }

    /// A real `recent-public` answer, trimmed to three items. Kept verbatim otherwise.
    private static let realAnswer: Data = Data("""
    {
      "items": [
        {
          "_id": "b3486b91b1161f1e712959d0d4149568",
          "_rev": "1-7e63d382e29dcfb4b40a076c076709b4",
          "entity": "inv:b3486b91b1161f1e712959d0d41488a3",
          "transaction": "lending",
          "shelves": [],
          "owner": "a295a78be16b5a714e74fd6a9d10a204",
          "created": 1788552483418,
          "snapshot": {
            "entity:title": "Ein Museum für den Frieden",
            "entity:lang": "de",
            "entity:worksUris": ["inv:b3486b91b1161f1e712959d0d413b8ce"],
            "entity:authorsUris": ["wd:Q133006258"],
            "entity:seriesUris": [],
            "entity:authors": "Tommy Spree",
            "entity:image": "/img/entities/aad39462d658e8ad98c0af6db893a7270f2b8dbf"
          }
        },
        {
          "_id": "b3486b91b1161f1e712959d0d410da75",
          "_rev": "2-f1f0d95379949a321c107634cc86de1e",
          "entity": "inv:b3486b91b1161f1e712959d0d410c38c",
          "transaction": "lending",
          "shelves": ["b3486b91b1161f1e712959d0d410caa2"],
          "owner": "bc897598715ff40f8c3306339a7e3eea",
          "created": 1788537155033,
          "details": "Explication de l'augmentation des frais d'inscription publics.",
          "updated": 1788608614260,
          "snapshot": {
            "entity:title": "Le marché aux connaissances",
            "entity:lang": "fr",
            "entity:worksUris": ["inv:b3486b91b1161f1e712959d0d410c064"],
            "entity:authorsUris": ["inv:b3486b91b1161f1e712959d0d410bc70"],
            "entity:seriesUris": [],
            "entity:authors": "Lawrence Busch",
            "entity:image": "/img/entities/a849b14309d1a3c2f70613d234c94e700c8e42e2",
            "entity:isbn13": "978-2-7592-2205-6",
            "entity:isbn10": "2-7592-2205-5"
          }
        },
        {
          "_id": "b3486b91b1161f1e712959d0d406dbc6",
          "_rev": "1-4c5a984648f21991e94e98a3b8b71d54",
          "entity": "inv:1fdd61c1d263f358c20182d0b3f474dd",
          "transaction": "inventorying",
          "shelves": [],
          "owner": "5c87c38af9cb6b60061da5c4fe2df1f5",
          "created": 1788526579081,
          "snapshot": {
            "entity:title": "Beauté fatale",
            "entity:lang": "fr",
            "entity:worksUris": ["wd:Q63453776"],
            "entity:authorsUris": ["wd:Q3320033"],
            "entity:seriesUris": [],
            "entity:authors": "Mona Chollet",
            "entity:image": "/img/entities/b85b1785cd72f085d5ebe1b035689f95c13406ce"
          }
        }
      ],
      "users": [
        {
          "_id": "a295a78be16b5a714e74fd6a9d10a204",
          "username": "someone",
          "created": 1720000000000
        }
      ]
    }
    """.utf8)
}
