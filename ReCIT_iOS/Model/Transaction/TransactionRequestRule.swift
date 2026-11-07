//
//  TransactionRequestRule.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import Foundation

/// Whether a friend's copy may be asked for: not when I own a copy of the same edition, the Fiche
/// livre's rule, applied copy by copy.
nonisolated struct TransactionRequestRule: Equatable, Sendable {
    private let myEditionURIs: Set<String>

    /// - Parameters:
    ///   - copies: every copy of the work, its owner and the uri of its edition.
    ///   - myUserId: who I am, `nil` when unknown.
    init(
        copies: [(ownerId: String, editionURI: String)],
        myUserId: String?
    ) {
        myEditionURIs = Set(copies.filter { $0.ownerId == myUserId }.map(\.editionURI))
    }

    /// - Parameter editionURI: the edition of the friend's copy.
    /// - Returns: whether the long press offers to ask for it.
    func isRequestOffered(forEditionURI editionURI: String) -> Bool {
        myEditionURIs.contains(editionURI) == false
    }
}
