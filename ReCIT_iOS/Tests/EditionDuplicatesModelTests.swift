//
//  EditionDuplicatesModelTests.swift
//  ReCIT_iOSTests
//
//  What « Éditions » sends to and reads from inventaire.io about duplicates — every request
//  answered by `MockURLProtocol`, none of them reaching the network, no merge ever made for real.
//  PRD 0028.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Edition duplicates model", .serialized)
struct EditionDuplicatesModelTests {

    // MARK: - Fixtures

    /// A request as the mock received it: method, path and query, and its JSON body.
    struct Sent: Sendable {
        let method: String
        let url: URL
        let body: Data?
    }

    final class Recorder: @unchecked Sendable {
        private let lock: NSLock = .init()
        private var storage: [Sent] = []

        var requests: [Sent] {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }

        func record(_ request: URLRequest) {
            lock.lock()
            defer { lock.unlock() }
            storage.append(.init(method: request.httpMethod ?? "GET", url: request.url!, body: request.bodyData))
        }
    }

    /// An `APIService` whose answers come from `respond`, keyed on the request's path.
    private func service(
        recorder: Recorder,
        respond: @escaping @Sendable (URLRequest) -> (Int, String)
    ) -> APIService {
        let session: URLSession = MockURLProtocol.makeSession { request in
            recorder.record(request)
            let (status, body): (Int, String) = respond(request)
            let response: HTTPURLResponse = .init(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
        return .init(env: .production, session: session)
    }

    private struct Store {
        let context: ModelContext
        let work: Work
        let kept: Edition
        let gone: Edition
    }

    /// A work with two editions of one ISBN: `wd:Q1`, to keep, and `inv:A`, to merge from.
    private func store() throws -> Store {
        let context: ModelContext = try TestStore.makeContext()
        let work: Work = .init(uri: "wd:W1", lastrevid: 1, title: "Le Comte de Monte-Cristo")
        let kept: Edition = .init(uri: "wd:Q1", title: "Tome 1", lang: "fr", authorNames: [])
        let gone: Edition = .init(uri: "inv:A", title: "Tome 1 bis", lang: "fr", authorNames: [])
        kept.isbn = "978-2-07-036822-8"
        gone.isbn = "978-2-07-036822-8"
        gone.invUri = "inv:A"
        context.insert(work)
        context.insert(kept)
        context.insert(gone)
        kept.mergeWorks([work])
        gone.mergeWorks([work])
        try context.save()
        return .init(context: context, work: work, kept: kept, gone: gone)
    }

    private func pair(_ store: Store) throws -> EditionDuplicatePair {
        try #require(EditionDuplicateDetector.detect(store.work.editions.map(EditionFacts.init)).pairs.first)
    }

    // MARK: - « Ce ne sont pas les mêmes »

    @Test("« Ce ne sont pas les mêmes » writes wdt:P1889 on the inv: edition, and the pair is gone at once")
    func notTheSameWritesTheClaim() async throws {
        let store: Store = try store()
        let recorder: Recorder = .init()
        let api: APIService = service(recorder: recorder) { _ in (200, #"{"ok":true}"#) }
        let model: EditionDuplicatesModel = .init(apiService: api)

        let task: Task<Void, Never>? = model.markNotTheSame(try pair(store), modelContext: store.context)
        #expect(store.gone.differentFromUris == ["wd:Q1"])
        #expect(EditionDuplicateDetector.detect(store.work.editions.map(EditionFacts.init)).pairs.isEmpty)
        await task?.value

        let request: Sent = try #require(recorder.requests.first)
        #expect(request.method == "PUT")
        #expect(request.url.path == "/api/entities/update-claim")
        let body: [String: String] = try JSONDecoder().decode([String: String].self, from: try #require(request.body))
        #expect(body == ["uri": "inv:A", "property": "wdt:P1889", "new-value": "wd:Q1"])
        #expect(store.gone.differentFromUris == ["wd:Q1"])
    }

    @Test("A refused claim brings the pair back and is reported")
    func notTheSameRevertsOnFailure() async throws {
        let store: Store = try store()
        let reporter: AppErrorReporter = .init()
        let api: APIService = service(recorder: .init()) { _ in (403, #"{"status_verbose":"forbidden"}"#) }
        let model: EditionDuplicatesModel = .init(apiService: api, errorReporter: reporter)

        await model.markNotTheSame(try pair(store), modelContext: store.context)?.value

        #expect(store.gone.differentFromUris.isEmpty)
        #expect(EditionDuplicateDetector.detect(store.work.editions.map(EditionFacts.init)).pairs.count == 1)
        #expect(reporter.lastFailure != nil)
    }

    // MARK: - Pending reports

    @Test("An open merge task tags both editions « Doublon signalé »")
    func pendingReportIsRecorded() async throws {
        let store: Store = try store()
        let recorder: Recorder = .init()
        let api: APIService = service(recorder: recorder) { _ in
            (200, #"{"tasks":{"inv:A":[{"type":"merge","suspectUri":"inv:A","suggestionUri":"wd:Q1"}]}}"#)
        }

        await EditionDuplicatesModel(apiService: api).refreshPendingReports(modelContext: store.context, work: store.work)

        let request: Sent = try #require(recorder.requests.first)
        #expect(request.url.path == "/api/tasks/by-uris")
        #expect(request.url.query?.contains("uris=inv:A") == true)
        #expect(request.url.query?.contains("wd:Q1") == false)
        #expect(store.gone.pendingMergeTargetUris == ["wd:Q1"])
        let duplicates: EditionDuplicates = EditionDuplicateDetector.detect(store.work.editions.map(EditionFacts.init))
        #expect(duplicates.pairs.isEmpty)
        #expect(duplicates.tags == ["inv:A": .reported, "wd:Q1": .reported])
    }

    @Test("A task closed since takes the tag away; a failed call keeps it")
    func closedTaskClearsTheTag() async throws {
        let store: Store = try store()
        store.gone.pendingMergeTargetUris = ["wd:Q1"]

        let failing: APIService = service(recorder: .init()) { _ in (500, "{}") }
        await EditionDuplicatesModel(apiService: failing).refreshPendingReports(modelContext: store.context, work: store.work)
        #expect(store.gone.pendingMergeTargetUris == ["wd:Q1"])

        let answering: APIService = service(recorder: .init()) { _ in
            (200, #"{"tasks":{"inv:A":[{"type":"merge","state":"dismissed","suspectUri":"inv:A","suggestionUri":"wd:Q1"}]}}"#)
        }
        await EditionDuplicatesModel(apiService: answering).refreshPendingReports(modelContext: store.context, work: store.work)
        #expect(store.gone.pendingMergeTargetUris.isEmpty)
    }
}

private extension URLRequest {
    /// The body `URLProtocol` sees: a JSON body arrives as a stream, not as `httpBody`.
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data: Data = .init()
        var buffer: [UInt8] = .init(repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read: Int = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
