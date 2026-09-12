//
//  EditionRelevanceTests.swift
//  ReCIT_iOSTests
//
//  Which edition a tapped search result opens. No `ModelContainer` and no network: the rule
//  works over values precisely so this suite can drive it with a handful of booleans.
//
//  The two cases worth reading before the others are `heldBreaksTiesInsideItsTier` and
//  `heldDoesNotClimbTiers`. Together they are the arbitration this feature was designed around:
//  a friend's copy decides *which* French edition to open, and never decides to open a Spanish
//  one instead.
//
//  `namelessEditionsAnswerNothing` is the one that guards a ruling rather than a rule: the
//  ladder deliberately stops at "has a title" and answers nothing below it, so that a tap can
//  never redirect onto a book called `Unknown`. Anyone tempted to add a catch-all rung so that
//  a tap "always opens something" will fail here, which is the point.
//
//  See PRD 0014.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("EditionRelevance")
struct EditionRelevanceTests {

    private typealias Candidate = EditionRelevance.Candidate

    private func candidate(
        _ id: String,
        lang: String?,
        title: Bool = true,
        cover: Bool = true,
        held: Bool = false,
        single: Bool = true
    ) -> Candidate {
        .init(id: id, lang: lang, hasTitle: title, hasCover: cover, isHeld: held, isSingleWork: single)
    }

    private func best(
        _ candidates: [Candidate],
        originalLang: String? = "en"
    ) -> Candidate? {
        EditionRelevance.best(among: candidates, preferredLang: "fr", originalLang: originalLang)
    }

    // MARK: - The rungs, in order

    @Test("Rung 1 — French, titled, with a cover wins over everything else")
    func preferredCompleteWins() {
        let winner: Candidate? = best([
            candidate("en-complete", lang: "en"),
            candidate("fr-no-cover", lang: "fr", cover: false),
            candidate("fr-complete", lang: "fr"),
            candidate("fr-untitled", lang: "fr", title: false)
        ])

        #expect(winner?.id == "fr-complete")
    }

    @Test("Rung 2 — a French edition without a cover beats a complete English one")
    func preferredTitledBeatsAnotherLanguage() {
        let winner: Candidate? = best([
            candidate("en-complete", lang: "en"),
            candidate("fr-no-cover", lang: "fr", cover: false)
        ])

        #expect(winner?.id == "fr-no-cover")
    }

    @Test("Rung 3 — no French edition, so the work's own language answers")
    func originalCompleteAnswersWhenNothingIsTranslated() {
        let winner: Candidate? = best([
            candidate("de-complete", lang: "de"),
            candidate("en-complete", lang: "en"),
            candidate("ja-complete", lang: "ja")
        ])

        #expect(winner?.id == "en-complete")
    }

    @Test("Rung 4 — no French, no original language either: anything with a title, and it is the last rung")
    func titledAnswersWhenTheOriginalIsAbsent() {
        let winner: Candidate? = best([
            candidate("de-untitled", lang: "de", title: false),
            candidate("ja-complete", lang: "ja")
        ])

        #expect(winner?.id == "ja-complete")
    }

    @Test("There is no rung below a title — a nameless edition is never a redirect target")
    func namelessEditionsAnswerNothing() {
        // Every candidate would render as `Unknown`. Opening one is worse than saying there is
        // nothing to open, which is the owner's ruling of 2026-09-11.
        let winner: Candidate? = best([
            candidate("first-untitled", lang: "fr", title: false),
            candidate("second-untitled", lang: nil, title: false)
        ])

        #expect(winner == nil)
    }

    @Test("One titled edition among nameless ones is the one that answers")
    func theOnlyNamedEditionWins() {
        let winner: Candidate? = best([
            candidate("fr-untitled", lang: "fr", title: false, held: true),
            candidate("ja-titled", lang: "ja", cover: false)
        ])

        #expect(winner?.id == "ja-titled")
    }

    // MARK: - One book, or a box of several

