---
issue: 141
status: to-close
wiki: [[features/0092-entity-deep-links]], [[lists]], [[features/0079-the-lists-a-book-is-in]], [[features/0068-lists-in-my-network]]
note: Third task of the « Deep links » sprint. Builds on #140, which teaches TabRouter to push a link on a given tab. Split from #65.
created: 2026-11-16
---

## Context / Decisions

> Lien /lists/<id> → la liste ; un élément de liste → la liste ouverte sur ce livre (NavigationDestination.entityList(id:focusURI:) existe). Forme du lien d'un élément à choisir pour que la redirection inventaire.io tombe sur une vraie page. Onglet Listes. Listes d'un·e ami·e en lecture seule. Issu du découpage de #65.

A link to a list, or to one book in a list, opens that list in Ex-libris, on the Listes tab. Without the app, the link lands on the same page on inventaire.io.

1. **Two paths, inventaire.io's own** (its web client routes them, `listings.ts`):
   - `https://link.exlibris.lunabee.ovh/lists/<id>` → the list, on its first element;
   - `https://link.exlibris.lunabee.ovh/lists/<id>/element/<elementId>` → the list, on that element.
   - The server's catch-all `302` already sends both to inventaire.io: only the app side and the verification files change.
2. **Strict match, as in #138.** `<id>` and `<elementId>` are CouchDB ids: whole match on `[0-9a-f]{32}` (check the length on a real list before fixing it), or the URL is not a link.
3. **On an element: the arrival of « Dans les listes »** (feature 0079): `NavigationDestination.entityList(id:focusURI:)` with the element's entity uri, so the list springs from its first book to that one with the tinted halo. The element is found by its `_id` among the list's elements. An element that is no longer in the list → the list on its first element.
4. **A list the store does not hold** (a stranger's public list, or a friend's not synced yet) is loaded first: `GET /api/lists/by-ids?ids=<id>&with-elements=true`, upserted with its `creatorId`, its creator fetched through `UserModel.getOrFetchUsers`. It opens read-only, like a friend's list. It shows neither in « Mes listes » nor in « Dans mon réseau », which keeps friends' lists only (`ListsTabSections`).
5. **My own list** opens as from « Mes listes », editable.
6. **Where it opens: the Listes tab**, pushed alone above its root, through the per-tab push of #140.
7. **Fallback**: unknown list, a list I may not see (`by-ids` answers `404` or nothing), or no network → the same page on inventaire.io in the browser, as in #138.
8. **Server**: `scripts/deeplinks/apple-app-site-association` gains `/lists/*`, then `scripts/deeplinks/deploy.sh`. `assetlinks.json` unchanged.
9. **Android**: same rules. The manifest gains `pathPrefix` `/lists/`; `MainScaffold` pushes `Destination.EntityList(id, focusUri)` on `AppTab.Lists`'s stack; the list is loaded through `ListRepository` when Room does not hold it.
10. **Where it lives**: `DeepLink` (iOS `Model/DeepLink/`, Android `ui/navigation/DeepLink.kt`) gains the two cases; the load goes in `ListModel` / `ListRepository`; the mapping stays in `NavigationDestination+DeepLink.swift` and `DeepLinkHandling`.

### Out of scope

- A link opened signed out, or under an open sheet: #143.
- « Partager » on a list or an element: #144.
- Showing a stranger's lists anywhere but the screen the link opens.

## Acceptance criteria

- `curl -s https://link.exlibris.lunabee.ovh/.well-known/apple-app-site-association` lists `/lists/*` with the paths of #138 and #140.
- `curl -i https://link.exlibris.lunabee.ovh/lists/<id>/element/<elementId>` → `302` to the same path on `https://inventaire.io`.
- iOS, signed in, link touched from another app:
  - `/lists/<one of my lists>` → Listes, my list, editable, on its first element;
  - `/lists/<a friend's list>/element/<its 3rd element>` → Listes, the list springing to that book with the halo, read-only;
  - `/lists/<a stranger's public list>` → Listes, the list read-only; the Listes tab's root does not show it afterwards;
  - `/lists/<id>/element/<an element removed since>` → the list on its first element;
  - `/lists/<unknown id>` → inventaire.io in Safari;
  - `/lists/<id>%7C<id>` and `/lists/<id>/element/a%26b` → not opened by the app.
