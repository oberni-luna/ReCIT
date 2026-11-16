---
issue: 142
status: to-close
wiki: [[features/0092-entity-deep-links]], [[shelves]], [[features/0019-a-friends-shared-shelves]], [[features/0089-tabbed-shelf-screen]]
note: Fourth task of the « Deep links » sprint. Builds on #140, which teaches TabRouter to push a link on a given tab. Split from #65.
created: 2026-11-16
---

## Context / Decisions

> Lien /items/<id> → fiche livre sur cet exemplaire (BookAnchor.item) ; /shelves/<id> → l'étagère. Onglet Inventaire, ou le profil de l'ami·e pour sa copie. Visibilité : un exemplaire non visible doit dire quelque chose. Issu du découpage de #65.

A link to a copy of a book or to an étagère opens it in Ex-libris, on the Inventaire tab. Without the app, or for an étagère outside my network, the link lands on the same page on inventaire.io.

1. **Two paths, inventaire.io's own** (its web client routes `/items/:id` and `/shelves/:id`):
   - `https://link.exlibris.lunabee.ovh/items/<id>` → a copy;
   - `https://link.exlibris.lunabee.ovh/shelves/<id>` → an étagère.
   - The server's catch-all `302` already sends both to inventaire.io: only the app side and the verification files change.
