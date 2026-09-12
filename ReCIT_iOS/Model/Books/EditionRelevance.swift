//
//  EditionRelevance.swift
//  ReCIT_iOS
//
//  Which edition of a work the app opens when a search result is tapped.
//
//  `/api/search` cannot return editions — the server's own error message lists the types it
//  accepts and editions are not among them — so a search for a book returns works, and someone
//  has to pick the edition. This type is the app doing it instead of asking the user which of
//  the 66 editions of Dune they meant (ADR 0002, Move 3).
//
//  It works over `Candidate` — an uri and four booleans — rather than over `Edition`, so it can
//  be tested without a `ModelContainer`, without a network, and without persisting the 127
//  editions of 1984 that answering the question requires reading.
//
//  Five decisions are worth stating:
//
//  1. **It is a ladder, not a score.** The first non-empty tier wins outright. A weighted score
//     would have been easy to tune and impossible to explain, and its weights would have become
//     numbers nobody dared touch.
//  2. **Having a title means having one *on screen*.** The question goes through
//     `EditionTitle`, the same resolution `Edition` uses to name itself — not the `wdt:P1476`
//     claim, which this type read at first. The two disagree for 13 % of editions (66 of 513
//     sampled), and every one of those was ranked as titled and then drawn as `Unknown`. A rule
//     about what the user sees has to be asked of the thing the user sees.
//
//     It is also not a resemblance. "The edition title matches the work label" was the obvious
//     rule and it is the wrong one: it rejects `Dune, Tome 1` — Robert Laffont, 2021, with an
//     ISBN — and every translation whose title legitimately differs. Having a name is the
//     reliable signal; being named the same thing is not.
//  3. **A box of several books loses to a single one, and that is decided before ownership.**
//     Searching « Harry Potter et la Chambre des Secrets » opened *Harry Potter, coffret 4
//     volumes*: the boxed set is French, named and covered, so it matched the top rung, and it
//     happened to come first out of `reverse-claims`. Handing someone four books when they asked
//     for the second one answers a different question. `wdt:P629` says how many works an edition
//     is of, which makes this cheap to know — and it is checked *before* `isHeld` because a copy
//     of my own is already listed above, in the search screen's own local section: the remote
//     result does not need to surface it a second time, and certainly not as a box.
//
//     It narrows rather than excludes. When every candidate of the winning rung is an omnibus,
//     an omnibus still answers: a box of the right book beats no book at all.
//  4. **Being held only breaks ties inside the tier that won.** A friend's Spanish copy does not
//     beat twenty French editions. It is a strong signal about *which* French edition to open,
//     and no signal at all about which language to open.
//  5. **There is no rung below "has a title".** An earlier draft ended with a catch-all so that
//     a tap always opened *something*, which meant a tap could open a book called `Unknown`.
//     The owner ruled that out on 2026-09-11: better to say there is nothing to show than to
//     redirect someone onto a nameless record. Reaching the end of the ladder is now an answer,
//     and the screen has a block for it.
//
//  See PRD 0014.
//

import Foundation

enum EditionRelevance {
    /// An edition reduced to what choosing needs. Built from the DTOs a resolution reads, never
    /// from persisted `Edition` objects: the ranking runs before anything is written.
    struct Candidate: Equatable, Identifiable, Sendable {
        /// The edition's uri — `inv:…` or `wd:…`.
        let id: String
        /// ISO code of the edition's own language, from `originalLang` (which mirrors
        /// `wdt:P407`). `nil` when the entity does not say.
        let lang: String?
        /// Whether a `wdt:P1476` title claim exists. Not whether it resembles anything.
        let hasTitle: Bool
        /// Whether the entity carries a cover (`invp:P2` / `image`).
        let hasCover: Bool
        /// Whether a copy of this edition is already on this device — mine or a friend's.
        let isHeld: Bool
        /// Whether this edition is one book rather than a box of several — `wdt:P629` naming a
        /// single work. The ordinary case, hence the default.
        let isSingleWork: Bool

        init(
            id: String,
            lang: String?,
            hasTitle: Bool,
            hasCover: Bool,
            isHeld: Bool = false,
            isSingleWork: Bool = true
        ) {
            self.id = id
            self.lang = lang
            self.hasTitle = hasTitle
            self.hasCover = hasCover
            self.isHeld = isHeld
            self.isSingleWork = isSingleWork
        }
    }

    /// The rungs, in order. The first one with a candidate answers, and the ones below it are
    /// never consulted — which is the whole point: a lower rung must not be able to outrank a
    /// higher one, however many good properties its candidates have.
    enum Tier: CaseIterable, Sendable {
        /// My language, with a title, with a cover. What almost every search lands on.
        case preferredComplete
        /// My language, with a title. The cover is missing and the book is still the right book.
        case preferredTitled
        /// The work's own language, with a title and a cover — for a work never translated.
        case originalComplete
        /// Anything with a title, in any language. The last rung, and deliberately so: past
        /// here every candidate is nameless, and a rung below this one would be a redirect to a
        /// book called `Unknown`.
        case titled

        func matches(
            _ candidate: Candidate,
            preferredLang: String,
            originalLang: String?
        ) -> Bool {
            switch self {
            case .preferredComplete:
                candidate.lang == preferredLang && candidate.hasTitle && candidate.hasCover
            case .preferredTitled:
                candidate.lang == preferredLang && candidate.hasTitle
            case .originalComplete:
                // Guarded rather than compared: a `nil` original language must not match the
                // candidates whose own language is also unknown.
                originalLang != nil && candidate.lang == originalLang
                    && candidate.hasTitle && candidate.hasCover
            case .titled:
                candidate.hasTitle
            }
        }
    }

    /// The edition to open for this work, or `nil` when there is none worth opening — the work
    /// has no edition at all, or none of them has a name. Both are states the caller renders
    /// rather than failures to swallow.
    ///
    /// Deterministic: once the two tie-breaks have had their say, the first candidate left
    /// answers, in the order the caller supplied.
    static func best(
        among candidates: [Candidate],
        preferredLang: String,
        originalLang: String? = nil
    ) -> Candidate? {
        for tier in Tier.allCases {
            let reached: [Candidate] = candidates.filter {
                tier.matches($0, preferredLang: preferredLang, originalLang: originalLang)
            }
            guard reached.isEmpty == false else { continue }

            // One book before a box of several — unless the box is all there is, in which case
            // a box is still better than nothing.
            let singles: [Candidate] = reached.filter(\.isSingleWork)
            let shortlist: [Candidate] = singles.isEmpty ? reached : singles

            return shortlist.first(where: \.isHeld) ?? shortlist[0]
        }

        return nil
    }
}
