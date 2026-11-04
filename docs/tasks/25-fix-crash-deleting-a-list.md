---
issue: 25
status: to-close
wiki: [[lists]], [[architecture]]
note: found by the iOS 1.9.0 gate (#19), which it blocks
created: 2026-11-04
---

## Context / Decisions

> Found by /wa-code 19 (iOS 1.9.0 gate) on 2026-11-04. Deleting a list from the Lists tab (swipe → « Supprimer la liste ») crashes: EntityList.type.getter on a deleted model, from ListRowView.swift:21 (crash 16:25). Same signature at 12:41 from ListCoverFlowScreen.swift:117. Blocks #19.

- **The cause:** `ListModel.deleteList` waits for the server, then calls `modelContext.delete(list)` + `save()`. A view still holding that `EntityList` renders once more and reads a persisted property (`list.type`). SwiftData traps on that read: it is an `EXC_BREAKPOINT`, not a nil. Crash logs: `~/Library/Logs/DiagnosticReports/ReCIT_iOS-2026-11-04-162520.ips` and `…-124150.ips`.
- **The fix is the project's existing one:** `PersistentModel.isStillInTheStore` (`Model/Utils/PersistentModel+StillInTheStore.swift`), asked before any persisted read on a model the view does not own. No new mechanism.
- **Where to fix:** every view that can outlive a list's deletion.
  - The Lists tab: `ListsTabList`, its sections, and `ListRowView` (« Mes listes » and « Dans mon réseau »).
  - A friend's Listes tab: `UserListsTab`, whose rows are `ListRowView` too.
  - The list's own screen: `EntityListDetail` → `ListCoverFlowScreen`, which `ListFormView`'s delete leaves behind for one render before it pops.
  - A deleted list is dropped before rendering, never drawn half-empty.
- **Unchanged:**
  - Deletion stays server-first, not optimistic (ADR 0001 lets this one wait: the confirmation already says it is final).
  - The confirmation copy stays as it is.
- **Tests:** a unit test where a list is deleted and saved shows that the Lists tab's section building drops it, without trapping. It reads `isStillInTheStore`, never a property of the deleted list.
- Out of scope: the e2e driver (#24), and any other `@Model` type's deletion.

## Acceptance criteria

- [ ] Lists tab → swipe one of my lists → « Supprimer la liste »: the row disappears, the app keeps running, the list is gone after a relaunch
- [ ] A list's screen → « … » → Modifier → delete: back on the Lists tab, no crash
- [ ] The Lists tab's section building skips a list that was deleted from the context (unit test)
- [ ] `ReCIT_iOSTests` green, build green with SwiftLint, no new baseline entry

## Implementation

Round 1 — 2026-11-04.

- `ListsTabSections`: drops lists that are no longer in the store before reading `name` / `creatorId`.
- `ListsTabList`, `UserListsTab`: each row guarded with `isStillInTheStore`; `UserListsTab.lists` filtered first. e2e identifiers moved to private `AccessibilityID` constants (same strings).
- `NetworkListEntry.id` → `list.id` (`PersistentIdentifier`), so `ForEach` diffing never reads a persisted property.
- `ListRowView` (crash 16:25), `ListCoverFlowScreen` (crash 12:41), `ListElementsPage`, `ListPresentationPage`: body only when `list.isStillInTheStore`. The two pages are hosted by `TabPager` in their own `UIHostingController` and re-render on their own.
- `EntityListDetail`: `list` = first match still in the store; the not-found view only when the query is empty; `popIfTheListIsGone` unchanged.
- Tests: new `ListsTabSectionsTests` (deleted and saved · deleted before save · friend's list deleted while searching); `NetworkListsTests` now inserts its lists into a context.
- `.swiftlint.baseline`: 3 stale `accessibility_id_constant` entries removed (4194 → 4191), nothing added.
- Proof: `ReCIT_iOSTests` `** TEST SUCCEEDED **` (1251), SwiftLint 0 violations. `RequestPacerTests/runsInOrder()` failed once under parallel load, passed on rerun — unrelated timing flake.
- Not touched: `ListFormView` still reads `list._id` / `name` until `dismiss()` (no crash seen), `ListMoveRow`, other `@Model` types.

## Review

Round `validation` — 2026-11-04, `/wa-close 25`. LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓.

- 🟠 `ListMoveRow.swift:42` [correctness] unguarded `list` / `item` reads in a FormList cell → fixed: `destinations` guards both, `lists` filtered on `isStillInTheStore`
- 🟠 `ListCommentRow.swift:68` [correctness] body reads `item` after the cascade → fixed: body behind `if item.isStillInTheStore`
- 🟡 `ListFormView.swift:64` [correctness] form reads the deleted list until `dismiss()` → fixed: body behind `isCreating || list.isStillInTheStore`; `isCreating` now a `let` set in each init (the computed one read `_id`)
- 🟡 `ListsTabSectionsTests.swift:16` [style] third copy of list/friend builders → fixed: `EntityList.mock(...)` in the model's file, `Fixture.user(relation:)`, used by three suites
- 🟡 `NetworkListsTests.swift:111` [structure] section tests in the sync suite → fixed: moved to `ListsTabSectionsTests`, backtick names
- 🟡 `NetworkListsTests.swift:43` [style] friends block ×3 (round 2) → fixed: `private let friends`
- Autofix side effects: 4 `ListFormView` identifiers to a private `AccessibilityID`, two `AsyncButton` calls one argument per line; `.swiftlint.baseline` 4191 → 4181 (10 stale removed, 0 added).
- Final: ✅ review clean. Tests 1251 green, SwiftLint 0.
- ⚠️ Code changed after the simulator pass: « Déplacer », comment row, list form — same guards, not re-run on the simulator.

## Verification

Round 1 — simulator pass on request (Olivier, 2026-11-04), iPhone 17 iOS 26, account `OlivierB_test4`, screenshots in `build/task-25/`.

- ✅ Listes → swipe « Test » → Supprimer → « Supprimer la liste »: row gone, app running (01)
- ✅ « For » → pencil → « Supprimer la liste »: back on Listes, no crash (02)
- ✅ OlivierB → Listes • 2: rows shown, « Livres lus » opens read-only (03, 04)
- ✅ Relaunch: both deleted lists stay gone (05). No new file in `~/Library/Logs/DiagnosticReports/` since the 16:25 crash.
- Note: « Supprimer la liste » in the form deletes without a confirmation, unlike the swipe. Unchanged by this task; Olivier to say if it should ask.

## Feedback
