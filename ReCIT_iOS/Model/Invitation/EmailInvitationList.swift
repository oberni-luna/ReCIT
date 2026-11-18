//
//  EmailInvitationList.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// The addresses of « Inviter par e-mail », read from its « Adresses e-mail » field the way
/// inventaire.io reads them: split on commas, semicolons, spaces and line breaks, lowercased,
/// each once, and without my own address.
///
/// An address is plausible when it has one `@`, something before it, and a domain of at least two
/// non-empty labels. The rule is loose on purpose: it catches a half-typed address, and the
/// server, which parses the list again, stays the judge of the rest.
nonisolated struct EmailInvitationList: Equatable, Sendable {
    /// The most addresses inventaire.io takes in one call; past it, it answers `400`.
    static let maximumCount: Int = 50

    /// The plausible addresses, lowercased, each once, in the order they were typed.
    let addresses: [String]
    /// What was typed and is not an address, as typed, each once, in order.
    let malformedAddresses: [String]

    /// Whether « Envoyer l'invitation » can send: at least one address, none malformed, and no
    /// more than `maximumCount`.
    var canSend: Bool {
        addresses.isEmpty == false
            && malformedAddresses.isEmpty
            && addresses.count <= Self.maximumCount
    }

    /// Reads the field.
    /// - Parameters:
    ///   - text: The field's text, as typed.
    ///   - ownAddress: My account's address, left out whatever its case; `nil` when unknown.
    init(
        _ text: String,
        excluding ownAddress: String?
    ) {
        let tokens: [String] = text
            .split { $0 == "," || $0 == ";" || $0.isWhitespace }
            .map(String.init)
        let ownAddress: String? = ownAddress?.lowercased()

        addresses = Self.uniqued(
            tokens
                .filter(Self.isPlausible)
                .map { $0.lowercased() }
                .filter { $0 != ownAddress }
        )
        malformedAddresses = Self.uniqued(tokens.filter { Self.isPlausible($0) == false })
    }

    /// What « Adresses e-mail » opens on from a reader search: the search when it holds an `@`,
    /// trimmed, and nothing otherwise.
    /// - Parameter query: The search field's text.
    /// - Returns: The field's first text.
    static func initialText(fromSearch query: String) -> String {
        let trimmedQuery: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedQuery.contains("@") ? trimmedQuery : ""
    }

    private static func isPlausible(_ address: String) -> Bool {
        let parts: [Substring] = address.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, let localPart = parts.first, let domain = parts.last else { return false }

        let labels: [Substring] = domain.split(separator: ".", omittingEmptySubsequences: false)
        return localPart.isEmpty == false
            && labels.count > 1
            && labels.allSatisfy { $0.isEmpty == false }
    }

    private static func uniqued(_ addresses: [String]) -> [String] {
        var seen: Set<String> = []
        return addresses.filter { seen.insert($0).inserted }
    }
}
