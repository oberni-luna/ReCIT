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
    private(set) var recordedRequests: [(endpoint: String, method: String)] = []
    var baseURLValue: String = "https://test.local"

    // MARK: - Stubbing

    func stub(_ match: String, json: String) {
        stubs.append((match, .data(Data(json.utf8))))
    }

    func stub(_ match: String, error: Error) {
        stubs.append((match, .failure(error)))
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
        return try decodeStub(for: endpoint)
    }

    func fetchData<T: Codable>(
        fromEndpoint endpoint: String,
        debug: Bool
    ) async throws -> T? {
        recordedRequests.append((endpoint, "GET"))
        return try decodeStub(for: endpoint)
    }

    // MARK: - Helpers

    private func decodeStub<R: Decodable>(for endpoint: String) throws -> R? {
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
