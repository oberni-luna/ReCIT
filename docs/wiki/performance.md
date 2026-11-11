# Performance iOS

How the iOS app is measured, the baseline it started from, and what each perf task changed. Lag felt in Réseau and Listes started the sprint « iOS perf » (2026-11-10): #124 measures, #125–#131 fix.

## Code

- `AppModels/Common/UserDataSync.swift` — one signpost interval per sync phase
- `AppModels/Inventory/InventoryModel.swift` — one signpost interval per `syncInventory` call, mine and each friend's
- `AppModels/Common/ScreenSignpost.swift` — one « Screen » event each time Réseau › Amis, Réseau › Groupes or Listes comes on display (`NetworkView`, `EntityListView`), so that a hitch can be put down to a screen

Subsystem `asso.recits`, categories `sync` and `screen`. No signpost names a reader: `syncInventory` only reports whether it was a first sync and how many items it announced, « Screen » only the screen's name.

## Protocol

Always the same, so that two numbers can be compared.

- **Device**: an iPhone, never the simulator: the simulator runs on the Mac's CPU.
- **Build**: Release (Xcode › Product › Profile). Debug distorts SwiftUI.
- **Account**: a real reader's, with friends, groups and lists. A test account is too small to lag.
- **Instruments**: Hangs, Hitches and os_signpost, nothing else. The SwiftUI template writes over a gigabyte in three minutes, its `swiftui-updates` table exports to more than 11 GB, and it loses signposts. From the Mac, the iPhone unlocked:

  ```sh
  xcrun xctrace record --device <udid> \
    --instrument os_signpost --instrument Hangs --instrument Hitches \
    --time-limit 3m --output build/perf/<scenario>.trace \
    --launch -- studio.lunabee.nouveau-recit
  ```

  The two baseline traces also passed `--recording-options` with `asso.recits` in `os_signpost`'s `dynamicTracingEnabledSubsystems`; it did not bring the sync signposts back (see below). Hangs are recorded from 100 ms; the baseline counts those over 250 ms and lists the others.
- **Path**, the same in both scenarios:
  1. Réseau › Amis — scroll to the bottom and back.
  2. Réseau › Groupes — same.
  3. Listes — same, « Mes listes » then « Dans mon réseau ».

### Scenario 1 — empty store

App deleted, reinstalled, recording started, then walk the path while friends' inventories sync. Deleting the app does not sign out: the session is in the keychain, which survives it, so the app opens signed in on an empty store. When it does ask, one sign-in only: inventaire.io rate-limits sign-ins (`429`).

### Scenario 2 — warm store

App killed, recording started, app launched, same path. The syncs have almost nothing to do.

Traces stay on the Mac and are never committed. They are read with `xcrun xctrace export --input <file>.trace --toc`, then `--xpath` on `potential-hangs`, `hitches` and `os-signpost`. A hitch belongs to the screen of the last « Screen » event before it; only hitches inside a UIKit `Scroll_DraggingAndDeceleration` interval count as scroll hitches. The hitch rate is milliseconds of hitch per second of scrolling: Apple calls more than 10 ms/s critical.

## Baseline

Recorded on 2026-11-11, iOS 27.2, Release build of 1.11.0 (23), on the account of a reader with 22 friends.

| | Scenario 1 — empty store | Scenario 2 — warm store |
|---|---|---|
| Hangs > 250 ms | 0 | 0 |
| Hangs 100–250 ms | 2: 131 ms during the first sync, 192 ms a second before Listes came on display | 3: 135 ms on opening Listes, 185 ms in Listes, 105 ms on opening Réseau › Groupes |
| Hitches, whole trace | 2 039 in 150 s, 27.1 s of hitch, longest 92 ms | 130 in 161 s, 2.3 s of hitch, longest 38 ms |
| Scroll hitches, during the first sync, any screen | 241 ms/s (1 791 hitches over 100 s of scrolling) | — |
| Scroll hitches, Réseau › Amis | 9.0 ms/s, once synced | 9.8 ms/s |
| Scroll hitches, Réseau › Groupes | 9.8 ms/s, once synced | 9.8 ms/s |
| Scroll hitches, Listes | 9.6 ms/s, once synced | **65.5 ms/s** (74 hitches over 24 s) |
| Sync phases, my user to network lists | not captured | not captured, but network lists: 116 ms |
| Friends' inventories | partial: 17 first syncs seen, 62.9 s for 351 items, the slowest 26.7 s for 118 items | 1.6 s for 22 friends, nothing new |

What it says:

- **The first sync is the lag.** While friends' inventories sync, every screen hitches at 241 ms/s, twenty-four times Apple's critical line, and a friend's first inventory costs about 180 ms per item. #125 and #126.
- **Listes lags on its own.** With a warm store and nothing to sync, Listes hitches at 65.5 ms/s where Réseau stays under 10, and three of the five hangs are in Listes or on the way to it. #127.
- **Réseau, once synced, is near the line, not over it.** #128 and #130 should be judged on scenario 1.

The sync phases were not captured. Signposts of category `sync` arrived, in part, in two of the five traces recorded, never in the three others; the « Screen » events, added for the last two, arrived in both. The likeliest cause: `APIService` logs every response body at `debug` under the same subsystem (`APIService.swift`, `logger.debug("Response: …")`), and while the sync runs that volume drowns the subsystem's signposts. The figures above for the sync come from the two first traces (SwiftUI template), kept on the Mac. Silencing it goes with #125, which already takes the `print`s out of the sync; its first trace fills these rows.

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
