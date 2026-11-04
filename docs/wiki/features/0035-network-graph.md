# The Réseau network as a graph

> **Removed on 2026-10-25 by [feature 0048](0048-network-graph-removed.md).** « Tout », the graph and its e2e step
> left the code; the Réseau tab is Amis | Groupes again, its control the list's first row. What it needed underneath
> — groups in the store, the sync order, the avatar fallback, `textStyle` following a capped Dynamic Type — stays.

Shipped on 2026-10-13, **in `DEBUG` only**: the « Tout » segment is compiled out of Release builds until the device review
([issue 0113](../issues/0113-network-graph-device-review.md)) lifts the `#if DEBUG` for 1.4.0. What it needed underneath —
groups kept in the store, the new sync order, the shared avatar fallback — ships in every build.

Built from PRD 0019 and issues 0103–0112, all deleted with this write-up (git keeps them); the 48 questions of the
2026-10-13 grilling (Q1–Q48 and « Après la passe Figma ») are referred to by number below. Design: the Figma section
`Réseau · Graphe` (`512:15486`), completed and validated on 2026-10-13 — see
[figma-library.md](../design-system/figma-library.md). Builds on [0028](0028-network-tab-and-groups.md) (the Réseau
tab and groups) and [0033](0033-group-pending-dot.md) (the red dot).

## What « Tout » turned out to be

The Réseau tab's control now reads **Tout | Amis | Groupes**, a native picker in a band fixed under the large title,
the same on all three segments so it never jumps. The tab opens on « Tout » the first time, then on the last segment
chosen; a value a Release build does not know reopens on Amis.

**The constellation.** « Vous » at the centre — my photo or my initials in a 72 pt green ring, a « Vous » pill over
its edge. My groups on a ring around it: admin, then member, then invitation, each block by name, the first on top,
clockwise. My friends near the groups we share, pushed outwards; a friend in two groups is one node with two lines.
Friends with no group in common, and readers who asked to be my friend, sit on a closer ring, tied to me alone. Lines
are green, the Vous ↔ friend ones lighter; an invitation or a request received is dashed — the line, the group card's
border, the requester's ring. Requests I sent, requests to join I sent, and members of my groups who are not my friends
are not drawn. A group card says « Admin · 12 membres », « 12 membres » or « Invitation de Camille », with the red dot
of 0033 when requests wait on me as its admin. The graph opens already laid out and framed on the whole network, white
on `backgroundDefault`, nav bar included, while Amis and Groupes keep their grey.

**Pinch, pan, touch.** It pinches around the fingers and pans, never leaving the screen, from the opening frame (the
smallest scale) up to twice full size. Zoomed out past ×0.6 it turns to an **overview** — readers as 24 pt dots
(photo or plain tinted disc, no initials), groups as compact tiles, « Vous » at 70 %, and only the lines of isolated
friends and requesters left among the Vous ↔ friend ones — and back above ×0.7. Glass **Zoomer / Dézoomer / Recentrer**
buttons sit at the bottom right; a glass **status pill** at the bottom left says « 42 amis · 6 groupes »,
« Synchronisation… » until relations and groups have answered once, or « Réessayer » after a failed first launch.

**A node touched** lights its lines and neighbours and dims the rest to 30 %; a native sheet rises, sized to its
content, with the graph still live behind it. A group: its role, « 12 membres, dont 4 de vos amis : Inès, Léa, Rémi et
Camille. » (three names and « et N autres » past four), up to five overlapping avatars, « Ouvrir le groupe ». A friend:
« Membre depuis … », « 1 groupe en commun : Club de Belleville. » (admin and member groups only), « Voir le profil ».
A group that invited me, or a reader who asked, adds **Accepter / Refuser**: accepted, the dashes turn solid and the
sheet stays on the new state; refused, the node leaves and the sheet closes. Touching another node swaps the sheet;
empty space or a drag down closes it; « Vous » does nothing. The graph pans just enough to lift a node out from under
the sheet.

**With nobody around me** (E1): « Vous » alone, « Vos amis lecteurs et vos groupes se placeront ici, autour de
vous. », and two links, « Ajouter des amis lecteurs » and « Trouver un groupe » — no zoom controls, no counter. On
« Tout » the « + » is a native menu: « Ajouter des amis lecteurs », « Créer un groupe ».

**Everywhere else**, a reader or a group without a picture — or whose picture fails to load — now shows initials on a
tinted disc or the `person.2` glyph on a tinted rounded square, instead of the grey square: the Amis and Groupes rows,
invitations, members, the group header, transaction rows.

