# « Partager », with an Ex-libris link

Shipped on 2026-11-16, iOS and Android (issue #144, PR #150, fifth task of the « Deep links » sprint, after
[0092](0092-entity-deep-links.md)–[0095](0095-inventory-deep-links.md)). The screens of a book, a work, an author, a
reader, a group, a list, a list's book and an étagère get « Partager », which opens the system share sheet with the
object's link on `link.exlibris.lunabee.ovh` and its name as subject. Seen on the simulator for the Fiche livre only;
Android built and unit-tested, never run on an emulator.

## What it does

- **What each screen shares.**
  - Fiche livre → `/entity/<edition uri>`, always the edition: the link says nothing about whose copy it is. No screen
    shares `/items/<id>`.
  - Œuvre → `/entity/<work uri>`; Auteur·ice → `/entity/<author uri>`.
  - A reader's profile, mine included → `/users/<username>`; a group → `/groups/<slug>`.
  - A list → `/lists/<id>`; a list's selected book → `/lists/<id>/element/<elementId>`; an étagère → `/shelves/<id>`.
- **Where it sits.**
  - First entry of the « … » menu: Fiche livre (its own section), Œuvre (`WorkEditionPicker`), a reader's profile
    (`UserDetailView`, the menu now shown on my own profile too, « Signaler » hidden there), a group (the « … » now
    shown to non-members when the group has a slug).
  - Share icon in the navigation bar (`.primaryAction`): Auteur·ice, a list (`EntityListDetail`), an étagère
    (`ShelfDetailView`).
  - A « Partager » row under « Déplacer dans une autre liste » for a list's selected book; on a friend's list, its own
    section under their comment. Subject: the work's title or the author's name.
  - The Profil sheet has none: my profile shares from `UserDetailView`.
- **No link, no button.**
  - My list or étagère visible to me alone: whoever got the link would see nothing. A friend's always shares, even when
    inventaire.io sends no visibility to non-owners or the store dropped a `group:` key.
  - An object whose link would not parse back (an `optimistic:` id not yet on the server, a group without slug, a
    username outside inventaire.io's rule).
  - The « … » of my own profile hides when it would be empty.
- **Copy.** iOS: the system's « Partager… » (`ShareLink`), no new string. Android: `action_share` « Partager », French
  only like the rest of its strings.

## Technical surface

- **iOS**
  - `DeepLink.url: URL?`: the inverse of `init?(url:)`, built from one `path` that `webURL` shares; returned only if
    parsing it gives the same case back, so a shared link and a parsed one cannot drift.
  - `Features/Components/DeepLinkShareLink.swift`: `ShareLink(item:subject:preview:)`, nothing when `url` is nil.
  - `Shelf.isShareable(isMine:)`, `EntityList.isShareable(isMine:)` (`isMine == false || visibility.isEmpty == false`).
  - `Features/Lists/ListShareRow.swift`; `ListElementReader` (Features/Lists) and `ListElementEntity` (Model/UserData,
    `title`, `byline`), the one source of a list element's title, shared with `ListSelectedTitle`.
  - Identifiers `e2e.*.share`.
- **Android** — `DeepLink.url` from each case's `path`; `ui/common/ShareLink.kt` (`Context.shareLink`: `ACTION_SEND`,
  `EXTRA_TEXT`, `EXTRA_SUBJECT`, `createChooser`; `ShareLinkButton`, `ShareLinkMenuItem`); `ui/lists/ListShareRow.kt`;
  `isShareable(isMine)` on `ShelfEntity` and `EntityListEntity` (mine = `!isReadOnly` for lists).
- **Tests** — round trip of every case (`DeepLinkTests`, `DeepLinkTest`), `SharingVisibilityTests` /
  `SharingVisibilityTest`, `ListElementEntityTests`.

## Known limits

- A list's authors come back from SwiftData in no set order, so a byline's names may change order.
