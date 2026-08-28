//
//  MockURLProtocol.swift
//  ReCIT_iOSTests
//
//  Intercepts URLSession traffic so the real services can be exercised against canned HTTP
//  responses without any network access.
//
//  Two ways in. `requestHandler` is the original process-wide one, which works as long as one
//  suite at a time uses it. `makeSession(handler:)` files the handler under a token carried in
//  the session's own headers instead, so two suites can hold the protocol at once — Swift
//  Testing runs top-level suites in parallel, and the moment a second suite touched the shared
//  handler the first one started failing at random.
//

import Foundation

final class MockURLProtocol: URLProtocol {
    /// Set before each test. Serial test execution makes the shared handler safe.
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Handlers scoped to one session, keyed by the token that session stamps on its requests.
    nonisolated(unsafe) private static var handlersByToken: [String: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
    private static let handlersLock: NSLock = .init()

    static let tokenHeader: String = "X-Mock-Session-Token"

    nonisolated static func makeSession() -> URLSession {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// A session whose responses come from `handler` and from nowhere else. Use this rather than
    /// the shared `requestHandler` in any suite that may run beside another one.
    nonisolated static func makeSession(
        handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> URLSession {
        let token: String = UUID().uuidString
        handlersLock.lock()
        handlersByToken[token] = handler
        handlersLock.unlock()

        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = [tokenHeader: token]
        return URLSession(configuration: configuration)
    }

    nonisolated private static func handler(for request: URLRequest) -> (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        if let token = request.value(forHTTPHeaderField: tokenHeader) {
            handlersLock.lock()
            defer { handlersLock.unlock() }
            return handlersByToken[token]
        }
        return requestHandler
    }

    nonisolated override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    nonisolated override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    nonisolated override func startLoading() {
        guard let handler = MockURLProtocol.handler(for: request) else {
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
