//
//  AuthManager.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//

import Foundation
import SwiftUI
import Combine
import Security

// MARK: - AuthManager

final class AuthService {
    struct Config: Sendable {
        let baseURL: String
        let loginPath: String
        let logoutPath: String
        /// Noms des cookies considérés comme "session" par votre backend (ex: ["SESSIONID", "authToken"])
        let sessionCookieNames: Set<String>
        /// Clé Keychain (namespace par environnement/app)
        let keychainKey: String

        init(
            baseURL: String = "https://inventaire.io/api",
            loginPath: String = "/auth?action=login",
            logoutPath: String = "/auth?action=logout",
            sessionCookieNames: Set<String> = [
                "inventaire:session",
                "inventaire:session.sig"
            ],
            keychainKey: String = "asso.recits.auth.cookies"
        ) {
            self.baseURL = baseURL
            self.loginPath = loginPath
            self.logoutPath = logoutPath
            self.sessionCookieNames = sessionCookieNames
            self.keychainKey = keychainKey
        }
    }

    enum AuthError: Error {
        case invalidCredentials
        case network(underlying: Error)
        case serverStatus(code: Int)
        case noSessionCookies
        case keychainError(status: OSStatus)
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidCredentials: return "Identifiants invalides."
            case .network(let e):     return "Erreur réseau: \(e.localizedDescription)"
            case .serverStatus(let c):return "Erreur serveur (\(c))."
            case .noSessionCookies:   return "Aucun cookie de session reçu."
            case .keychainError(let s): return "Erreur Keychain (\(s))."
            case .unknown:            return "Erreur inconnue."
            }
        }
    }

    private let cfg: Config
    private let cookieStorage: HTTPCookieStorage
    private let session: URLSession

    init(
        config: Config,
        cookieStorage: HTTPCookieStorage = .shared,
        session: URLSession = .shared
    ) {
        self.cfg = config
        self.cookieStorage = cookieStorage
        self.session = session

        // Tente de restaurer les cookies persistés au lancement
        restoreCookiesFromKeychain()
    }

    // MARK: - Public API

    func isLoggedIn() -> Bool {
        hasValidSessionCookies()
    }

    /// Exemple de login avec body JSON { "username": "...", "password": "..." }
    /// Adaptez au format réel de votre API.
    func login(username: String, password: String) async throws {
        var request = URLRequest(url: URL(string: cfg.baseURL + cfg.loginPath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Payload: Encodable { let username: String; let password: String }
        request.httpBody = try JSONEncoder().encode(Payload(username: username, password: password))

        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw AuthError.unknown
            }
            guard (200..<300).contains(http.statusCode) else {
                if http.statusCode == 401 || http.statusCode == 403 {
                    throw AuthError.invalidCredentials
                }
                throw AuthError.serverStatus(code: http.statusCode)
            }

            // À ce stade, URLSession/HTTPCookieStorage a déjà absorbé les Set-Cookie.
            // On vérifie qu'on a bien reçu les cookies attendus puis on les persiste.
            guard hasValidSessionCookies() else {
                // Parfois les APIs renvoient aussi un body JSON utile ; libre à vous de l’exploiter
                _ = data // pour éviter un warning si vous ne l’utilisez pas
                throw AuthError.noSessionCookies
            }

            try persistCookiesToKeychain()
        } catch {
            if let err = error as? AuthError { throw err }
            throw AuthError.network(underlying: error)
        }
    }

    /// Déconnexion : tente l'endpoint, puis purge les cookies en mémoire + Keychain
    func logout() async {
        // On essaie d'appeler l'endpoint logout (sans échouer si le réseau ne répond pas)
        var request = URLRequest(url: URL(string: cfg.baseURL + cfg.logoutPath)!)
        request.httpMethod = "POST"

        do { _ = try await session.data(for: request) } catch { /* ignore */ }

        clearAllCookies()
        deleteCookiesFromKeychain()
    }

    // MARK: - Cookies

    /// Considère qu’on est loggé si on détient au moins un cookie "session" non expiré
    private func hasValidSessionCookies() -> Bool {
        let now = Date()
        let jar = cookieStorage.cookies(for: URL(string: cfg.baseURL)!) ?? cookieStorage.cookies ?? []
        return jar.contains { cookie in
            cfg.sessionCookieNames.contains(cookie.name)
            && (cookie.expiresDate.map { $0 > now } ?? true) // certains cookies de session n'ont pas d'expiration explicite
        }
    }

    private func persistCookiesToKeychain() throws {
        // On ne stocke que les cookies liés au domaine/baseURL
        let jar = (cookieStorage.cookies(for: URL(string: cfg.baseURL)!) ?? cookieStorage.cookies ?? [])
            .filter { cfg.sessionCookieNames.contains($0.name) }
        guard !jar.isEmpty else { throw AuthError.noSessionCookies }

        // HTTPCookie est NSSecureCoding -> sérialisation via NSKeyedArchiver
        let data = try NSKeyedArchiver.archivedData(withRootObject: jar, requiringSecureCoding: true)
        let status = Keychain.saveOrUpdate(key: cfg.keychainKey, data: data)
        guard status == errSecSuccess else { throw AuthError.keychainError(status: status) }
    }

    private func restoreCookiesFromKeychain() {
        guard let data = Keychain.load(key: cfg.keychainKey) else { return }
        do {
            if let cookies = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie] {
                // Replace existing cookies with restored ones (for same names/domains)
                for cookie in cookies {
                    cookieStorage.setCookie(cookie)
                }
            }
        } catch {
            // Si la désérialisation échoue, on nettoie l’entrée Keychain
            deleteCookiesFromKeychain()
        }
    }

    private func clearAllCookies() {
        let all = cookieStorage.cookies ?? []
        for cookie in all {
            cookieStorage.deleteCookie(cookie)
        }
    }

    private func deleteCookiesFromKeychain() {
        _ = Keychain.delete(key: cfg.keychainKey)
    }
}

// MARK: - Simple Keychain helper (Data)

enum Keychain {
    /// Ajoute ou met à jour une entrée (kSecClassGenericPassword) pour la clé donnée.
    @discardableResult
    static func saveOrUpdate(key: String, data: Data) -> OSStatus {
        let account = key
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,       // service namespace
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let attrsToUpdate: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
            return status
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
            return status
        default:
            return status
        }
    }

    static func load(key: String) -> Data? {
        let account = key
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return data
    }

    @discardableResult
    static func delete(key: String) -> OSStatus {
        let account = key
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary)
    }
}
