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

    func fetchData<T: Codable>(fromEndpoint endpoint: String) async throws -> T? {
        try await fetchData(fromEndpoint: endpoint, debug: false)
    }
}
