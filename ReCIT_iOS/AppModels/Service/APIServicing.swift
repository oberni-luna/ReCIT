//
//  APIServicing.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni.
//

import Foundation

/// Abstraction over the network layer so app models can be tested against a
/// mock implementation instead of hitting the live `inventaire.io` backend.
protocol APIServicing {
    func baseUrl() -> String
    func absoluteImageUrl(_ path: String?) -> String?

    func send<T: Codable, U: Codable>(
        toEndpoint endpoint: String,
        method: String,
        payload: T,
        debug: Bool
    ) async throws -> U?

    /// A verb with no body at all — `DELETE /api/user` is the first of them.
    ///
    /// Separate from `send(toEndpoint:method:payload:debug:)` rather than a nil payload: the
    /// endpoints that take nothing take *nothing*, and an empty JSON object sent to one is a
    /// body the server never asked for. Nothing is written to `httpBody`, so the request on the
    /// wire is the one the spec describes.
    func send<U: Codable>(
        toEndpoint endpoint: String,
        method: String,
        debug: Bool
    ) async throws -> U?

    func fetchData<T: Codable>(
        fromEndpoint endpoint: String,
        debug: Bool
    ) async throws -> T?
}

// MARK: - Convenience overloads (default arguments)

extension APIServicing {
    func send<T: Codable, U: Codable>(
        toEndpoint endpoint: String,
        payload: T
    ) async throws -> U? {
        try await send(toEndpoint: endpoint, method: "POST", payload: payload, debug: false)
    }

    func send<T: Codable, U: Codable>(
        toEndpoint endpoint: String,
        payload: T,
        debug: Bool
    ) async throws -> U? {
        try await send(toEndpoint: endpoint, method: "POST", payload: payload, debug: debug)
    }

    func send<T: Codable, U: Codable>(
        toEndpoint endpoint: String,
        method: String,
        payload: T
    ) async throws -> U? {
        try await send(toEndpoint: endpoint, method: method, payload: payload, debug: false)
    }

    func send<U: Codable>(
        toEndpoint endpoint: String,
        method: String
    ) async throws -> U? {
        try await send(toEndpoint: endpoint, method: method, debug: false)
    }

    func fetchData<T: Codable>(fromEndpoint endpoint: String) async throws -> T? {
        try await fetchData(fromEndpoint: endpoint, debug: false)
    }
}
