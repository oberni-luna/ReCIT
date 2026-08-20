//
//  OnboardingGate.swift
//  ReCIT_iOS
//
//  When onboarding is allowed on screen. Pure: no SwiftUI, no SwiftData, no `UserDefaults`,
//  on the pattern of `BatchScanStateMachine` and the `Model/AutoSort/` types. The conditions
//  *are* the feature, so they live in one testable place and every consumer reads the answer
//  instead of re-deriving it — a view that re-derives one of them is how the accueil and the
//  empty shelf's note come to disagree about whether the inventory is empty.
//
//  A namespace of decisions rather than a value built from one snapshot of state, and
//  deliberately so: the two decisions do not share a single input. The bilan's needs what a
//  scanning session just added and how many étagères the user owns, neither of which the
//  accueil's has any use for, and it waits on no sync — so it sits beside the accueil's as a
//  second static method rather than inside a struct that would have to be rebuilt at every call
//  site to carry both.
//
//  See PRD 0007.
//

/// The rules that decide which onboarding screen, if any, the app owes the user.
enum OnboardingGate {

    /// Whether the first-launch accueil should be presented.
    ///
    /// `inventoryHasSynced` is load-bearing and cannot be inferred from the count: an empty
    /// inventory means either "this user owns nothing" or "we have not fetched it yet", and
    /// only the second one must not raise the accueil. Without the clause an existing user
    /// reinstalling the app is offered a first-launch scan over three hundred books that
    /// simply have not arrived — and answering that offer suppresses the accueil for good.
    ///
    /// - Parameters:
    ///   - inventoryHasSynced: whether this user's inventory has ever completed a sync.
    ///   - ownedBookCount: how many books the user owns.
    ///   - welcomeAnswered: whether this user has already answered the accueil, either way.
    ///     The call to action and the escape hatch both count: the accueil is a question asked
    ///     once.
    static func presentsWelcome(
        inventoryHasSynced: Bool,
        ownedBookCount: Int,
        welcomeAnswered: Bool
    ) -> Bool {
        guard inventoryHasSynced else { return false }
        guard ownedBookCount == 0 else { return false }

        return !welcomeAnswered
    }

    /// Whether the bilan should be presented at the end of a scanning session.
    ///
    /// It waits on no sync, unlike the accueil: both of its inputs are facts about a session
    /// that has just run in front of the user, and the étagère count is only ever read once
    /// that session is over.
    ///
    /// Nothing here is persisted. "Has already arranged their books" is *derived* from owning
    /// an étagère, which is exactly the state the whole sequence exists to produce — so a user
    /// who created one by hand also stops being offered the arrangement. Accepted: they have
    /// shown they know what an étagère is, and a persisted flag would instead have to be kept
    /// in step with a fact the store already holds.
    ///
    /// - Parameters:
    ///   - sessionAddedBookCount: how many books the session that is ending filed. Carried out
    ///     of the scanner because no query can derive it: three books added among three hundred
    ///     are invisible in any snapshot of the store.
    ///   - ownedShelfCount: how many étagères the user owns.
    static func presentsScanTally(
        sessionAddedBookCount: Int,
        ownedShelfCount: Int
    ) -> Bool {
        guard sessionAddedBookCount > 0 else { return false }

        return ownedShelfCount == 0
    }
}
