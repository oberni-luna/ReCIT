//
//  MergeFailure.swift
//  ReCIT_iOS
//
//  Why inventaire.io refused a merge, one case per message its `400` carries (read on Codeberg,
//  `server/controllers/entities/merge.ts` and `tasks/lib/merge_validation.ts`, 2026-10-27). The
//  server's English is matched, never shown: each case owns the sentence the reader gets.
//
//  Only a `400` is classified. A `401` is a session gone, and goes out as it came (ADR 0008,
//  rule 3); anything else stays the network error it is.
//
//  See PRD 0028.
//

import Foundation

enum MergeFailure: Error, Equatable {
    /// « can't merge editions with different ISBNs »
    case differentIsbns
    /// « entities have conflicting properties » — an ISBN-13 or ISBN-10 on both, not the same.
    case conflictingProperties
    /// « entities are referring to one antoher » (sic) — one cites the other, `wdt:P1889` included.
    case relatedEntities
    /// « 'from' entity is already a redirection » — somebody merged it first.
    case alreadyRedirected
    /// Any other `400`.
    case refused

    /// The failure `error` stands for, or `error` itself when it is not a refusal.
    static func classify(_ error: Error) -> Error {
        guard case NetworkError.badStatus(code: 400, let body) = error else { return error }
        let message: String = body ?? ""
        if message.contains("different ISBNs") {
            return MergeFailure.differentIsbns
        }
        if message.contains("conflicting properties") {
            return MergeFailure.conflictingProperties
        }
        if message.contains("referring to one an") {
            return MergeFailure.relatedEntities
        }
        if message.contains("already a redirection") {
            return MergeFailure.alreadyRedirected
        }
        return MergeFailure.refused
    }
}

extension MergeFailure: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .differentIsbns:
            String(localized: "duplicates.merge.error.different_isbns")
        case .conflictingProperties:
            String(localized: "duplicates.merge.error.conflicting_properties")
        case .relatedEntities:
            String(localized: "duplicates.merge.error.related")
        case .alreadyRedirected:
            String(localized: "duplicates.merge.error.already_merged")
        case .refused:
            String(localized: "duplicates.merge.error.refused")
        }
    }
}