## Technical surface

**Groups in the store (0103).**
- `StoredGroup` (`Model/Groups/`) — `@Model`, `_id` unique, `_rev`, name, slug, description, absolute picture URL,
  `open`, `searchable`, and the five role lists as `[GroupMembership]` (ids, no relationship to `User`). Only groups
  I hold a role in (admin, member, invited, requested from this device); one opened from a search stays in
  `GroupModel.visitedGroups` for the launch. Added to the `ModelContainer` schema as a lightweight migration, no
  `VersionedSchema`; `ModelContainerMigrationTests` opens a store of the previous schema.
- `GroupModel` reads and writes the store; its sync is an upsert with a deletion scope; optimistic gestures write to
  the store and are put back on failure. It remembers the signed-in reader (`groups.signedInReader`) so stored groups
  sort offline. `SyncStatusStore.Domain.groups` replaces `hasLoaded`.
- `MyGroups` (`Model/Groups/`) — stored groups as `ReaderGroup`s sorted by my role: what the Groupes segment lists
  (now through `@Query`) and what the tab badge counts (`MainTabView`).
- `UserDataSync` (`AppModels/Common/`) — the sync lifted out of `RootView+RefreshUserData`, order pinned by
  `UserDataSyncTests`: user, étagères, **relations, groups**, inventory, lists, transactions, friends' inventories.
  When my user cannot be fetched, every domain never synced is marked failed, so an offline first launch stops at
  « Réessayer » instead of spinning. `SyncUserDataAction`, set in the environment by `RootView`, reruns it.
- Sign-out and account deletion wipe the groups.

**Avatar fallback (0104).** `ReaderInitials` (`Model/Utils/`, one letter per word when the handle has separators —
`_ . -`, space, case change — else the first two, upper-cased, accents kept); `AvatarThumbnail`, `AvatarFallbackView`,
`AvatarKind`, `AvatarMetrics` (`Features/Components/`; `action300` from 44 pt, `action200` below). `AbsoluteImageURL`
(`Model/Utils/`) holds the URL rule `APIService.absoluteImageUrl` delegates to; `User`'s avatar URL now goes through it.

**The graph, pure (`Model/NetworkGraph/`, all `nonisolated`).**
- `NetworkGraph` — a value snapshot (`NetworkGraphInput`, built from the views' `@Query`s by
  `NetworkGraphInput+Store`) → nodes (`NetworkNodeID`), typed edges (`NetworkEdge`, `NetworkEdgeKind`), isolated
  readers, `NetworkGraphCounter`, a group's friends, a friend's common groups, `NetworkGraphHighlight`, and the
  VoiceOver `readingOrder`. Text rules: `NetworkNameList`, `NetworkGroupSummary`, `NetworkReaderSummary`,
  `NetworkGroupCardDetail`.
- `NetworkGraphLayout` (+ `Crowd`, `NetworkGraphRelaxation`) → `NetworkGraphPlacement`: elliptical rings (narrower
  than tall, for a portrait screen), readers sharing the same groups fanned out in rows, then relaxation until no two
  measured boxes are closer than 10 pt. Jitter seeded by `DeterministicTilt`. Cached by fingerprint in
  `NetworkGraphLayoutCache` (4 entries) and computed off the main actor. 200 friends + 30 groups: 7 ms optimised.
