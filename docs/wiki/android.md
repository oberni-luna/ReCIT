# Android

`Recit_Android/`: Room + Compose + Navigation 3, a port of the iOS app. Each feature doc says what was ported and what was not.

## Code

- `Recit_Android/`
- [integrations/google-play.md](integrations/google-play.md)

## Features

- [0031 Ex-libris on Android](features/0031-android-app.md) — `Recit_Android/`, Room + Compose + Navigation 3: account, inventory and shelves, search, book, lists, friends, profile; scanner, sorting, transactions and groups not ported; first run signed in during 0036
- [0041 Android catches up with iOS](features/0041-android-catches-up-with-ios.md) — on `Recit_Android/`: authors on every row, À propos and the version (no donations), the Profil behind the avatar as a full-height overlay, a Recherche tab with « Chez mes amis », black behind the tabs' lists with a third token for the cells; never seen signed in
- [0042 Scanning and sorting books, on Android](features/0042-android-scan-and-sort.md) — CameraX + ML Kit batch scanner and « Ranger mes livres » by hand in one full-screen flow, the bilan between them; the drag is the app's own; no proposal, no book creation; never run on a device
- [0043 Creating a book inventaire.io lacks, on Android](features/0043-android-create-a-missing-book.md) — the scanner's unknown row opens « Nouveau livre »: title, author picked or created, cover by the camera app, dry run then `resolve`, filed and counted; drafts by ISBN; never run on a device
- [0044 Ex-libris on Android, reviewed and redressed](features/0044-android-visual-review.md) — a screen-by-screen review, 46 fixes: books from search open again (`lastrevid` is a `Long`), Wikimedia images load (a named user agent), the cache shows before the network; an app icon, one surface per screen, one book row, one search field, one sheet; the welcome wall of covers; an étagère filled from itself
- [0046 Groups on Android](features/0046-android-groups.md) — Réseau gets Amis | Groupes: invitations, my groups with the admin tag and the red dot, sent requests; a group's screen by role, members, invite, find, create, settings; held in memory like iOS 0028, synced after the relations; never seen signed in
- [0052 The cover full screen, editions added and edited, a book row's long press — on Android](features/0052-android-cover-zoom-edition-editing-context-menu.md) — on `Recit_Android/`: iOS 0029's cover zoom from the entity header; the book's « … » menu on a long press of every `InventoryItemRow`; « Données bibliographiques › Modifier l'édition » with every property, works and « Modifier l'œuvre », saved server-first, a retry sending only the rest; the scanner's « Nouveau livre » work-first with the same form in creation; `_score` read at last; never run on a device, nothing written to inventaire.io
- [0062 Android catches up with iOS 1.7.0](features/0062-android-catches-up-with-1-7-0.md) — on `Recit_Android/`: red removal swipes, an ISBN in Recherche opening its edition, « Éditions » by language and filled batch by batch, the section spinner, a list as a cover flow with its comment, « Ajouter un livre » by search and by scan, « Déplacer dans une autre liste »; seen only in a throwaway harness, never signed in, nothing written to inventaire.io
- [0072 Asking a friend for a book, on Android](features/0072-android-transaction-request.md) — « Emprunter à / Acheter à / Récupérer de X » on a friend's copy, in the book's « … » and a row's long press; a full-height form with one sentence for the type and a required message; `POST /api/transactions/request` with `{ item, message }`; the rest of the transactions not ported; never sent for real, not seen running
