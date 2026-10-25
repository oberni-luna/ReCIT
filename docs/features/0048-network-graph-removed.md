# The Réseau graph removed, Amis | Groupes as before

Shipped on 2026-10-25, ahead of the next iOS release. No PRD and no issues: one slice, decided in an autopilot run
whose decision log is summarised below. Undoes the user-facing half of [0035](0035-network-graph.md).

## What changed

The Réseau tab is **Amis | Groupes** again, exactly as it was on `main` before the graph was merged (`b3bd717`):

- the native segmented `Picker` is the **first row of the list**, on a clear background, so the large title
  « Réseau » collapses with the scroll like every other tab's — not a band fixed under the title;
- the tab opens on **Amis** at every launch; the last segment is no longer remembered;
- the « + » adds a friend on Amis and creates a group on Groupes; the « Tout » menu is gone.

« Tout » was compiled in `DEBUG` only, so a Release build only sees the control move back into the list.

## What left the code

- `Features/Network/Graph/` (51 files), `Model/NetworkGraph/` (25 files), `NetworkSegmentBand`,
  `NetworkSegmentContent`.
- Their tests: `GraphViewportTests`, `MeCentredStackTests`, `NetworkAllContentTests`,
  `NetworkGraphAccessibilityTests`, `NetworkGraphInputStoreTests`, `NetworkGraphLayoutTests`,
  `NetworkGraphRenderingRulesTests`, `NetworkGraphTests`, `NetworkSegmentTests`, `NetworkSheetTextTests`, and the
  fixture `Tests/Support/NetworkGraphFixture.swift`.
- `NetworkSegment.storageKey`, `firstLaunch`, `restored(from:)` and `ground`; the `network.lastSegment` value an
  earlier build stored in `UserDefaults` is left there, unread.
- `View.glassCapsule()` and `View.glassEffectContainer()`, which only the graph's controls used; `DeterministicTilt`
  is no longer `nonisolated`, which only the graph's placement needed.
- The 16 `network.graph.*` strings and `network.segment.all` from `Localizable.xcstrings`.
- The e2e step « Réseau · Tout : un groupe ouvert depuis le graphe », `E2EDriver.Tab.network` and
  `E2EDriver.identifiers(startingWith:)`; the steps after it are renumbered back
  ([0012](0012-end-to-end-scenario.md)).
- Issues 0113 (the graph's device review) and 0114 (the overview's placement), whose object is gone.

## What stays from 0035

Everything 0035 shipped in every build, because other screens rely on it:

- groups kept in the store (`StoredGroup`, `MyGroups`, `GroupModel` on the store) and the Groupes segment reading
  them through `@Query`;
- `UserDataSync` and its order — relations then groups, before the inventory;
- the avatar fallback (`ReaderInitials`, `AvatarThumbnail`, `AvatarFallbackView`, `AvatarKind`, `AvatarMetrics`) and
  `AbsoluteImageURL`;
- `textStyle(_:)` reading its own view's Dynamic Type size (`TextStyleDynamicTypeTests`).

Comments that described those in terms of the graph now speak of it in the past tense.

## Notable decisions

- **The code is deleted, not hidden.** Leaving the graph compiled but unreachable would have kept 8 000 lines and
  ten test suites alive for nothing. The removal is one commit, `691b939`: `git revert 691b939` brings the graph back, its
  tests and its e2e step with it.
- **The control is the pre-graph one, not a new design.** `NetworkView` and `NetworkSegment` are the files as they
  stood at `b3bd717^1`, which already carried the Profil avatar (0038) and the black list ground (0039).
- **The segment is not remembered.** The memory existed so the tab would reopen on « Tout » (0035, Q12).
- **`docs/grill-me/`**, the grilling and Figma extraction of the graph, is kept: it is what a return of the graph
  would start from. The Figma section `Réseau · Graphe` (`512:15486`) is kept too.

## Not verified

- **Not seen on a simulator or a device.** The build and the unit tests pass (980 passed, 1 skipped, 0 failed on
  the iPhone 17 simulator); the tab itself was not opened.
- **The e2e scenario was not run** (on request only); its target builds.
- **Android** never had the graph; nothing changes there.
