//
//  FriendsCarouselState.swift
//  ReCIT_iOS
//
//  What « Chez mes amis » draws in the Recherche tab: nothing, an invitation to find readers, or
//  my friends' latest books. Pure — the screen hands it the phase and two facts it already has
//  from its `@Query`s, and draws what comes back — so the rule is driven by values in a test.
//
//  Three decisions live here:
//
//  1. **Rest only.** The carousel is discovery, not an answer: from the first character typed,
//     my friends' copies answer in the local section, next to mine (issue 0115).
//  2. **No friend is an invitation, friends without books are silence.** The first is a reader
//     who has not found the network yet, and a paper tag toward Réseau tells them where it is;
//     the second is a network that has nothing to show yet, and an empty band would only say so.
//  3. **Ten at most, and « Tout voir » past ten** — never at exactly ten, so the action always
//     leads to something the row did not show.
//
//  See PRD 0020 and issue 0117.
//

import Foundation

enum FriendsCarouselState: Equatable, Sendable {
    /// How many of my friends' books the carousel shows.
    static let limit: Int = 10

    /// Nothing to draw: a query is being typed, or my friends have no book yet.
    case hidden
    /// I have no friend: a tag toward the Réseau tab stands where the carousel would.
    case invitation
    /// My friends' most recent books, `shownCount` of them, and whether « Tout voir » leads to
    /// more.
    case recent(shownCount: Int, showsSeeAll: Bool)

    static func current(
        phase: SearchPhase,
        hasFriends: Bool,
        friendsBookCount: Int
    ) -> FriendsCarouselState {
        guard case .recents = phase else { return .hidden }
        guard hasFriends else { return .invitation }
        guard friendsBookCount > 0 else { return .hidden }

        return .recent(
            shownCount: min(limit, friendsBookCount),
            showsSeeAll: friendsBookCount > limit
        )
    }
}
