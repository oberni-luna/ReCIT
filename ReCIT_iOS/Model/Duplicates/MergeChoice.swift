//
//  MergeChoice.swift
//  ReCIT_iOS
//
//  Which edition of a pair is kept, and which may be.
//
//  inventaire.io merges only *from* an `inv:` edition: a Wikidata edition can be the one kept,
//  never the one that disappears. So when one of the two is Wikidata it is kept, and the other
//  cannot be chosen instead. Otherwise the app proposes the more complete one — one point per
//  datum it carries, then the more copies, then the uri so that the proposal never moves — and
//  the reader may choose the other.
//
//  See PRD 0028.
//

import Foundation

enum MergeChoice {

    /// The edition the app proposes to keep.
    static func proposedKeep(
        in pair: EditionDuplicatePair,
        copyCounts: [String: Int] = [:]
    ) -> EditionFacts {
        let (first, second): (EditionFacts, EditionFacts) = (pair.first, pair.second)
        if canKeep(first, in: pair) != canKeep(second, in: pair) {
            return canKeep(first, in: pair) ? first : second
        }
        if first.completeness != second.completeness {
            return first.completeness > second.completeness ? first : second
        }
        let firstCopies: Int = copyCounts[first.uri] ?? 0
        let secondCopies: Int = copyCounts[second.uri] ?? 0
        if firstCopies != secondCopies {
            return firstCopies > secondCopies ? first : second
        }
        return first.uri < second.uri ? first : second
    }

    /// Whether `edition` may be the one kept: the other one must be able to disappear.
    static func canKeep(_ edition: EditionFacts, in pair: EditionDuplicatePair) -> Bool {
        pair.other(than: edition.uri).mergeUri != nil
    }

    /// `{ from, to }` for keeping `kept` — `nil` when `kept` cannot be kept.
    static func request(keeping kept: EditionFacts, in pair: EditionDuplicatePair) -> EditionMergeRequest? {
        guard let from = pair.other(than: kept.uri).mergeUri else { return nil }
        return .init(from: from, to: kept.mergeUri ?? kept.uri)
    }
}
