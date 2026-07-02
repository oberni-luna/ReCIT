//
//  NetworkError.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation

enum NetworkError: Error {
    case badUrl
    case invalidRequest
    case badResponse
    case badStatus(code: Int, message: String?)
    case failedToEncodeRequest(underlying: Error)
    case failedToDecodeResponse(underlying: Error)
    case transport(underlying: Error)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .badUrl:
            String(localized: "error.network.bad_url")
        case .invalidRequest:
            String(localized: "error.network.invalid_request")
        case .badResponse:
            String(localized: "error.network.bad_response")
        case .badStatus:
            String(localized: "error.network.bad_status")
        case .failedToEncodeRequest:
            String(localized: "error.network.encode_failed")
        case .failedToDecodeResponse:
            String(localized: "error.network.decode_failed")
        case .transport(let underlying):
            underlying.localizedDescription
        }
    }

    /// Detailed, developer-facing description used for logging. Includes the
    /// underlying error so the root cause is never lost.
    var debugDescription: String {
        switch self {
        case .badUrl:
            "Failed to build a valid URL."
        case .invalidRequest:
            "The request was invalid."
        case .badResponse:
            "The response was not a valid HTTP response."
        case .badStatus(let code, let message):
            "Bad HTTP status \(code): \(message ?? "<no message>")"
        case .failedToEncodeRequest(let underlying):
            "Failed to encode the request payload: \(underlying)"
        case .failedToDecodeResponse(let underlying):
            "Failed to decode the response: \(underlying)"
        case .transport(let underlying):
            "Transport error: \(underlying)"
        }
    }
}