- `GraphViewport` — the camera: world → screen, opening frame, range ×min … ×2, pinch anchored at the fingers, bounded
  pan (the network's box always covers the middle of the graph area), ±×1.5 steps, recentre, the level with its
  hysteresis (`NetworkGraphLevel`, 0.6 / 0.7, tuned in one place), hit test (nearest anchor within 44 pt), the minimal
  pan out from under the sheet. A sync keeps scale and place, unless the camera is still on its opening frame.

**The views (`Features/Network/` and `Features/Network/Graph/`).**
- `NetworkSegment` (`.all` under `#if DEBUG`, `restored(from:)`, `ground`), `NetworkSegmentBand` (the picker in a
  `safeAreaInset(edge: .top)` band, its ground stopping at its own top edge so the large title stays visible),
  `NetworkSegmentContent`, `NetworkView` (`@AppStorage`, the « + » `Menu` on Tout).
- `NetworkAllView` (status, empty state or graph), `NetworkEmptyView` / `MeCentredLayout` / `MeCentredStack` /
  `NetworkFirstStepsCard` (E1).
- `NetworkGraphView` — measures every node invisibly at its real size, places, then shows; owns the camera, gestures,
  selection, sheet and answers. `NetworkConstellationView` draws edges in `NetworkEdgesCanvas` (one `Canvas`, styles
  from `NetworkEdgeStyle`) under node views set by `.position`, animatable so lines follow sliding nodes. Nodes:
  `NetworkMeNode`, `NetworkFriendNode` (+ `NetworkFriendRing`), `NetworkGroupCard` (+ `NetworkGroupCardBorder`),
  `NetworkFriendDot`, `NetworkGroupTile`; `NetworkOverviewBoxes` hands the overview's boxes to the camera. Sizes off
  the token scale live in `NetworkGraphMetrics`; no token was added.
- Sheets: `NetworkNodeSheet` → `NetworkGroupSheet` / `NetworkReaderSheet`, `NetworkSheetAvatars`,
  `NetworkSheetAnswerButtons`. `.sheet` with one `.height` detent measured from the content,
  `presentationBackgroundInteraction(.enabled)`. Answers go through `GroupModel`'s accept / decline and
  `InvitationAnswer` for relations.
- Controls: `NetworkGraphZoomControls` (`.buttonStyle(.glass)` in a `GlassEffectContainer`, `.labelStyle(.iconOnly)`,
  disabled rather than hidden at the ends of the range), `NetworkGraphStatusPill` / `NetworkGraphStatusText`
  (`.glassEffect`), `NetworkGraphStatus`.
- VoiceOver (0110): `NetworkGraphAccessibility` (labels, built once per network), `NetworkNodeAccessibilityFrame` /
  `NetworkNodeAccessibilityElement` (transparent frames, one per node, in reading order), `NetworkNodeAction`.
- Motion: `NetworkGraphMotion` — nothing on opening, nothing with Reduce Motion, otherwise a 0.45 s slide.

**End-to-end (0111).** A step « Réseau · Tout : un groupe ouvert depuis le graphe » in `E2EScenarioTests`, between
« Ranger mes livres » and the list steps; `E2EDriver.Tab.network`. It reports « non joué » when the account has no
network or no group among the first eight nodes probed. Identifiers: `e2e.network.graph`,
`e2e.network.graph.node.<id>` / `.node.me`, `.sheet`, `.sheet.openGroup`, `.sheet.viewProfile`, `.sheet.accept`,
`.sheet.refuse`, `.zoomIn`, `.zoomOut`, `.recentre`, `.status`. Described in
[0012](0012-end-to-end-scenario.md), « What the Réseau graph added ».

**Tests.** `GroupPersistenceTests`, `GroupModelTests` (adapted), `MyGroupsTests`, `ModelContainerMigrationTests`,
`UserDataSyncTests`, `UserRelationTests` (a refused request put back on failure), `ReaderInitialsTests`,
`AbsoluteImageURLTests`, `AvatarMetricsTests`, `NetworkSegmentTests`, `NetworkAllContentTests`,
`MeCentredStackTests`, `NetworkGraphTests`, `NetworkGraphInputStoreTests`, `NetworkGraphLayoutTests` (zero overlap on
R1, R3 and 200 + 30 at full size; determinism; budget), `NetworkGraphRenderingRulesTests`, `NetworkSheetTextTests`,
`GraphViewportTests`, `NetworkGraphAccessibilityTests`, `TextStyleDynamicTypeTests`. Fixtures R1, R3 and the stress
network in `Tests/Support/NetworkGraphFixture.swift`. `ReaderGroupTests` unchanged.

## Notable decisions

- **Groups are persisted, reversing 0028.** A graph that opened empty and rearranged itself after the inventory sync —
  minutes on a first launch, never offline — was not drawable. The cost is one more entity in the schema.
- **`ReaderGroup` stays the domain type.** `StoredGroup` is only where a group is kept: `readerGroup` reads it out,
  `overwrite(with:)` writes back a value the app computed, `update(from:pictureURL:)` merges the server's. Every transition and
  its 12 tests stayed where they were.
- **`textStyle(_:)` now reads its own view's Dynamic Type size** — an app-wide change. The design-system fonts were
  scaled to the app's size through `UIFontMetrics`, which a SwiftUI `.dynamicTypeSize(...)` cap never reached, so
  the graph's `.xxxLarge` cap (Q43) was silently ignored. `TextStyleModifier` now scales for the environment's size;
  `uiFont` (no argument) remains for UIKit's navigation bar. Every screen goes through it; outside a cap the result is
  the same size as before.
- **Nodes shrink below ×1.** From full size up, nodes keep their size and only their places move apart; below it they
  shrink with the network (`GraphViewport.nodeScale`), otherwise a full graph framed at ×0.8 would overlap where the
  layout left gaps. The opening frame is drawn in full if the whole graph fits at ×0.6 or more, in the overview
  otherwise.
- **Nodes are not buttons.** A touch goes through the camera's hit test (nearest anchor within 44 pt) so a 24 pt dot
  is touchable and two close nodes resolve predictably. The e2e step touches them by coordinate.
- **Reading-order accessibility frames.** Sort priority alone did not hold for nodes placed with `.position` — their
  `zIndex` set the order. The drawn nodes are hidden from accessibility; a layer of transparent frames, laid out in
  `NetworkGraph.readingOrder` and given it as sort priority, carries the labels and actions and lets touches through.
- **A friend's name sits on the ground**, so lines from its own avatar pass under it rather than through it.
- **« Tout » is DEBUG-only** (Q47): no feature flag in the app, so the intermediate slices could not reach a Release
  build. Taking the `#if DEBUG` out of `NetworkSegment` is issue 0113's.
- **Native sheet, native picker, native menu, Liquid Glass** for the controls: VoiceOver, Dynamic Type and the system
  look come with them; the Figma drawings are stand-ins.

### Divergences from Figma (the code is the source of truth)

| Point | Figma | Code |
|---|---|---|
| Segmented control | `Chrome / Segmented Control · 3`, drawn | native `Picker` in a fixed band |
| Node sheet | drawn panel, 32 pt radius (no token) | native `.sheet`, one measured detent, system grabber, graph live behind |
| Zoom controls, status pill | capsules (`521:15969`, `521:15993`), stand-ins | `.buttonStyle(.glass)` in a `GlassEffectContainer`; `.glassEffect` pill; buttons disabled, not hidden, at range ends |
| « + » menu | drawn panel | native `Menu` in the toolbar |
| Compact tile radius | 14 | `CornerRadius.medium` (8) |
| Glyphs | substitutes from `Icon` (no `minus`, `scope`, `person.badge.plus`, `arrow.clockwise`) | those SF Symbols |
| Between ×0.6 and ×1 | not drawn | full nodes scaled down with the network |
| Off-scale sizes (72, 44, 24, 52, 32 pt; pill paddings 3/10 and 6/12) | literal | literal, in `NetworkGraphMetrics`, no new token |
| R4 (zoomed, minimap) | drawn | not built (out of v1) |
| Book counts in R5 / R6 | drawn | not built, as in 0028 |

## Not verified

- **Never seen signed in**, on a simulator or a device: no real account, no real network. A real network in light and
  dark, at large text sizes, with Reduce Motion, offline and on a first launch is unchecked.
- **No real VoiceOver pass.** The reading order and the frames were checked in the simulator's accessibility tree
  (0110), not by listening.
- **No 60 fps measurement** while panning 200 friends + 30 groups (Q45); the hysteresis thresholds (0.6 / 0.7) and the
  ×2 maximum are untuned.
- **The e2e step is written and compiles; it was not run.**
- **The sheet's accept / refuse animation** — dashes turning solid, a refused node fading while the sheet slides down
  with its last content — was never watched.
- Android: not ported; Android's Réseau stays friends only.

## Known defects

- **The overview overlaps at its opening frame on large networks** — 13 overlapping pairs on R3, many on 200 friends +
  30 groups. The placement keeps full-size boxes apart; the overview draws fixed-size dots and tiles at those places
  scaled below ×0.6, which brings them closer than their own size. It needs a placement of its own:
  [issue 0114](../issues/0114-overview-placement.md).

## Issues

| Issue | Commit |
|---|---|
| 0103 Groups persisted, synced right after relations | `0b035c6` |
| 0104 Shared avatar fallback | `963c203` |
| 0105 The « Tout » segment: band, remembered segment, « + » menu, empty state | `32628ff` |
| 0106 The constellation: pure graph and layout, nodes and edges drawn | `f6b460a` |
| 0107 Pinch, pan, touch; group and friend sheets | `870b36f` |
| 0108 Answering from the sheet | `0a843ef` |
| 0109 Overview, glass controls, counter and status pill | `2478796` |
| 0110 VoiceOver on the graph | `86eb0c9` |
| 0111 An e2e step for Réseau · Tout | `432a6be` |
| 0112 This write-up | — |

Still open: [0113](../issues/0113-network-graph-device-review.md) (device review, then out of DEBUG) and
[0114](../issues/0114-overview-placement.md) (overview placement).
