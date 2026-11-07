---
issue: 81
status: to-test
wiki: [[lists]], [[book-and-editions]], [[network]], [[design-system/figma-library]]
note: Figma B3 · Liste · Où trouver ce livre ? (992:1760, fileKey S7IvC6GvlcUFe5IgbtvQq6)
created: 2026-11-07
---

## Context / Decisions

> « Où trouver ce livre ? » sur l'écran d'une liste (iOS). Sous « Ajouté le … » du livre sélectionné : une section avec, dans une seule carte, les exemplaires de l'œuvre chez mes ami·es (Cell / Owner Item, comme « Dans la communauté » de la Fiche livre), puis deux liens extérieurs « Trouver sur Recyclivre » et « Trouver sur Chez Mon Libraire », logo du site + titre + sous-titre + flèche arrow.up.right, ouverts dans le navigateur.

- **Where**: Liste (`EntityListDetail` → `ListElementsPage`), Livres page, last section, under the footer « Ajouté le … » of the selected element.
  - Lists of works only. Author and publisher lists: no section.
  - My lists and friends' lists alike: the section is about the work, not the list.
  - Cross-fades with the selected element, like the other rows (`ListCrossFade`).
- **Design**: Figma `B3 · Liste · Où trouver ce livre ?` (`992:1760`, page `Liste`), section `992:1795`.
  - Header « Où trouver ce livre ? » (`Section Header`), one card: friends' copies first, then the two links.
  - Components and measures: `docs/wiki/design-system/figma-library.md`, proposal of 2026-11-07, `Cell / External Link` (`994:688`) and `Brand / Logo` (`994:680`).
- **Friends' copies**:
  - Every copy of the work, any edition, owned by someone other than me, read from the store (`@Query` / store relations, no network call).
  - The work's editions → their items; `InventoryItem.workUris` is computed, so not usable in a `#Predicate`.
  - Row = `UserItemCellView`, same as « Dans la communauté » on the Fiche livre.
  - Tap → Profil d'un ami. Long press → the Fiche livre's menu: « Emprunter à X / Acheter à X / Récupérer de X » by the copy's status, disabled « X ne prête pas » for `inventorying`, opening the request sheet. Not offered when I own a copy of the work myself (same rule as the Fiche livre).
  - None → no rows, the two links stay.
- **Links**: search by title + author, never an ISBN. A list knows the work, not the edition; the sites then show every edition they stock.
  - Recyclivre → `https://www.recyclivre.com/search?q=<title author>`. Not verified live (Cloudflare 403 to automated clients): check it on a phone while coding.
  - Chez mon libraire → `https://www.chez-mon-libraire.fr/listeliv.php?mots_recherche=<title author>`.
  - Query = the work's title (in the phone's language, `EntityLabel`) + its first author's name, URL-encoded.
  - Opened in Safari through SwiftUI `Link`. No in-app browser, no UIKit.
- **Copy** (fr / en):
  - Header « Où trouver ce livre ? » / "Where to find this book?"
  - « Trouver sur Recyclivre » · « Pour l'acheter d'occasion » / "Find on Recyclivre" · "To buy it second-hand"
  - « Trouver sur Chez mon libraire » · « Pour le réserver dans une librairie indépendante près de chez vous » / "Find on Chez mon libraire" · "To reserve it at an independent bookshop near you"
- **Logos**: the sites' public icons (favicon / touch icon), already in Figma, exported into `Assets.xcassets`. No brand files from the sites; their deep-link terms not read. Olivier's call, accepted.
- **Code placement**:
  - `Features/Lists/` — the section view (e.g. `ListWhereToFindSection`).
  - `Features/Components/` — the external link row (`Cell / External Link`), reusable.
  - The URL building is a pure value type in `Model/` (e.g. `BookshopSearch`), unit-tested.
- **Out of scope**: Android (later), ISBN deep links, other bookshops, a setting to hide the links.

## Acceptance criteria

- [ ] A list of works, a book selected → « Où trouver ce livre ? » under « Ajouté le … », on my list and on a friend's list.
- [ ] A list of authors → no « Où trouver ce livre ? » section.
- [ ] A work two friends own (any editions) → two rows, avatar, pseudo, status, as on the Fiche livre; my own copy never listed.
- [ ] A work no friend owns → only the two links.
- [ ] Tap a friend's row → Profil d'un ami. Long press, I own no copy → « Emprunter à X » (or Acheter / Récupérer), which opens the request sheet.
- [ ] Swipe to another cover → the section's rows cross-fade to the new work.
- [ ] Tap « Trouver sur Chez mon libraire » for « Petit pays », Gaël Faye → Safari opens their search for « Petit pays Gaël Faye » and lists it.
- [ ] Tap « Trouver sur Recyclivre » for the same work → Safari opens Recyclivre's search results for it.
- [ ] Each link row: site logo 28 pt, title, subtitle, `arrow.up.right`; titles aligned with the friends' pseudos; dark mode readable.
- [ ] Unit tests: the URL builder encodes accents and spaces, and uses title + first author.

## Implementation

Round 1, 2026-11-07, coded in its own worktree (the main checkout is shared with other sessions).

- **Model**: `Model/Books/Bookshop.swift` is a pure enum `recyclivre` / `chezMonLibraire` with `searchURL(title:authorName:)`. It builds the URL with URLComponents, trims both parts, drops an empty author, and encodes `+`. Tested by `Tests/BookshopTests.swift` (5 tests).
- **Section**: `Features/Lists/ListWhereToFindSection.swift`, with `Bookshop+Link.swift` holding each site's title, subtitle and logo.
  - It reads the Work by uri, then walks `editions → items`. It keeps copies with `ownerId ≠ me`, an owner, and `isStillInTheStore`, sorted by username.
  - `InventoryModel.syncItems(ofWork:)` links friends' editions to their work through `mergeWorks`, so no fallback query was needed.
- **Shared with the Fiche livre**:
  - `Features/Components/FriendItemRow.swift` holds the row and its context menu; `.requestOffered(_:)` turns the request on or off.
  - `Features/Transactions/TransactionRequestSheet.swift` holds the request sheet.
  - `BookDetailView.communitySection` now uses both, with the same behaviour.
- **Link row**: `Features/Components/ExternalLinkRow.swift` and `ExternalLinkLogo.swift`. The logo is 28 pt, radius 6, with a `borderDefault` hairline. It sits in a 36-pt column (`ThumbnailSize.small`), so titles start at 60 like the friends' pseudos.
- **Wiring**: `ListElementsPage` adds the section after « Ajouté le … » on lists of works, mine and friends'. `ListCoverFlowScreen` pushes `NavigationDestination.user` and presents `TransactionRequestSheet`.
- **Assets**: two imagesets, `BookshopRecyclivre` (the site's touch icon) and `BookshopChezMonLibraire` (its touch icon, white margins cropped).
- **Strings**: five keys `list.where_to_find.*`, fr and en.
- **Proof**: build green with SwiftLint strict, and `swiftlint lint --strict` passes on the touched files. ReCIT_iOSTests: 1319 cases passed.
- **Notes**:
  - The logo hairline uses the `borderDefault` token, not Figma's 8 % black.
  - Walking the editions costs one fault per edition. This is not measured for a work with thousands of editions in the store.
  - The Chez mon libraire search was checked with curl. Recyclivre was not checked (Cloudflare).
  - The same request sheet is still copied in `BookActions.swift` and `UserDetailView.swift`, and the menu in `UserInventoryTab.swift`. They are left as they are.
  - One baseline entry in `BookDetailView` (`let me`) is now stale.

## Review

## Verification

manual validation — not run by agent

## Feedback
