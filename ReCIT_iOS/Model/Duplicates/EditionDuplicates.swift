//
//  EditionDuplicates.swift
//  ReCIT_iOS
//
//  What the detection found among a work's editions: the pairs to decide on, and the tag each
//  edition carries. PRD 0028.
//

import Foundation

struct EditionDuplicates: Equatable, Sendable {
    let pairs: [EditionDuplicatePair]
    let tags: [String: EditionDuplicateTag]

    static let none: EditionDuplicates = .init(pairs: [], tags: [:])

    /// The pairs seen, in one string: what closing the banner remembers, so that it comes back
    /// when the pairs change and only then.
    var signature: String {
        pairs.map(\.id).sorted().joined(separator: ",")
    }

    func count(of reason: EditionDuplicateReason) -> Int {
        pairs.filter { $0.reason == reason }.count
    }
}
