# Where to find a book, on a Liste

Shipped on 2026-11-07, iOS only (issue #81, PR #84, five feedback rounds tested on Olivier's iPhone, then a review
round). A Liste of works said which books were in it, never how to get them. The selected element now ends on « Où
trouver ce livre ? »: the friends who own the work, then two bookshops.
The Figma maquette is `B3 · Liste · Où trouver ce livre ?` (`992:1760`, page `Liste`), with the components
`Cell / External Link` (`994:688`) and `Brand / Logo` (`994:680`) — see
[figma-library.md](../design-system/figma-library.md), proposal of 2026-11-07.

## What it does

- **Where.** On a Liste of works, mine or a friend's, after the selected element's comment and actions. Lists of
  authors and publishers have no such section. The section cross-fades with the cover in front, like the rows above.
- **« Ajouté le … »** moved with it: right under the title + author block, 2 pt below, no longer the footer of
  « Retirer de la liste ». A friend's element without comment no longer shows an empty card.
- **One card.** The section header « Où trouver ce livre ? », then:
  - **My friends' copies** of the work, any edition, read from the store — no network call. Each is the Fiche livre's
    community row: picture, pseudo, since when, status. A touch opens the Profil d'un ami.
  - **A long press** offers « Emprunter à X », « Acheter à X » or « Récupérer de X » by the copy's status, which
    opens the request sheet; « X ne prête pas ce livre pour le moment », greyed, for an Inventorié copy; « Ce livre
    est dans votre inventaire », greyed, when I own that same edition. Same menu on the Fiche livre's « Dans la
    communauté ».
  - **« Trouver sur Recyclivre »** (« Pour l'acheter d'occasion ») and **« Trouver sur Chez mon libraire »** (« Pour
    le réserver dans une librairie indépendante près de chez vous »): the site's logo, title, subtitle and an
    `arrow.up.right` in the chevrons' colour. A touch opens Safari on the site's search for the work's title and its
    first author.
- No friend owns it → only the two links.

## Technical surface

- `Features/Lists/ListWhereToFindSection.swift` — the section; `Bookshop+Link.swift` — each site's title, subtitle,
  logo and accessibility id. Wired in `ListElementsPage` (last section, `list.type == .work`); `ListCoverFlowScreen`
  pushes `NavigationDestination.user` and presents the request sheet, since the page lives in `TabPager`'s own
  hosting controller.
- **Friends' copies.** The Work by uri, then `editions → items`, `ownerId ≠ me`, an owner, `isStillInTheStore`, sorted
  by pseudo. Every user's inventory sync links an item's edition to its work (`InventoryModel.syncItems(ofWork:)` →
  `mergeWorks`), so no fallback query. Walking a work's editions faults each one; not measured on a work with
  thousands of editions in the store.
- **The request rule.** `Model/Transaction/TransactionRequestRule.swift`, pure and tested: a friend's copy may be
  asked for unless I own a copy of that same edition — the Fiche livre's rule, copy by copy, on both screens. A first
  version hid the request as soon as I owned any edition of the work, and the menu came up empty (round 3).
- **Shared with the Fiche livre.** `Features/Components/FriendItemRow.swift` — the row and its menu,
  `.requestOffered(_:)`; `Features/Transactions/TransactionRequestSheet.swift` — the request form. `BookActions`,
  `UserDetailView` and `UserInventoryTab` still build their own copies.
- **Links.** `Model/Books/Bookshop.swift` builds `https://www.recyclivre.com/search?q=…` and
  `https://www.chez-mon-libraire.fr/listeliv.php?mots_recherche=…` with `URLComponents`, title + first author,
  trimmed, `+` encoded (`BookshopTests`). Never an ISBN: a list knows the work, not the edition. `ExternalLinkRow` is
  a SwiftUI `Link`; its logo (`ExternalLinkLogo`) is 28 pt in a 36-pt column, so titles start at 60 like the pseudos.
- **Colours and lines.** `foregroundDisclosure` (`UIColor.tertiaryLabel`, the system chevron) is a code-only token.
  Every separator of the card starts at 12 pt (`listRowSeparatorLeading`); before, they followed the avatar's
  initials.
- **Assets.** `BookshopRecyclivre` and `BookshopChezMonLibraire`, the sites' public touch icons, the second cropped
  of its white margins. No brand files; the sites' deep-link terms not read.

## Not done

- Recyclivre's search address never checked by a script (Cloudflare 403); Olivier tested it on his iPhone.
- The local store keeps copies removed on inventaire.io (`syncInventory` never prunes), which can wrongly show « Ce
  livre est dans votre inventaire ».
- Android not ported. e2e not run.
