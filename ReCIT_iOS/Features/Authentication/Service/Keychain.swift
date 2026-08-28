//
//  Keychain.swift
//  ReCIT_iOS
//
//  A `Data` in, a `Data` out, under a key. The only persistence in the app that outlives an
//  uninstall, which is why the session lives here and nowhere else.
//
//  Split out of `AuthService` when that file was rewritten for PRD 0010: the project keeps one
//  type per file, and the tests need to reach this one on its own to clean up after the unique
//  key each of them writes under.
//

import Foundation
import Security

enum Keychain {

    /// Adds or updates a `kSecClassGenericPassword` entry for the given key.
    @discardableResult
    static func saveOrUpdate(key: String, data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        var status: OSStatus = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let attrsToUpdate: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
            return status
        case errSecItemNotFound:
            var addQuery: [String: Any] = query
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
            return status
        default:
            return status
        }
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return data
    }

    @discardableResult
    static func delete(key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary)
    }
}
