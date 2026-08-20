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
//  deliberately so: the bilan's decision (PRD 0007's second screen) needs inputs this one has
//  no use for — what a scanning session just added, how many étagères the user owns — and
//  arrives here as a second static method beside this one. A struct holding today's inputs
//  would have to be rebuilt at every call site to take tomorrow's.
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
}
