---
issue: 94
status: to-test
wiki: [[features/0080-a-private-note-on-my-copy]], [[features/0031-android-app]], [[adr/0001-swiftdata-reactive-optimistic]]
note: Rattrapage iOS 1.10.0 (feature 0080) on Android. Android writes only `details` today (BookViewModel.commitNotes → updateDetails).
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0080](../wiki/features/0080-a-private-note-on-my-copy.md) to `Recit_Android/`. The iOS doc is the spec; only the Android specifics are settled here.

- **Data.** `ItemDto.notes: String?` (`network/dto/InventoryDtos.kt`), `InventoryItemEntity.notes: String = ""` (`data/db/Entities.kt`), a DAO setter beside `setDetails`. Room goes from version 2 to 3 by `AutoMigration(2, 3)` (`data/db/AppDatabase.kt`), schema 3 exported to `app/schemas/`.
- **Merge** (`data/model/Merges.kt`): insert sets `notes = dto.notes.orEmpty()`, update `notes = dto.notes ?: existing.notes` — a friend's item or a sparse payload never wipes my note, as `details`.
- **Write.** Same path as the Commentaire: `PUT /api/items/bulk-update` with `attribute: "notes"`, optimistic through `OptimisticRunner`, early return when unchanged, revert only if the stored value is still the new one, error to `ErrorReporter` → SnackBar. `updateDetails` becomes one function over an attribute (`details` | `notes`) rather than a copy.
- **Writes of one field on one book leave one after the other** (iOS `lastTextWrites`): a write waits for the server's answer to the previous one on the same item + attribute, so the older text never lands last.
- **UI.** « Dans mon inventaire » (`BookScreen.myCopy()`): « Ce que j'en pense », then « Ce que je garde pour moi » (placeholder « Écrire une note privée »), then the date / mode d'échange row. The autosaving cell (`MyNotesCell`: 1 s pause, focus loss, dispose) is shared by both fields, not duplicated. Commit runs on `backgroundScope` like `commitNotes`.
- **Nowhere else.** Not on `CommunityItemRow`, not on a book row, not in Recherche. A book I don't own has no « Dans mon inventaire », as now.
- French strings only (Android has no English values). Commentaire's French label unchanged.
- Out of scope: a note emptied on the website coming back without `notes` (kept, as `details`).

## Acceptance criteria

- On my copy's Fiche livre, « Dans mon inventaire » shows « Ce que j'en pense », then « Ce que je garde pour moi » with the placeholder « Écrire une note privée », then the date row.
- Typing a note, waiting 1 s, leaving and reopening the book: the note is there; after an app restart it is still there.
- The request sent is `PUT /api/items/bulk-update` with `attribute: "notes"` and the item id; `details` is not sent.
- Server refuses (unit test with a failing API): the field goes back to the previous note and the SnackBar shows; a note typed after the failed one is not overwritten.
- Two writes of the note on the same book: the second request starts only after the first answered (unit test).
- A friend's copy of the same book shows its Commentaire, never a private note.
- An app installed with database version 2 upgrades to 3 without losing items (AutoMigration test or schema check).
- A sync payload without `notes` keeps the local note (merge unit test).

## Implementation

- Data: `ItemDto.notes: String? = null`; `InventoryItemEntity.notes` (`@ColumnInfo(defaultValue = "")`); `ItemDao.setNotes`; Room version 3 by `AutoMigration(2, 3)`, `schemas/…/3.json` generated; `Merges.kt` insert `dto.notes.orEmpty()`, update `dto.notes ?: existing.notes`.
- New `data/inventory/`: `InventoryItemTextAttribute` (`Details("details")` | `Notes("notes")`), `InventoryItemTextStore` (+ `RoomInventoryItemTextStore`), `InventoryItemTextWriter` — the one optimistic write path, port of iOS `updateItemTextOptimistic`: last `Job` per (item, attribute) under a `Mutex`, each request joins the previous one; local apply immediate; early return when unchanged or item gone; revert only if the stored text is still the refused one; error to `ErrorReporter`. `ItemBulkUpdate.kt`: `ApiService.bulkUpdateItem`, shared with `updateTransaction`.
- `InventoryRepository.updateText(itemId, attribute, text)` replaces `updateDetails` / `bulkUpdate`; `BookViewModel.commitText` on `backgroundScope`.
- UI: `MyNotesCell` → `MyCopyTextCell(row, attribute, onCommit)` shared by both fields; `myCopy()` shows « Ce que j'en pense », « Ce que je garde pour moi » (placeholder « Écrire une note privée »), then the date row. `CommunityItemRow` untouched (reads `details` only).
- Tests: `InventoryItemTextWriterTest` (MockWebServer, 6: exact body with `attribute: notes`, details still `details`, nothing sent unchanged / item gone, refusal reverts + reports, stale refusal keeps newer note, second request waits for the first — fails with the `join()` removed), `InMemoryInventoryItemTextStore`, `AppDatabaseSchemaTest` (3.json = 2.json + `inventory_items.notes` NOT NULL default `''`; no MigrationTestHelper, which needs instrumented tests), `MergesTest` note merge.
- Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest --rerun-tasks` ✅ 0 failures. `EntityCreationRepositoryEntityTest.aWikidataWorkOrAnEditionIsNotOpened` failed once (404 from MockWebServer) on a first full run, then passed: looks flaky, unrelated.
- Runtime not run: no inventaire.io credentials for the agent.
- Round 1 (feedback): `BookScreen.myCopy()` — the date row's `LazyColumn` key `mine-details:<id>` → `mine-transaction:<id>`. `inline`.

## Review

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

round 1: manual validation — not run by agent · run: yours

## Feedback

### Round 1 — 2026-11-10

- **Asked:** « l'App n'arrête pas de crash sur le simulateur, corrige »
- **Cause:** `IllegalArgumentException: Key "mine-details:<id>" was already used` (emulator crash buffer). The Commentaire cell's key is `mine-${attribute.raw}:<id>`, and `InventoryItemTextAttribute.Details.raw` is `details`, so it collided with the date row's `mine-details:<id>`: every Fiche livre of a book I own crashed. Also explains e2e step 12 (« l'écran du livre n'est pas apparu »).
- **Triage:** defect — the first criterion (« Dans mon inventaire » shows both fields then the date row) never held at runtime. Criteria unchanged.
- **Change:** `ui/book/BookScreen.kt` — date row key `mine-transaction:<id>`. `inline`.
- **Build / tests:** `./gradlew :app:assembleDebug :app:testDebugUnitTest` ✅ 608 tests, 0 failures.
- **Review:** deferred → `/wa-validate`.
- **Verify:** manual — run: yours.
- **Rule captured:** none.
