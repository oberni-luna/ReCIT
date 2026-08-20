//
//  SortDraftNameRuleTests.swift
//  ReCIT_iOSTests
//
//  What may become a new étagère on the sorting surface, and what is refused before it
//  ever reaches the change stack.
//
//  The rule exists so that applying can never produce two étagères the user reads as
//  the same — which is a claim about what they *read*, not about what the strings are,
//  hence the accents and the capitals below. Every case here is a sentence a user could
//  have said: "I already have a Romans shelf, so it should not let me make another
//  one."
//
//  Pure and store-free, over the sections the surface is showing. No form, no session,
//  no server — PRD 0008 keeps those out of scope on purpose.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortDraftNameRule")
struct SortDraftNameRuleTests {

    private var library: SortSnapshot {
        .init(
            shelves: [
                .init(id: "s1", name: "Romans", bookIds: ["1"]),
                .init(id: "s2", name: "Poésie", bookIds: [])
            ],
            books: [.init(id: "1", title: "Livre 1"), .init(id: "2", title: "Livre 2")]
        )
    }

    private func rule(changes: [SortChange] = []) -> SortDraftNameRule {
        .init(sections: SortProjection(snapshot: library, changes: changes).sections)
    }

    /// The spellings a reader takes for one and the same shelf.
    static let sameName: [String] = ["Romans", "romans", "ROMANS", "Rômans", " Romans ", "  rOmAnS  "]

    // MARK: - A name already on the shelf

    /// A name nobody is using is a name the user may have.
    @Test func aNameNothingUsesIsAccepted() {
        #expect(rule().accepts("Science-fiction"))
        #expect(rule().refusal(for: "Science-fiction") == nil)
    }

    /// However it is typed, a name the user already has is refused — and the refusal
    /// names their étagère in its own spelling, because « Romans » is what they will be
    /// looking for on the screen behind the form.
    @Test(arguments: SortDraftNameRuleTests.sameName)
    func aNameMatchingAnEtagereTheUserAlreadyHasIsRefused(typed: String) {
        #expect(rule().accepts(typed) == false)
        #expect(rule().refusal(for: typed) == .alreadyUsed(name: "Romans"))
    }

    /// Accents are not a second étagère either way round: an accented name collides with
    /// the unaccented étagère just as the unaccented name collides with the accented one.
    @Test(arguments: ["Poésie", "poesie", "POESIE", "Poesie "])
    func anAccentIsNotASecondEtagere(typed: String) {
        #expect(rule().refusal(for: typed) == .alreadyUsed(name: "Poésie"))
    }

    // MARK: - A name already on the stack

    /// The asymmetry that matters: a draft made a moment ago is refused exactly as an
    /// étagère the server holds. Applying would create both, and the user would be left
    /// with two shelves they cannot tell apart.
    @Test(arguments: ["Science-fiction", "science-fiction", "SCIENCE-FICTION", " Science-Fiction "])
    func aNameMatchingAnotherDraftIsRefused(typed: String) {
        let draftId: String = SortDraftID.make()
        let taken: SortDraftNameRule = rule(
            changes: [.createShelf(draftId: draftId, name: "Science-fiction")]
        )

        #expect(taken.accepts(typed) == false)
        #expect(taken.refusal(for: typed) == .alreadyUsed(name: "Science-fiction"))
    }

    /// A draft holding no books is still a section on screen, so it is still a name that
    /// is taken. It will not be created when the stack is applied — but until then the
    /// user can see it, and two sections reading the same is the thing being prevented.
    @Test func anEmptyDraftStillTakesItsName() {
        let draftId: String = SortDraftID.make()
        let taken: SortDraftNameRule = rule(
            changes: [.createShelf(draftId: draftId, name: "Essais")]
        )

        #expect(taken.accepts("essais") == false)
    }

    /// Both sides at once, from one rule: the étagères the server holds and the drafts
    /// on the stack are one list of taken names, not two lists that could disagree.
    @Test func existingEtageresAndDraftsAreRefusedByTheSameRule() {
        let taken: SortDraftNameRule = rule(
            changes: [.createShelf(draftId: SortDraftID.make(), name: "Essais")]
        )

        #expect(taken.accepts("romans") == false)
        #expect(taken.accepts("essais") == false)
        #expect(taken.accepts("Bandes dessinées"))
    }

    // MARK: - Nothing typed, and the pile

    @Test(arguments: ["", " ", "\n", "   \t "])
    func aBlankNameIsNotAName(typed: String) {
        #expect(rule().accepts(typed) == false)
        #expect(rule().refusal(for: typed) == .blank)
    }

    /// « À ranger » is not an étagère and has no name of its own, so nothing stops a
    /// user from calling a shelf that. The rule refuses shelves that collide with
    /// shelves, and the pile is not one.
    @Test func thePileIsNotANameAnythingCollidesWith() {
        #expect(rule().accepts("À ranger"))
    }
}
