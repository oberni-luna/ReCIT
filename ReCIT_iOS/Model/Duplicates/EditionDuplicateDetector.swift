//
//  EditionDuplicateDetector.swift
//  ReCIT_iOS
//
//  Compares the editions of one work and says which look like the same book. Pure: plain
//  values in, plain values out.
//
//  Two editions are linked when
//  1. their ISBNs are the same once normalized — « Même ISBN » —, or
//  2. one at least has no ISBN, and they name the same publisher and the same year —
//     « Doublon probable ».
//  Two different ISBNs never make a duplicate: inventaire.io refuses that merge.
//
//  A link is proposed only when somebody can act on it: one of the two must be an `inv:`
//  edition (a merge only goes *from* one), the two must not have been declared different
//  (`wdt:P1889`, either way), and no merge task may already be waiting on them — those are
//  tagged « Doublon signalé » instead.
//
//  Linked editions form groups; a group of n editions gives n − 1 pairs, each of two editions
//  linked directly, chosen « Même ISBN » first and the most complete first. Three editions with
//  one ISBN are two merges, not three; and an edition linked to two others with different ISBNs
//  never pairs those two.
//
//  See PRD 0028.
//

import Foundation

enum EditionDuplicateDetector {

    static func detect(_ editions: [EditionFacts]) -> EditionDuplicates {
        let editions: [EditionFacts] = editions.sorted { $0.uri < $1.uri }
        var tags: [String: EditionDuplicateTag] = [:]
        var candidates: [EditionDuplicatePair] = []

        for (index, first) in editions.enumerated() {
            for second in editions[(index + 1)...] {
                if isReported(first, second) {
                    tags[first.uri] = .reported
                    tags[second.uri] = .reported
                    continue
                }
                guard let reason = reason(first, second), isProposable(first, second) else { continue }
                candidates.append(.init(first: first, second: second, reason: reason))
            }
        }

        // Kruskal over the links, best first: each pair kept joins two groups not joined yet.
        candidates.sort { lhs, rhs in
            if lhs.reason != rhs.reason {
                return lhs.reason == .sameIsbn
            }
            let lhsWeight: Int = lhs.first.completeness + lhs.second.completeness
            let rhsWeight: Int = rhs.first.completeness + rhs.second.completeness
            return lhsWeight != rhsWeight ? lhsWeight > rhsWeight : lhs.id < rhs.id
        }
        var groups: [String: String] = .init(uniqueKeysWithValues: editions.map { ($0.uri, $0.uri) })
        func root(_ uri: String) -> String {
            var uri: String = uri
            while let parent = groups[uri], parent != uri {
                uri = parent
            }
            return uri
        }

        var pairs: [EditionDuplicatePair] = []
        for candidate in candidates {
            let (left, right): (String, String) = (root(candidate.first.uri), root(candidate.second.uri))
            guard left != right else { continue }
            groups[left] = right
            pairs.append(candidate)
        }

        for pair in pairs {
            for edition in [pair.first, pair.second] where tags[edition.uri] != .reported {
                if tags[edition.uri] != .sameIsbn {
                    tags[edition.uri] = .init(pair.reason)
                }
            }
        }

        return .init(pairs: pairs, tags: tags)
    }

    /// Why `first` and `second` look like one book, or `nil` when they do not.
    static func reason(_ first: EditionFacts, _ second: EditionFacts) -> EditionDuplicateReason? {
        switch (first.isbn, second.isbn) {
        case let (left?, right?):
            return left == right ? .sameIsbn : nil
        default:
            guard let publisher = first.publisherUri, publisher == second.publisherUri,
                  let year = first.year, year == second.year
            else { return nil }
            return .probable
        }
    }

    private static func isProposable(_ first: EditionFacts, _ second: EditionFacts) -> Bool {
        guard first.mergeUri != nil || second.mergeUri != nil else { return false }
        let declaredDifferent: Bool = first.differentFrom.isDisjoint(with: second.uris) == false
            || second.differentFrom.isDisjoint(with: first.uris) == false
        return declaredDifferent == false
    }

    private static func isReported(_ first: EditionFacts, _ second: EditionFacts) -> Bool {
        first.reportedMergeTargets.isDisjoint(with: second.uris) == false
            || second.reportedMergeTargets.isDisjoint(with: first.uris) == false
    }
}
