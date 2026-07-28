//
//  APIServiceTests.swift
//  ReCIT_iOSTests
//
//  Exercises the real APIService error handling through a mocked URLProtocol.
//

import Foundation
import Testing
@testable import ReCIT_iOS

private struct Probe: Codable, Equatable {
    let value: String
}

@Suite("APIService error handling", .serialized)
struct APIServiceTests {
    private func makeService() -> APIService {
        .init(env: .production, session: MockURLProtocol.makeSession())
    }

    private func respond(status: Int, body: Data) {
        MockURLProtocol.requestHandler = { request in
            let response: HTTPURLResponse = .init(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body)
        }
    }

    @Test("Decodes a successful 2xx JSON response")
    func decodesSuccess() async throws {
        respond(status: 200, body: Data(#"{"value":"ok"}"#.utf8))
        let service: APIService = makeService()

        let probe: Probe? = try await service.fetchData(fromEndpoint: "/probe")

        #expect(probe == Probe(value: "ok"))
    }

    @Test("Throws badStatus with the real status code on non-2xx")
    func throwsBadStatus() async throws {
        respond(status: 403, body: Data(#"{"status":"forbidden"}"#.utf8))
        let service: APIService = makeService()

        do {
            let _: Probe? = try await service.fetchData(fromEndpoint: "/probe")
            Issue.record("Expected a NetworkError to be thrown")
        } catch let NetworkError.badStatus(code, _) {
            #expect(code == 403)
        }
    }

    @Test("Throws failedToDecodeResponse on malformed JSON")
    func throwsDecodeError() async throws {
        respond(status: 200, body: Data(#"{"unexpected":true}"#.utf8))
        let service: APIService = makeService()

        do {
            let _: Probe? = try await service.fetchData(fromEndpoint: "/probe")
            Issue.record("Expected a decode error to be thrown")
        } catch NetworkError.failedToDecodeResponse {
            // expected
        }
    }

    @Test("Wraps transport failures as NetworkError.transport")
    func throwsTransport() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let service: APIService = makeService()

        do {
            let _: Probe? = try await service.fetchData(fromEndpoint: "/probe")
            Issue.record("Expected a transport error to be thrown")
        } catch NetworkError.transport {
            // expected
        }
    }
}
