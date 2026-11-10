# Performance iOS

How the iOS app is measured, the baseline it started from, and what each perf task changed. Lag felt in Réseau and Listes started the sprint « iOS perf » (2026-11-10): #124 measures, #125–#131 fix.

## Code

- `AppModels/Common/UserDataSync.swift` — one signpost interval per sync phase
- `AppModels/Inventory/InventoryModel.swift` — one signpost interval per `syncInventory` call, mine and each friend's

Subsystem `asso.recits`, category `sync`. No signpost names a reader: `syncInventory` only reports whether it was a first sync and how many items it announced.

## Protocol

Always the same, so that two numbers can be compared.

- **Device**: an iPhone, never the simulator: the simulator runs on the Mac's CPU.
- **Build**: Release (Xcode › Product › Profile). Debug distorts SwiftUI.
- **Account**: a real reader's, with friends, groups and lists. A test account is too small to lag.
- **Instruments**: the SwiftUI template, plus the Hangs instrument and an os_signpost instrument filtered on `asso.recits`.
- **Path**, the same in both scenarios:
  1. Réseau › Amis — scroll to the bottom and back.
  2. Réseau › Groupes — same.
  3. Listes — same, « Mes listes » then « Dans mon réseau ».

### Scenario 1 — empty store

App deleted, reinstalled, recording started, then sign in and walk the path while friends' inventories sync. One sign-in only: inventaire.io rate-limits sign-ins (`429`).

### Scenario 2 — warm store

App killed, recording started, app launched, same path. The syncs have almost nothing to do.

Traces stay on the Mac and are never committed. They are read with `xcrun xctrace export --input <file>.trace --toc`, then `--xpath` on the tables needed.

## Baseline

Not recorded yet: waiting for the two traces.

| | Scenario 1 — empty store | Scenario 2 — warm store |
|---|---|---|
| Hangs > 250 ms (count · longest · screen) | — | — |
| Scroll hitches, Réseau › Amis | — | — |
| Scroll hitches, Réseau › Groupes | — | — |
| Scroll hitches, Listes | — | — |
| My user | — | — |
| My shelves | — | — |
| Relations | — | — |
| Groups | — | — |
| My inventory | — | — |
| Lists | — | — |
| Transactions | — | — |
| Network lists | — | — |
| Friends' inventories | — | — |

## Before / after

One row per task, measured with the protocol above, on the scenario it targets.

| Task | Scenario | Measure | Before | After |
|---|---|---|---|---|
| #125 Move sync off main actor | | | | |
| #126 Batch inventory sync requests | | | | |
| #127 Speed up the Lists tab | | | | |
| #128 Speed up the Réseau tab | | | | |
| #129 Speed up cover loading | | | | |
| #130 Narrow inventory item queries | | | | |
| #131 Cache text style fonts | | | | |
