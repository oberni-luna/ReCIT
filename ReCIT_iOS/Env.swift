//
//  Env.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation

enum Env {
    case development
    case production

    /// `-ExLibrisBackend http://localhost:8080` on a debug launch, read from the arguments domain.
    /// A release build never reads it.
    private static let backendOverride: String? = {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "ExLibrisBackend")
        #else
        return nil
        #endif
    }()

    public var apiBaseUrl: String {
        apiBaseUrl(backendOverride: Self.backendOverride)
    }

    public var keychainKey: String {
        keychainKey(backendOverride: Self.backendOverride)
    }

    func apiBaseUrl(backendOverride: String?) -> String {
        backendOverride ?? "https://inventaire.io"
    }

    /// Suffixed while another backend is in use, so its session and inventaire.io's never overwrite each other.
    func keychainKey(backendOverride: String?) -> String {
        let key: String = switch self {
        case .development:
            "asso.recits.auth.cookies.dev"
        case .production:
            "asso.recits.auth.cookies"
        }
        return backendOverride == nil ? key : "\(key).exlibris"
    }
}