    @Test("A boxed set loses to a single book of the same rung")
    func omnibusLosesToASingleBook() {
        // The report that produced this rule: searching « Harry Potter et la Chambre des
        // Secrets » opened *Harry Potter, coffret 4 volumes*, which is French, named, covered —
        // and first out of `reverse-claims`.
        let winner: Candidate? = best([
            candidate("coffret", lang: "fr", single: false),
            candidate("chambre-des-secrets", lang: "fr")
        ])

        #expect(winner?.id == "chambre-des-secrets")
    }

    @Test("A box beats no book at all when the rung holds nothing else")
    func omnibusAnswersWhenItIsAllThereIs() {
        let winner: Candidate? = best([
            candidate("coffret-4", lang: "fr", single: false),
            candidate("coffret-7", lang: "fr", single: false)
        ])

        #expect(winner?.id == "coffret-4")
    }

    @Test("A box is preferred over nothing rather than dropping a rung")
    func omnibusIsNarrowedNotExcluded() {
        // The only French candidate is a box; the only single book is English. Narrowing must
        // not push the answer down a rung — a box of the right language still wins.
        let winner: Candidate? = best([
            candidate("fr-coffret", lang: "fr", single: false),
            candidate("en-single", lang: "en")
        ])

        #expect(winner?.id == "fr-coffret")
    }

    @Test("Single-work is settled before ownership, not after")
    func singleWorkOutranksBeingHeld() {
        // A copy of my own is already listed in the search screen's local section; the remote
        // result does not need to hand me the same box a second time.
        let winner: Candidate? = best([
            candidate("held-coffret", lang: "fr", held: true, single: false),
            candidate("plain-single", lang: "fr")
        ])

        #expect(winner?.id == "plain-single")
    }

    // MARK: - What being held may and may not do

    @Test("A held copy breaks the tie among the single books of the tier that won")
    func heldBreaksTiesInsideItsTier() {
        let winner: Candidate? = best([
            candidate("fr-first", lang: "fr"),
            candidate("fr-second", lang: "fr"),
            candidate("fr-held", lang: "fr", held: true)
        ])

        #expect(winner?.id == "fr-held")
    }

    @Test("A held copy never climbs a tier — a friend's Spanish copy loses to French editions")
    func heldDoesNotClimbTiers() {
        let winner: Candidate? = best([
            candidate("es-held", lang: "es", held: true),
            candidate("fr-plain", lang: "fr")
        ])

        #expect(winner?.id == "fr-plain")
    }

    @Test("A held copy that is untitled loses to a titled one in the same language")
    func heldDoesNotRescueAnUntitledEdition() {
        let winner: Candidate? = best([
            candidate("fr-held-untitled", lang: "fr", title: false, held: true),
            candidate("fr-titled", lang: "fr", cover: false)
        ])

        #expect(winner?.id == "fr-titled")
    }

    // MARK: - Edges

    @Test("A work with no edition at all answers nothing")
    func emptyAnswersNil() {
        #expect(best([]) == nil)
    }

    @Test("A nil original language does not match candidates whose language is unknown")
    func nilOriginalLangMatchesNothingOnItsRung() {
        // `unknown-complete` would satisfy rung 3 if `nil == nil` were allowed to match. It must
        // fall to rung 4 instead, where `de-titled` — declared first — answers.
        let winner: Candidate? = best(
            [
                candidate("de-titled", lang: "de", cover: false),
                candidate("unknown-complete", lang: nil)
            ],
            originalLang: nil
        )

        #expect(winner?.id == "de-titled")
    }

    @Test("Same input, same answer, twice")
    func isDeterministic() {
        let candidates: [Candidate] = [
            candidate("fr-a", lang: "fr"),
            candidate("fr-b", lang: "fr"),
            candidate("en-c", lang: "en")
        ]

        #expect(best(candidates)?.id == best(candidates)?.id)
        #expect(best(candidates)?.id == "fr-a")
    }

    @Test("The preferred language is a parameter, not a constant")
    func preferredLangIsHonoured() {
        let candidates: [Candidate] = [
            candidate("fr-complete", lang: "fr"),
            candidate("en-complete", lang: "en")
        ]

        let winner: Candidate? = EditionRelevance.best(
            among: candidates,
            preferredLang: "en",
            originalLang: "fr"
        )

        #expect(winner?.id == "en-complete")
    }
}
