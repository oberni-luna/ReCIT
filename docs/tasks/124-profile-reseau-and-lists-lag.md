---
issue: 124
status: to-close
wiki: [[architecture]], [[network]], [[lists]], [[performance]]
note: First of the 2026-11-10 perf pass — lag felt in Réseau and Listes. #125–#131 are blocked by it.
created: 2026-11-10
---

## Context / Decisions

> Idée : « il faudrait améliorer les perfs sur iOS, je trouve que ça lag un peu dans l'écran Réseau ou dans les listes ».

The lag is felt, never traced. This task leaves two things behind: sync signposts in the code, and a written baseline. Each later perf task (#125–#131) measures before/after with them and commits as `perf:`.

- **Signposts, not a perf test.** An `XCTOSSignpostMetric` UI test would need a populated account signed in to inventaire.io: the e2e's cost and its `429`. Rejected for now.
- **Where.** One `OSSignposter` per type, `static let`, subsystem `asso.recits` like `APIService`'s `Logger` (`docs/conventions/style.md` → Logging).
  - `UserDataSync.run`: one interval per phase — my user, shelves, relations, groups, my inventory, lists, transactions, network lists, friends' inventories (the whole loop).
  - `InventoryModel.syncInventory`: one interval per call. It covers mine and each friend's. No username in the signpost: an index or the item count, nothing that names a reader.
  - Nothing else instrumented. The SwiftUI instrument already shows body updates of the views.
- **No other change.** The `print`s in `UserDataSync` stay: removing them is #125's job.
- **Who records.** Olivier, on his iPhone, Release build, his real account. The volume of friends, items and lists is what makes the lag. `OlivierB_test4` is too small. The simulator measures the Mac's CPU.
- **Templates.** Instruments SwiftUI + Hangs (+ os_signpost through the SwiftUI template's Points of Interest / custom signposts).
- **Two scenarios, same path.**
  1. Empty store: app deleted and reinstalled, sign in, then Réseau → Amis, scroll; Réseau → Groupes, scroll; Listes, scroll. Done while friends' inventories sync. One sign-in only, no `429` risk.
  2. Warm store: app killed and relaunched, same path.
- **Reading the trace.** The agent reads the `.trace` files Olivier hands over with `xcrun xctrace export` and writes the numbers. Traces stay on the Mac, never committed.
- **Report.** New page `docs/wiki/performance.md`, one line in `docs/wiki/index.md`. It holds:
  - the protocol above, so anyone can replay it;
  - the baseline per scenario: hangs > 250 ms (count, longest, which screen), scroll hitches in Réseau and Listes, duration of each sync phase;
  - an empty "Before / after" table, one row per later task (#125–#131).
  - No username, book title or list name: numbers only.
- **Blockers.** #125–#131 are all blocked by this task.

## Acceptance criteria

- In Instruments on a Release build, the `asso.recits` signposts show one interval per `UserDataSync` phase, in the order the sync runs.
- Each `InventoryModel.syncInventory` call shows as its own interval, mine and each friend's. No username appears in any signpost.
- The app's behaviour is unchanged: same sync order, same screens, existing tests green.
- `docs/wiki/performance.md` exists, linked from `docs/wiki/index.md`, with the protocol and both scenarios.
- Once Olivier has handed over the two traces, the page carries the baseline per scenario, read from them:
  - hangs > 250 ms;
  - scroll hitches in Réseau (Amis, Groupes) and Listes;
  - duration of each sync phase.
- The page has an empty before/after table, one row per task #125 to #131.
- The page contains no reader name, book title or list name.

## Implementation

Round 1 (2026-11-11).

- `AppModels/Common/UserDataSync.swift` — `private static let signposter` (`asso.recits` / `sync`); private `signposted(_:_:)` opens an interval and ends it in a `defer`. `sync(_:signpostedAs:_:)` takes the interval's name. Nine intervals in sync order: My user, My shelves, Relations, Groups, My inventory, Lists, Transactions, Network lists, Friends inventories (the whole loop).
- `AppModels/Inventory/InventoryModel.swift` — its own `signposter`; one « Inventory sync » interval per `syncInventory` call, ended in a `defer` on every path. End message: `firstSync` and `items` (distinct item ids announced), both `.public`, nothing naming a reader. `isFirstSync` moved above the early return so the `defer` can read it.
- `run` keeps its exact length: its `function_body_length` entry in `.swiftlint.baseline` matches on the line count, so each wrapped call is a one-line trailing closure. Baseline and lint config untouched.
- `print`s left in place (#125).
- `docs/wiki/performance.md` + `index.md` line: protocol, both scenarios, empty baseline and before/after tables.
- Proof: Debug and Release builds ✅ (iPhone 17 simulator, SwiftLint in the build); full `ReCIT_iOSTests` ✅, 1321 tests, `UserDataSyncTests` and `InventorySyncProgressTests` included.
- Open: the baseline needs Olivier's two Release traces from his iPhone; the agent then reads them with `xctrace export` and fills the page.

Round 2 (2026-11-11) — the baseline.

- First two traces (SwiftUI template + Hangs + Hitches + os_signpost): over a gigabyte each, nothing in them to tell which screen a hitch is on, and the sync signposts only partly there. `swiftui-updates` exports to more than 11 GB.
- `AppModels/Common/ScreenSignpost.swift` — one « Screen » event (`asso.recits` / `screen`) each time Réseau › Amis, Réseau › Groupes or Listes comes on display: `NetworkView` on appear and on segment change, `EntityListView` on appear. Name of the screen only. A deviation from « nothing else instrumented », agreed with Olivier: without it the scroll hitches can't be split by screen.
- Re-recorded both scenarios with Hangs, Hitches and os_signpost only (18–25 MB a trace). Screens and hitches captured; the sync intervals still not. Likely cause: `APIService` logs every response body at `debug` under `asso.recits`, drowning the subsystem's signposts while the sync runs. Left to #125.
- `docs/wiki/performance.md` — protocol updated (light recording, the keychain survives a reinstall), baseline filled: no hang over 250 ms; 241 ms/s of scroll hitches during the first sync; Listes at 65.5 ms/s on a warm store, Réseau under 10; sync phases partial.
- Proof: Release device build ✅ (SwiftLint in the build); full `ReCIT_iOSTests` ✅ on the iPhone 17 simulator.

## Review

Round `validation` (2026-11-11), cumulative diff from `origin/sprint/ios-perf`.

- 🟠 `ScreenSignpost.swift` — [structure] `init(_ segment: NetworkSegment)` made AppModels depend on Features → mapping moved to `Features/Network/NetworkSegment+ScreenSignpost.swift` (`segment.screenSignpost`). Fixed.
- 🟡 `InventoryModel.swift` — [structure] announced-item count computed twice → one `InventorySyncProgress` per sync, its `total` read for the signpost. Fixed (no DTO property: `InventorySyncProgress.init(workUriItemsMap:)` takes a bare map, used by tests and previews).
- Re-verify: ✅ clean, four lenses. Debug build with SwiftLint ✅; InventorySyncProgressTests, InventoryFirstSyncStateTests, InventoryModelFirstSyncTests, UserDataSyncTests ✅.
- Screenshots: none, no screen changed.

## Verification

manual validation — not run by agent.

## Feedback
