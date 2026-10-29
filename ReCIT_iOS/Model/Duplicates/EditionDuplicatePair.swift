//
//  EditionDuplicatePair.swift
//  ReCIT_iOS
//
//  Two editions to decide on, and why. Its order means nothing — which one is kept is
//  `MergeChoice`'s call, and the reader's. PRD 0028.
//

import Foundation

nonisolated struct EditionDuplicatePair: Equatable, Hashable, Identifiable, Sendable {
    let first: EditionFacts
    let second: EditionFacts
    let reason: EditionDuplicateReason

    /// The two uris in a fixed order, whichever way round the pair was built.
    var id: String {
        [first.uri, second.uri].sorted().joined(separator: "|")
    }

    func contains(_ uri: String) -> Bool {
        first.uri == uri || second.uri == uri
    }

    func other(than uri: String) -> EditionFacts {
        first.uri == uri ? second : first
    }
}
