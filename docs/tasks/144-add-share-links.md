---
issue: 144
status: to-test
wiki: [[features/0092-entity-deep-links]], [[book-and-editions]], [[lists]], [[network]], [[shelves]]
note: Last task of the « Deep links » sprint. Builds on #140, #141 and #142: every link it shares must already open in the app. Split from #65 (decision 6).
created: 2026-11-16
---

## Context / Decisions

> « Partager » dans les menus « … » de la fiche livre, de l'auteur·ice, d'un profil, d'un groupe, d'une liste, d'un élément de liste, d'une étagère : feuille de partage système avec le lien link.exlibris.lunabee.ovh et le nom de l'objet. iOS et Android. Issu de #65 (décision 6).

« Partager » on the screens that show a book, a person, a group, a list or an étagère opens the system share sheet with its Ex-libris link, which opens that screen in Ex-libris or on inventaire.io.

1. **What each screen shares**:
   - Fiche livre → `/entity/<edition uri>`, always the edition: the link says nothing about whose copy it is. No screen shares `/items/<id>`.
   - Œuvre (`WorkActions`) → `/entity/<work uri>`.
   - Auteur·ice → `/entity/<author uri>`.
   - A reader's profile, mine included → `/users/<username>`.
   - A group → `/groups/<slug>`.
   - A list → `/lists/<id>`.
   - A list's element (cover flow) → `/lists/<id>/element/<elementId>`.
   - An étagère → `/shelves/<id>`.
2. **One place builds the links**: `DeepLink` gains the inverse of its parser (case → URL), on iOS and Android, so a shared link and a parsed one cannot drift apart. Unit-tested as a round trip: every case built then parsed gives itself back.
3. **Where « Partager » sits**:
   - In the « … » menu where the screen has one: Fiche livre (`BookActions`), Œuvre (`WorkActions`), profile (`UserDetailView`), group (`GroupDetailView`).
   - Else the system share icon in the navigation bar, beside what is already there: Auteur·ice, list (`EntityListDetail`), étagère (`ShelfDetailView`).
   - A list's element: a « Partager » row under « Déplacer dans une autre liste ».
4. **Nothing to share, no button.** A list or an étagère visible to me alone has no « Partager »: whoever receives the link would see nothing, in the app or on inventaire.io. An object anyone else may see (friends, groups, everyone) has one.
5. **What the sheet carries**: the URL, with the object's name as subject (title of the book, name of the person, the group, the list or the étagère). iOS: `ShareLink(item:subject:preview:)`. Android: `Intent.ACTION_SEND`, `EXTRA_TEXT` = the URL, `EXTRA_SUBJECT` = the name, through `Intent.createChooser`.
6. **Copy**: « Partager », as the system says it. No other string.
7. **Android**: the same screens and rules, in their « … » menus or top bars.

### Out of scope

- Sharing a copy (`/items/<id>`).
- A QR code, a short link, or text written around the link.

## Acceptance criteria

- iOS, Fiche livre « … » → « Partager » → the share sheet with `https://link.exlibris.lunabee.ovh/entity/<the edition's uri>` and the book's title; sent to Notes and touched → the same Fiche livre.
- iOS, the same from: an œuvre, an auteur·ice (navigation bar), a friend's profile, my own profile, a group, a list I share with friends, an element of a list, a friend's étagère: each link, touched, opens that screen.
- iOS, a list and an étagère visible to me alone → no « Partager ».
- Android, the same screens → the system chooser with the same link and subject.
- Unit tests: for every `DeepLink` case, building the URL then parsing it gives the same case, on both platforms.

## Implementation

stacked on: wa/142-add-inventory-deep-links @ f00bcdb5

Autopilot round 1, 2026-11-16.

- Builder
  - iOS `DeepLink.url: URL?` (URLComponents), Android `DeepLink.url: String?` (`URI.toASCIIString()`), both from one `path` that `webURL` shares. Returns the URL only when parsing it gives the same case back → round trip by construction; `optimistic:` ids, usernames outside the rule, a group without slug → nil → no button.
  - Round-trip tests on 11 samples incl. `Anaïs`, `lecture-à-chambéry` (`users/Ana%C3%AFs`), both platforms.
- Private rule: `EntityList.isVisibleToCreatorAlone`, `Shelf.isVisibleToOwnerAlone` (`visibility` empty); any key counts as shared. Edge: iOS store drops `group:<id>` keys on decode, so a list shared with one group only reads as private (no button).
- iOS placements
  - `Features/Components/DeepLinkShareLink.swift` (new): `ShareLink(item:subject:preview:)`, system label (« Partager… »), nothing when `url` is nil.
  - Fiche livre: first entry of the « … » (own Section), `/entity/<edition uri>`, title as subject. Not added to book rows' long press.
  - Œuvre: first entry of `WorkEditionPicker`'s « … » (`workActions` takes `title:`).
  - Auteur·ice, list (`EntityListDetail`), étagère (`ShelfDetailView`): share icon at `.primaryAction`.
  - `UserDetailView`: « Partager » first; the « … » now shows on my own profile too (only entry; « Signaler » hidden for me). Profil sheet (`ProfileView`) unchanged.
  - Group: « Partager » first; the « … » also shows for non-members when the group has a slug.
  - List element: `ListShareRow.swift` (new) under « Déplacer… » on my lists; own section under the comment on a friend's list. Subject = work title or author name.
  - New identifiers `e2e.*.share`; re-indented baselined literals (`e2e.user.menu`/`report`, `e2e.group.menu`/`settings`/`leave`) moved to constants, baseline entries now stale.
- Android: `ui/common/ShareLink.kt` (new: `Context.shareLink`, `ShareLinkButton`, `ShareLinkMenuItem`), `ui/lists/ListShareRow.kt` (new), `MoreActionsMenu.shareMenuLine`; same placements; `UserMenu` always shows. `strings.xml` `action_share` « Partager » (no English catalogue on Android).
- Proof
  - iOS build green; 47 tests pass (DeepLinkTests, TabRouterTests, LinkedListTests, LinkedInventoryItemAndShelfTests, SharingVisibilityTests, ListVisibilityTests).
  - Android build green; DeepLinkTest 17, SharingVisibilityTest 2, TabRouterTest 9, AppDatabaseSchemaTest 1.

## Review

## Verification

Implementer had no UI automation. PM check, iPhone 17 simulator, signed in:
- ✅ `/entity/isbn:9782070360024` → Fiche livre; « … » shows « Partager… » first, then Liste, Ajouter à l'inventaire.
- ✅ « Partager… » → share sheet titled « L'étranger ».
- ❌ link text in the sheet not read (copy to pasteboard did not land). URL proven by round-trip tests.
- ❌ other screens (œuvre, auteur·ice, profile, group, list, element, étagère) not seen.
- Android: no emulator, build + unit tests only.

## Feedback
