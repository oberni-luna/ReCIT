//
//  MockURLProtocol.swift
//  ReCIT_iOSTests
//
//  Intercepts URLSession traffic so the real `APIService` can be exercised
//  against canned HTTP responses without any network access.
//

import Foundation

final class MockURLProtocol: URLProtocol {
    /// Set before each test. Serial test execution makes the shared handler safe.
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    nonisolated static func makeSession() -> URLSession {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    nonisolated override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    nonisolated override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    nonisolated override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data): (HTTPURLResponse, Data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    nonisolated override func stopLoading() {}
}
