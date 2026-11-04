# How far a first sync has got, and friends that no longer wait for their books

Shipped on 2026-09-27, from the Figma section `Synchronisation · Progression` (`495:13490`), frames
`I-A · Inventaire · Encart` (`495:13591`), `P · Profil · Amis en synchronisation` (`495:13895`) and
`F-A · Ami · Encart` (`495:14066`). No PRD and no issues: one slice, decided in an autopilot run whose decision log
is summarised below.

## What it does

A first sync of a large inventory could take minutes behind an indeterminate spinner, and the Profil kept the
friends list behind another until **every** friend's books had landed.

- **My inventory.** The Inventaire tab no longer waits behind `SyncingPlaceholderView`. While my first sync runs,
  a card sits at the head of the page — « Synchronisation de vos livres », the share as a percentage, a
  determinate bar, « 312 livres sur 1 240 · ils apparaissent au fur et à mesure » — and the books fill in below
  it as they are saved. Before `inventory-view` has answered there is no total: the bar is empty, a small spinner
  stands where the percentage goes, and the line reads « Préparation de la synchronisation… ».
- **The friends list.** It shows as soon as the relations are known. Each friend whose books have never landed
  carries, under their name, the bar and « X livres sur Y », or « En attente » while their turn has not come
  (or their last attempt failed). Once synced, the cell goes back to « Membre depuis … ».
- **A friend's profile.** The same card, titled « L'inventaire de Camille arrive », above the books already
  received.

Progress is **items received / items announced**, counted in distinct item ids.

## Technical surface

- **`InventorySyncProgress`** (`AppModels/Inventory/`) — pure: the total (distinct ids of `workUriItemsMap`,
  `nil` until known), the set of ids received, `fraction`. An item filed under two works counts once on both
  sides; an empty inventory is complete.
- **`InventoryFirstSyncState`** — `.synced` / `.waiting` / `.running(progress)`, from `lastInventorySync` and the
  running progress.
- **`InventoryModel`** — `firstSyncProgress: [userId: InventorySyncProgress]`, in memory, set only when
  `lastInventorySync == nil` at the start of a sync, cleared by a `defer` however the sync ends;
  `firstSyncState(for:)` is what views read. `syncInventory` now walks **author by author**: the author's works,
  then at once the items of those works (`syncItems(ofWork:…)`), then `save()`. The works no author claimed, or
  whose author failed, keep a final pass, as before. A work's ids count into the progress even when the work or
  its items could not be had, so the bar still reaches its end.
- **`RootView+RefreshUserData`** — `.community` is `syncRelations` only. `syncFriendsInventories()` runs last,
  after lists and transactions: friends sorted by name, the never-synced first, one at a time, shelves then
  books, each failure caught per friend.
- **Views** (`Features/Components/`) — `InventorySyncProgressBar` (linear `ProgressView`, `foregroundTinted`),
  `InventorySyncCaption`, `InventorySyncBanner` (card-free; `ShelvesContent` wraps it on `backgroundSecondary`
  with `radius/medium`, `UserDetailView` gives it a row). `UserCellView` shows the bar for `relation == .friend`
  only.
- **`ShelvesView` / `ShelvesContent`** — the content is reached before the first sync; the banner shows while
  the state is not `.synced`, and the empty-shelf card waits for `.synced`.
- Strings `sync.inventory.{mine.title,friend.title %@,count %lld %lld,count_arriving %lld %lld,preparing,waiting}`,
  fr and en. Accessibility identifier `e2e.shelves.syncBanner`; the end-to-end scenario does not use it.
- Tests: `InventorySyncProgressTests.swift` — the two pure types, and `syncInventory` against `MockAPIService`
  (a landed sync leaves no progress behind, a failed one goes back to waiting).

## Notable decisions

- **Card (A), not the compact bar (B).** A long sync should be seen; B stays in Figma.
- **The total is known after the first request.** `inventory-view` returns the whole work → items map at once,
  so the bar is determinate from its first answer on; only that first request is unmeasured.
- **Author by author, saved as it goes.** Every work first and every item after kept the bar at zero for as long
  as the works took, then ran it to the end at once; and one save at the end meant nothing reached `@Query`
  before the last book. One save per author is the compromise between books appearing and a re-render per work.
- **Content during the first sync.** The maquette shows books under the card, so the full-screen placeholder
  goes. What an empty store would say falsely — the empty-shelf card's « scannez vos livres » — is held back;
  « Ranger » was already gated on `lastInventorySync`, and so is the onboarding.
- **Friends last and one by one.** Their books are not what any screen in front of the user waits for, so lists
  and transactions go first; one at a time so each bar fills in turn.
- **In memory, first syncs only.** A refresh lands on books already there. A sync cut short by a relaunch starts
  over, and so does its bar.
- **« En attente » also after a failure.** It is true: the next refresh tries again. Telling the two apart would
  need a queue the view does not need.

### Divergences from the Figma frames (the code is the source of truth)

| Point | Figma | Code |
|---|---|---|
| Card background | white on the grey page | `backgroundSecondary` — the inventory's page is white |
| Section count | « Tous les livres · 312 sur 1 240 » | « Tous les livres · 312 » — the card says the rest |
| Friend header | « 540 livres » | the server's snapshot count, unchanged |
| Before the total | not drawn | empty bar, spinner in place of the percentage, « Préparation… » |
| Chrome | cloned frames' tab bars | the app's tabs, unchanged |

## Not done / not verified

- **Not seen in the running app signed in**: built, 755 unit tests green. A pass on a device with a large
  inventory and several friends is owed — the bar's pace, the save per author, and the Profil list re-rendering
  while books land.
- **End-to-end scenario not played** (on request only). It reads none of the identifiers touched here, but it
  signs in on a fresh store, so it now goes through the banner and the progressive inventory.
- **Deferred**: bringing the friend one opens to the front of the queue; variant B; a live count in the friend
  header.
