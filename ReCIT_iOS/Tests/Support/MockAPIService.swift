//
//  MockAPIService.swift
//  ReCIT_iOSTests
//
//  Test double for `APIServicing`. Stubs are matched against the requested
//  endpoint by substring, in registration order (first match wins), so tests
//  never touch the live `inventaire.io` backend.
//

import Foundation
@testable import ReCIT_iOS

@MainActor
final class MockAPIService: APIServicing {
    enum Stub {
        case data(Data)
        case failure(Error)
    }

    private var stubs: [(match: String, stub: Stub)] = []
    /// Answers given one after the other, before `stubs` are looked at: two calls to one
    /// endpoint that must answer differently — two entities created, two uris.
    private var sequences: [(match: String, answers: [Data])] = []
    /// What an upload answers, and how it fails. Kept apart from `stubs`, which decode JSON
    /// into a `Codable`: an upload answers one url.
    var uploadedImageUrl: String?
    var uploadFailure: Error?
    private(set) var uploadedImageSizes: [Int] = []
    private(set) var recordedRequests: [(endpoint: String, method: String)] = []
    var baseURLValue: String = "https://test.local"
    /// Called with each fetched endpoint before its stub answers — the moment a test can change
    /// the store under a model that is waiting on the network.
    var onFetch: ((String) -> Void)?
    /// The JSON bodies sent with a payload, in order: what a test reads when several calls share
    /// an endpoint, and the endpoint alone does not say which one was which.
    private(set) var sentPayloads: [Data] = []
    /// Called with the index of each send that carries a payload, before its stub answers. A
    /// throw fails that call alone — the second of three to one endpoint, say.
    var onSend: ((Int) throws -> Void)?

    // MARK: - Stubbing

    func stub(_ match: String, json: String) {
        stubs.append((match, .data(Data(json.utf8))))
    }

    func stub(_ match: String, error: Error) {
        stubs.append((match, .failure(error)))
    }

    /// `match` answers each of `jsons` in turn, then falls back on `stubs`.
    func stub(_ match: String, jsonSequence jsons: [String]) {
        sequences.append((match, jsons.map { Data($0.utf8) }))
    }

    /// Replaces what `match` answers, keeping its place in the order: a server whose answer
    /// changed between two calls of the same model.
    func restub(_ match: String, json: String) {
        if let index = stubs.firstIndex(where: { $0.match == match }) {
            stubs[index] = (match, .data(Data(json.utf8)))
        } else {
            stub(match, json: json)
        }
    }

    // MARK: - APIServicing

    func baseUrl() -> String {
        baseURLValue
    }

    func absoluteImageUrl(_ path: String?) -> String? {
        guard let path else { return nil }
        return path.hasPrefix("http") ? path : "\(baseURLValue)\(path)"
    }

    func send<T: Codable, U: Codable>(
        toEndpoint endpoint: String,
        method: String,
        payload: T,
        debug: Bool
    ) async throws -> U? {
        recordedRequests.append((endpoint, method))
        let index: Int = sentPayloads.count
        sentPayloads.append((try? JSONEncoder().encode(payload)) ?? Data())
        try onSend?(index)
        return try decodeStub(for: endpoint)
    }

    func send<U: Codable>(
        toEndpoint endpoint: String,
        method: String,
        debug: Bool
    ) async throws -> U? {
        recordedRequests.append((endpoint, method))
        return try decodeStub(for: endpoint)
    }

    func fetchData<T: Codable>(
        fromEndpoint endpoint: String,
        debug: Bool
    ) async throws -> T? {
        recordedRequests.append((endpoint, "GET"))
        onFetch?(endpoint)
        return try decodeStub(for: endpoint)
    }

    func upload(
        imageData: Data,
        fileName: String,
        fieldName: String,
        container: String,
        debug: Bool
    ) async throws -> String? {
        recordedRequests.append(("/api/images/upload?container=\(container)", "POST"))
        uploadedImageSizes.append(imageData.count)

        if let uploadFailure { throw uploadFailure }
        return uploadedImageUrl
    }

    // MARK: - Helpers

    private func decodeStub<R: Decodable>(for endpoint: String) throws -> R? {
        if let index = sequences.firstIndex(where: { endpoint.hasSuffix($0.match) && $0.answers.isEmpty == false }) {
            let data: Data = sequences[index].answers.removeFirst()
            return try JSONDecoder().decode(R.self, from: data)
        }

        guard let match = stubs.first(where: { endpoint.contains($0.match) }) else {
            throw NetworkError.badStatus(code: 404, message: "No stub registered for \(endpoint)")
        }
        switch match.stub {
        case .failure(let error):
            throw error
        case .data(let data):
            return try JSONDecoder().decode(R.self, from: data)
        }
    }
}
