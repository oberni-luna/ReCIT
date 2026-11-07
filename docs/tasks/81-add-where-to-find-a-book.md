---
issue: 81
status: todo
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

## Review

## Verification

## Feedback
