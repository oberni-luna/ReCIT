//
//  APIService.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation
import OSLog

final class APIService: APIServicing {
    private static let logger: Logger = .init(subsystem: "asso.recits", category: "network")

    private let session: URLSession
    private let env: Env

    init(env: Env, session: URLSession = .shared) {
        self.env = env
        self.session = session
    }

    func baseUrl() -> String {
        env.apiBaseUrl
    }

    //    https://commons.wikimedia.org/wiki/Special:FilePath/Mathieu%20Bablet%202023.jpg?width=56
    //    "https://commons.wikimedia.org/wiki/Special:FilePath/Mathieu Bablet 2023.jpg"
    func absoluteImageUrl(_ path: String?) -> String? {
        guard let path else { return nil }
        if path.hasPrefix("http") {
            return path
        } else if path.hasPrefix("/img") {
            return "\(self.baseUrl())\(path)"
        } else {
            return "https://commons.wikimedia.org/wiki/Special:FilePath/\(path)?width=512"
        }
    }

    func send<T: Codable, U: Codable>(
        toEndpoint endpoint: String,
        method: String = "POST",
        payload: T,
        debug: Bool = false
    ) async throws -> U? {
        guard let url = URL(string: "\(env.apiBaseUrl)\(endpoint)") else {
            throw NetworkError.badUrl
        }

        var request: URLRequest = .init(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw NetworkError.failedToEncodeRequest(underlying: error)
        }

        log(request: url, method: method, debug: debug)

        let responseData: Data = try await perform(request: request, debug: debug)

        do {
            return try JSONDecoder().decode(U.self, from: responseData)
        } catch {
            Self.logger.error("Decoding failed for \(url, privacy: .public): \(error, privacy: .public)")
            throw NetworkError.failedToDecodeResponse(underlying: error)
        }
    }

    /// The same request without a body, for the endpoints that take none.
    ///
    /// No `Content-Type` either: there is no content to type. `DELETE /api/user` is the first
    /// caller — its sanitization on the server is the empty object, and the spec documents no
    /// parameter, so anything sent here would be noise the server has to ignore.
    func send<U: Codable>(
        toEndpoint endpoint: String,
        method: String,
        debug: Bool = false
    ) async throws -> U? {
        guard let url = URL(string: "\(env.apiBaseUrl)\(endpoint)") else {
            throw NetworkError.badUrl
        }

        var request: URLRequest = .init(url: url)
        request.httpMethod = method

        log(request: url, method: method, debug: debug)

        let responseData: Data = try await perform(request: request, debug: debug)

        do {
            return try JSONDecoder().decode(U.self, from: responseData)
        } catch {
            Self.logger.error("Decoding failed for \(url, privacy: .public): \(error, privacy: .public)")
            throw NetworkError.failedToDecodeResponse(underlying: error)
        }
    }

    func fetchData<T: Codable>(
        fromEndpoint endpoint: String,
        debug: Bool = false
    ) async throws -> T? {
        guard let url = URL(string: "\(env.apiBaseUrl)\(endpoint)") else {
            throw NetworkError.badUrl
        }

        log(request: url, method: "GET", debug: debug)

        let request: URLRequest = .init(url: url)
        let data: Data = try await perform(request: request, debug: debug)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            Self.logger.error("Decoding failed for \(url, privacy: .public): \(error, privacy: .public)")
            throw NetworkError.failedToDecodeResponse(underlying: error)
        }
    }

    /// Sends one image as `multipart/form-data` and answers the url the server filed it under.
    ///
    /// Hand-built rather than reached for through a library: it is one part, one file, and the
    /// whole body fits in memory — a cover is a few hundred kilobytes. The server reads the
    /// **form field name** as the image's id and indexes its answer by it, so the url comes
    /// back under the name we sent.
    ///
    /// See PRD 0015.
    func upload(
        imageData: Data,
        fileName: String,
        fieldName: String,
        container: String,
        debug: Bool = false
    ) async throws -> String? {
        guard let url = URL(string: "\(env.apiBaseUrl)/api/images/upload?container=\(container)") else {
            throw NetworkError.badUrl
        }

        let boundary: String = "Boundary-\(UUID().uuidString)"

        var request: URLRequest = .init(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body: Data = .init()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(imageData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body

        log(request: url, method: "POST", debug: debug)

        let responseData: Data = try await perform(request: request, debug: debug)

        do {
            let urlsByFieldName: [String: String] = try JSONDecoder().decode([String: String].self, from: responseData)
            return urlsByFieldName[fieldName]
        } catch {
            Self.logger.error("Decoding failed for \(url, privacy: .public): \(error, privacy: .public)")
            throw NetworkError.failedToDecodeResponse(underlying: error)
        }
    }

    // MARK: - Private helpers

    /// Performs the request using the injected session and validates the HTTP
    /// status, surfacing typed `NetworkError`s instead of swallowing failures.
    private func perform(request: URLRequest, debug: Bool) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transport(underlying: error)
        }

        if debug {
            Self.logger.debug("Response: \(String(decoding: data, as: UTF8.self), privacy: .public)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message: String = String(decoding: data, as: UTF8.self)
            throw NetworkError.badStatus(code: httpResponse.statusCode, message: message)
        }

        return data
    }

    private func log(request url: URL, method: String, debug: Bool) {
        guard debug else { return }
        Self.logger.debug("\(method, privacy: .public) \(url, privacy: .public)")
    }
}