- Android emulator, `adb shell am start -a android.intent.action.VIEW -d <link>` with the same links → the same results.
- Unit tests: the parser accepts both shapes and refuses the decoded `|` / `&` cases, on both platforms; an element id maps to its entity uri, and a missing one to the first element.

## Implementation

Autopilot round 1, 2026-11-16.

- iOS
  - `DeepLink`: `.list(id:elementId:)`, ids whole match `[0-9a-f]{32}` (checked on real lists and elements); `init?(url:)` split into `list(at:)` / `page(at:)`.
  - `AppModels/List/ListModel+DeepLink.swift` (new): `storedList(id:)`, `fetchList(id:)` → `by-ids?ids=&with-elements=true`, upsert of that list alone (no deleteMissing); no `creator` in the answer → not stored (an unstamped list passes for mine). `ListsByIdDTO.swift` (new): `{ lists: [id: ListDTO] }`.
  - `ListModel.swift`: `apiService` internal for the extension; `creatorsPerRequest` moved to the top, fixing its baselined `type_contents_order` (baseline entry now stale, left in place).
  - `NavigationDestination(linkedList:elementId:)`: element `_id` → its `uri` as `focusURI`, missing → nil (first element).
  - `DeepLinkHandling`: store first, else `fetchList`, creator via `getOrFetchUsers` (`try?`), `router.open(…, on: .lists)`. `EntityListView`: `.opensPendingLink(on: .lists, path:)`.
- Android
  - `DeepLink.EntityList(id, elementId)` (not `List`: shadows `kotlin.collections.List`), `listDestination(list, elementId)` pure.
  - `ListRepository.storedList(id)`, `fetchList(id)` (skipped without creator, `Merges.list` + `mergeElements` in one transaction, no pruning). `ListsByIdDto`. Manifest `pathPrefix="/lists/"`.
- Server: AASA file gains `/lists/*`. Not deployed.
- Decisions
  - A stored list linked on an element added since its last sync opens on its first element (no refetch).
  - A stranger's list stays in the store until sign-out, like one opened from their profile; `ListsTabSections` shows it nowhere (no filter change needed).
- Proof
  - iOS build green; DeepLinkTests 10, TabRouterTests, LinkedListTests 6: all pass.
  - Android build green; DeepLinkTest 12/12, TabRouterTest 9/9.

## Review

### Round validation — 2026-11-16

Rebased onto `sprint/deep-links` after #140 landed (PR #147); no longer stacked. Spec validated by Olivier on his iPhone.

LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓. Two 🟡, both fixed by autofix round 1, re-verified clean:
- 🟡 `ListModel+DeepLink.swift:45` [structure] upsert closures duplicated `syncLists`' → `ListModel+Upsert.swift` (new) `upsertLists(_:deleteMissing:scope:modelContext:)`, used by both; `syncLists` keeps `deleteMissing: true` + creator scope, `fetchList` no deletion. Class body now 249 lines: the `type_body_length` baseline entry (255) is unused, baseline untouched.
- 🟡 Android `DeepLink.kt:120` [correctness] `runCatching` swallowed `CancellationException` → try/catch rethrowing it.

Proof after autofix: iOS build green, DeepLinkTests + LinkedListTests + TabRouterTests pass; Android build green, DeepLinkTest 12, TabRouterTest 9.

## Verification

Agent, iPhone 17 simulator, signed in:
- ✅ launch; `/entity/isbn:9782070360024` still opens on Recherche.
- ✅ `/lists/<id>` → Safari on inventaire.io's list page (AASA not deployed); server `302` checked for `/lists/<id>/element/<eid>`.
- ❌ Listes tab not tapped through, list links not opened in app on screen: unit tests only.
- Android: no emulator, build + unit tests only.

## Feedback
