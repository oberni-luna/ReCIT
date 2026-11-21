---
issue: 170
status: to-test
wiki: [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0066-a-friends-profile-tabs-as-pages]], [[features/0089-tabbed-shelf-screen]]
note: Sur une liste, il arrive que quand je swipe vers la droite pour accéder à la description de la liste, l'écran revient tout à la première page. Bug antérieur à #168.
created: 2026-11-21
---

## Context / Decisions

> Sur une liste, il arrive que quand je swipe vers la droite pour accéder à la description de la liste, l'écran revient tout à la première page.

- Seen on a Liste, now and then: a swipe from « Livres » to « Présentation » lands, then the pager turns back to « Livres ». It was there before #168.
- Likely cause, read in the code, not reproduced:
  - As soon as the finger lets go, `UIPageViewController` puts the page it lands on in `viewControllers`. `TabPager.Coordinator` only writes the selection in `didFinishAnimating`, once the page has settled.
  - A SwiftUI update in between calls `updateUIViewController`, then `turn(_:to: selection)`. It sees the page on screen (« Présentation ») differ from the selection (still « Livres »), takes it for a tab chosen by its name, and turns back: at once, or through `pendingTab` if the scroll is still decelerating.
  - On a Liste, that update is frequent: `ListCoverFlowView` binds its scroll to the screen's `selectedURI` (`scrollPosition(id: $selectedURI)`). A swipe that starts on the covers nudges them, and they write `selectedURI` as they settle.
- Fix in `TabPager`, so the Liste, the Étagère and a friend's profile all get it: the pager turns only when the selection has changed since the last value it saw or wrote, never because the selection differs from the page on screen.
  - The coordinator keeps that last value. It is set when the pager is made, when its pages are rebuilt, and when a swipe writes the selection.
- Tabs chosen by their name still turn the pager, including during a swipe's settle (`pendingTab`).
- `ListCoverFlowView` and its scroll binding stay as they are.
- No unit test: the decision lives in a UIKit coordinator; checked by hand.

## Acceptance criteria

- On a Liste, swipe from « Livres » to « Présentation » starting on the covers, ten times → each swipe stays on « Présentation ».
- Same, swiping back to « Livres » → stays on « Livres ».
- Touching a tab's name on a Liste, an Étagère and a friend's profile → the pager turns to that page, as before.
- Touching a tab's name while a swipe is still settling → the pager ends on the touched tab.
- Swiping between pages on an Étagère and a friend's profile → unchanged, no turn back.

## Implementation

- `TabPager.swift` only. `Coordinator.lastSelection` holds the selection as the pager last saw or wrote it, set in `init`.
- `follow(_:in:)`, called by `updateUIViewController` in place of `turn`: turns only when the selection differs from `lastSelection`, then records it.
- `didFinishAnimating` records the page it settled on as `lastSelection`, so the update it causes does not turn the pager again.
- `turn` queues `pendingTab` while the pages move: under a finger, decelerating, or turning to a tab chosen by name. The `setViewControllers` completion turns to it. Before, a tab chosen during a turn by name was dropped and caught by a later update, which `follow` no longer makes.
- Known limit: touching the tab being left while a swipe away from it is still settling leaves the pager on the new page. The selection has not changed, so the pager cannot tell the touch from a stray update.
- `.swiftlint.baseline` keeps a stale `multiline_condition_break` entry for the old `guard isTurningByName == false,` line (#17).
- Build: `** BUILD SUCCEEDED **`, scheme `ReCIT_iOS`, iPhone 17 simulator, SwiftLint in the build. No unit test.

## Review

## Verification

manual validation — not run by agent

## Feedback