2. **Strict match, as in #138**: `<id>` is a whole match on `[0-9a-f]{32}` (check the length on a real item before fixing it), or the URL is not a link.
3. **A copy in the store** (mine, or a friend's) → the Fiche livre anchored on it, `BookAnchor.item`. The Fiche livre already says whose it is and offers « Emprunter à… » on a friend's.
4. **A copy outside the store** (a stranger's public copy) → `GET /api/items/by-ids?ids=<id>` read without storing it, then the Fiche livre of its edition, `BookAnchor.edition(uri:)`, not anchored on the stranger's copy. Nothing about the stranger enters the store.
5. **An étagère in the store** (mine, or a friend's) → `ShelfDetailView`. A friend's étagère not synced yet is loaded first (`GET /api/shelves/by-ids`), with the friend's items it needs.
6. **An étagère of someone outside my network** → inventaire.io in the browser. Opening it in the app would put a stranger's copies in the store, which the local search and « Chez mes amis » read as mine and my friends'.
7. **Where it opens: the Inventaire tab**, pushed alone above its root, through the per-tab push of #140. A friend's copy too: the rule is one tab per kind of link.
8. **Fallback**: unknown id, a copy or étagère I may not see (`by-ids` answers nothing or `404`), or no network → the same page on inventaire.io in the browser, as in #138.
9. **Server**: `scripts/deeplinks/apple-app-site-association` gains `/items/*` and `/shelves/*`, then `scripts/deeplinks/deploy.sh`. `assetlinks.json` unchanged.
10. **Android**: same rules. The manifest gains `pathPrefix` `/items/` and `/shelves/`; `MainScaffold` pushes `Destination.Book(BookAnchor.Item(id))`, `BookAnchor.Edition(uri)` or `Destination.Shelf(id)` on `AppTab.Inventory`'s stack.
11. **Where it lives**: `DeepLink` (iOS `Model/DeepLink/`, Android `ui/navigation/DeepLink.kt`) gains the two cases; the loads go in `InventoryModel` / `ShelfModel` (iOS) and `InventoryRepository` / `ShelfRepository` (Android); the mapping stays in `NavigationDestination+DeepLink.swift` and `DeepLinkHandling`.

### Out of scope

- A link opened signed out, or under an open sheet: #143.
- « Partager » on a copy or an étagère: #144.
- Opening a stranger's étagère in the app.

## Acceptance criteria

- `curl -s https://link.exlibris.lunabee.ovh/.well-known/apple-app-site-association` lists `/items/*` and `/shelves/*` with the paths of #138, #140 and #141.
- `curl -i https://link.exlibris.lunabee.ovh/shelves/<id>` → `302` to the same path on `https://inventaire.io`.
- iOS, signed in, link touched from another app:
  - `/items/<one of my copies>` → Inventaire, the Fiche livre on my copy;
  - `/items/<a friend's copy>` → Inventaire, the Fiche livre on their copy, « Emprunter à… » offered when its status allows;
  - `/items/<a stranger's public copy>` → Inventaire, the Fiche livre of its edition; the local search does not find that copy afterwards;
  - `/shelves/<one of my étagères>` → Inventaire, my étagère, « Ajouter des livres » shown;
  - `/shelves/<a friend's étagère>` → Inventaire, their étagère, read-only;
  - `/shelves/<a stranger's étagère>` → inventaire.io in Safari;
  - `/items/<unknown id>` → inventaire.io in Safari;
  - `/items/<id>%7C<id>` → not opened by the app.
- Android emulator, `adb shell am start -a android.intent.action.VIEW -d <link>` with the same links → the same results.
- Unit tests: the parser accepts both shapes and refuses the decoded `|` / `&` cases, on both platforms; a copy maps to `item` when stored, to `edition` when not; an étagère of a stranger maps to the fallback.

## Implementation

Autopilot round 1, 2026-11-16.

- iOS
  - `DeepLink`: `.item(id:)`, `.shelf(id:)`, parsed in `page(at:)` with `isCouchId` (item and shelf ids: 32 lowercase hex, checked live).
  - `AppModels/Inventory/InventoryModel+DeepLink.swift` (new): `fetchEditionURI(ofItem:)` → `GET /api/items/by-ids?ids=`, stores nothing.
  - `AppModels/Shelf/ShelfModel+DeepLink.swift` (new): `fetchShelf(id:ownedByOneOf:)` → `GET /api/shelves/by-ids?ids=` (`ShelvesResponseDTO`); owner outside the set → nothing stored, nil; else upsert without deleteMissing, then existing `linkItems`.
  - `InventoryModel`/`ShelfModel`: `apiService` internal (ShelfModel's moved below the statics: baseline entry l.34 now unused), `linkItems`/`localShelf` internal.
  - `NavigationDestination.linkedItem(id:…)` / `linkedShelf(id:ownedByOneOf:…)`: static async, stored copy → `.item`, else `.edition(uri:)`, else nil; stored shelf → `.shelf`, else fetch, else nil (fallback).
  - `DeepLinkHandling`: both cases on `.inventory`, owners = me + `friends(modelContext:)`; helper `open(_:on:) -> Bool` keeps cyclomatic complexity under 12. `ShelvesView`: `.opensPendingLink(on: .inventory, …)`.
- Android: `DeepLink.Item`, `DeepLink.Shelf` → `AppTab.Inventory`; `InventoryRepository.isStored`, `fetchEditionUri` (no store); `ShelfRepository.isStored`, `fetchShelf(id, owners)`, membership extracted to private `linkItems`. Manifest `/items/`, `/shelves/`.
- Server: AASA file gains `/items/*`, `/shelves/*`. Not deployed.
- Decisions
  - A friend's shelf not stored opens with the friend's books already in the store; none fetched (they arrive with the friend's inventory sync). Smaller than decision 5's « with the items it needs ».
  - A friend's copy not stored yet opens its edition (decision 4).
  - `with-items` is deprecated server-side (renamed `with-items-ids`); existing `?action=by-ids&with-items=true` calls left unchanged.
- Proof
  - iOS build green; 44 tests pass (DeepLinkTests, TabRouterTests, LinkedListTests, LinkedInventoryItemAndShelfTests 7, ShelfModelTests, ShelfModelAddItemsTests).
  - Android build green; DeepLinkTest 14, TabRouterTest 9.

## Review

### Round validation — 2026-11-16

Rebased onto `sprint/deep-links` after #141 landed (PR #148); no longer stacked. Spec validated by Olivier (sprint-wide go-ahead; retest on the sprint branch to follow).

LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓. Six 🟡, then two rounds of follow-ups on the fixes; all fixed in 3 autofix rounds, re-verified clean:
- [correctness] iOS étagère saved before `linkItems`: a failed book read left an empty étagère stored → `fetchShelf` reads the books first (`fetchItemIds(ofShelves:)`), then upserts, sets `items` and saves once in the caller's context, no await in between. A first fix through a second `ModelContext` was dropped (could leave `InventoryItem.shelves` stale). New test: books unreadable → nil, nothing stored.
- [correctness] Android same partial write → membership fetched first, `upsert` + `replaceItems` in one `db.withTransaction`.
- [structure] one `with-items` request: `fetchItemIds(ofShelves:)` shared by `linkItems` (private again) and `fetchShelf`; ShelfModel.swift kept at 578 lines for its pinned baseline counts. `linkItems` now saves even with no change (harmless).
- [style] ShelfModel instance properties together below the statics; 3 stale `type_contents_order` baseline entries removed.
- [elegance] resolver uses the returned shelf (`shelf.map { .shelf(id: $0._id) }`).
- [style] tests `.init(apiService:)`; Android import order.

Proof after autofix: iOS build green, DeepLinkTests, LinkedInventoryItemAndShelfTests, ShelfModelTests, ShelfModelAddItemsTests, LinkedListTests, TabRouterTests pass; Android build green, DeepLinkTest, TabRouterTest pass.

## Verification

Agent, iPhone 17 simulator, signed in:
- ✅ launch on Inventaire (carousel, « Tous les livres · 7 »).
- ✅ `/entity/isbn:9782070360024` → Fiche livre on Recherche.
- ❌ `/items/…`, `/shelves/…` not opened on screen: AASA not deployed. Unit tests only.
- Android: no emulator, build + unit tests only.

## Feedback
