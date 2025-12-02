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

    public var apiBaseUrl: String {
        switch self {
        case .development:
            return "https://inventaire.io"
        case .production:
            return "https://inventaire.io"
        }
    }

    public var keychainKey: String {
        switch self {
        case .development:
            return "asso.recits.auth.cookies.dev"
        case .production:
            return "asso.recits.auth.cookies"
        }
    }
}

