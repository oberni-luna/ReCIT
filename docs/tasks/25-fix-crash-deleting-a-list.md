---
issue: 25
status: todo
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

## Review

## Verification

## Feedback
