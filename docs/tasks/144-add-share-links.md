---
issue: 144
status: todo
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

## Review

## Verification

## Feedback
