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
  - Tap → Profil d'un ami. Long press → the Fiche livre's menu: « Emprunter à X / Acheter à X / Récupérer de X » by the copy's status, disabled « X ne prête pas » for `inventorying`, opening the request sheet. Not offered when I own a copy of that same edition (the Fiche livre's rule, copy by copy — round 3: « any edition of the work » hid the menu).
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

- [ ] A list of works, a book selected → « Où trouver ce livre ? » as the last section, on my list and on a friend's list.
- [ ] Any list, a book selected → « Ajouté le … » sits 2 pt under the title + author block (Figma `1000:31633`), no longer as the footer of « Retirer de la liste »; a friend's element without comment shows no empty card.
- [ ] A list of authors → no « Où trouver ce livre ? » section.
- [ ] A work two friends own (any editions) → two rows, avatar, pseudo, status, as on the Fiche livre; my own copy never listed.
- [ ] A work no friend owns → only the two links.
- [ ] Tap a friend's row → Profil d'un ami. Long press, I own no copy of that edition → « Emprunter à X » (or Acheter / Récupérer by status, disabled « X ne prête pas » for Inventorié), which opens the request sheet.
- [ ] Long press on a friend's copy of an edition I own → one disabled entry « Ce livre est dans votre inventaire », on the Liste and the Fiche livre.
- [ ] The link rows' `arrow.up.right` has the exact colour of the friend rows' chevrons, light and dark.
- [ ] Every separator of the card, friend rows and link rows, starts at the same x.
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

### Round 2 — 2026-11-07

- **Asked**: « la date d'ajout à la liste devrait être beaucoup plus proche du bloc titre + auteur, j'ai modifié le Figma ici https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=992-1760, regarde et ajuste le code et la documentation. »
- **Triage**: adjustment. Criteria updated: date position added, section placement reworded.
- **Changes** (`inline`):
  - `ListElementsPage.swift`: « Ajouté le … » moves from the section footers into the title block, under `ListSelectedTitle`, at `.xxSmall` (2 pt), and cross-fades with it. A friend's element without comment drops its now-empty section.
  - `figma-library.md`: the 2026-11-07 proposal records the retouch, the title + author addresses, and the code files of `Cell / External Link` and `Brand / Logo`. This doc and the glossary rows came over from uncommitted edits in the main checkout.
- **Review**: deferred → /wa-validate.
- **Verify**: round 2, manual validation, not run by agent. Installed on Olivier's iPhone.
- **Rule**: none.

### Round 3 — 2026-11-07

- **Asked**: « je voudrais un appuie-long sur les cells de mes ami.e.s avec une entrée "Emprunter à ..." (en fonction du statut) · je veux que les arrows.up.right soient de la même couleur que les chevrons au dessus pour ouvrir le profil des amis · je veux que le séparateur entre "Recyclivre" et "Chez mon libraire" soit aligné sur les autres séparateurs au dessus. »
- **Triage**:
  - Long press: defect.
  - Arrow colour: adjustment.
  - Separator: adjustment.
  - Criteria updated.
- **Changes** (implementer):
  - **Long press**: the menu was empty, not blocked. `iOwnTheWork` was true as soon as any edition of the work held a copy of mine. It is replaced by `Model/Transaction/TransactionRequestRule.swift`, a pure rule decided copy by copy: a friend's copy may be asked for unless I own that same edition. Tested by `TransactionRequestRuleTests` (4 tests). A throwaway XCUITest harness reproduced the bug and ruled out the gestures; it is deleted.
  - **Arrow colour**: new token `foregroundDisclosure` (`UIColor.tertiaryLabel`, the system chevron) in `Color.swift`, used by `ExternalLinkRow`. On screenshots it matches the chevron in light and dark.
  - **Separators**: `.alignmentGuide(.listRowSeparatorLeading)` at `Spacing.sMedium` (12 pt) on the friend rows and link rows, in `ListWhereToFindSection` only. The Fiche livre is untouched.
  - **Docs**: `figma-library.md` records the code-only token and the separator x.
- **Review**: deferred → /wa-validate.
- **Verify**: round 3, manual validation, not run by agent. Build green, 1322 tests passed.
- **Rule**: none.

### Round 4 — 2026-11-07

- **Asked**: « j'ai l'impression que si la liste n'appartient pas à un ami, je n'ai pas le long press, si elle appartient à un ami je l'ai. C'est une limitation de inventaire.io ou un bug ? Les 2 autres points sont bien corrigés. »
- **Triage**: defect to investigate; confirmed: arrow colour and separators.
- **Finding**: no code change. With identical data, my list and a friend's list behave the same. The menu is empty only when I own a copy of the friend's edition (`TransactionRequestRule`, the Fiche livre's rule).
  - Olivier's lists mostly hold works he owns or once owned, often in a single edition, so the rule hides the request there.
  - A local copy can also be stale: `InventoryModel.syncInventory` never prunes items gone from the server.
  - Proof: a throwaway XCUITest harness on the real `ListCoverFlowScreen`, mine vs friend's list, with and without my own copy. It is deleted.
- **Open**: Olivier to say whether he owns that edition, or whether the request should be offered even then.
- **Review**: deferred → /wa-validate.
- **Verify**: round 4, manual validation, not run by agent. Build green, 1324 tests passed.
- **Rule**: none.

### Round 5 — 2026-11-07

- **Asked**: « Garder la règle mais au lieu de ne rien montrer, afficher un message qui dit "Ce livre est dans votre inventaire". »
- **Triage**: adjustment. Criteria updated.
- **Changes** (`inline`):
  - `FriendItemRow.swift`: when the request is not offered, the long press shows a disabled « Ce livre est dans votre inventaire » (`books.vertical`) instead of an empty menu. The row is shared, so the Fiche livre changes too.
  - `Localizable.xcstrings`: `community.book_in_my_inventory`, fr « Ce livre est dans votre inventaire » / en "This book is in your inventory".
- **Review**: deferred → /wa-validate.
- **Verify**: round 5, manual validation, not run by agent. Tests: first run failed on `CreateBookFailureTests`, a file this round does not touch; the rerun passed.
- **Rule**: none.
