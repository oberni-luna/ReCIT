# Ex-libris on Android, reviewed and redressed

Shipped on 2026-10-16 on the `android-revue-visuelle` branch. A screen-by-screen review of the
Android app (feature 0031) found 53 problems. Olivier validated 46 of them, set 6 aside and left one
open. This document covers what changed. The app was run signed in for the first time, on a Pixel 8
emulator (API 35) with the test account `OlivierB_test4`.

Numbered 0036 because 0035 is taken on the unmerged `reseau-graphe` branch.

## What it does now

**Four bugs found on the way:**

- **Opening a book from the inventaire.io search always failed.** Every work and every author showed
  « Impossible d'ouvrir ce livre ». `lastrevid` was decoded as an `Int`, and Wikidata revision ids
  passed 2³¹ in 2025 (Les Misérables is at 2 551 707 872). The column is now a `Long`. SQLite stores
  both as `INTEGER`, so the schema and the Room identity hash are unchanged and no migration is
  needed. Swift's `Int` is 64-bit, which is why iOS never hit it.
- **No Wikimedia image ever loaded.** That meant every author portrait and every Commons cover.
  Commons answers `403` to OkHttp's default `okhttp/x.y` user agent. Every request now says
  `Ex-libris/<version> (Android)`.
- **A cold start waited for the network before showing the cache.** `myUserId` was only set when
  `GET /api/user` answered, so the inventory showed « Synchronisation de vos données… » full screen
  for several seconds. The id is now remembered in preferences (`session.myUserId`) and restored at
  the start of `SessionCoordinator.refresh()`. It is cleared with the rest of the user on sign-out.
- **« 0 œuvres ».** Plural rules follow the device's language, and on an English phone 0 is
  `other`. An empty list now says « Vide ».

**Across the app:**

- **An app icon.** It is the books-on-a-shelf illustration of `ReCIT_iOS/Resources/AppIcon.icon` on
  its cream gradient, as an adaptive icon with a monochrome layer. It also appears on the splash.
- **One surface per screen.** Every screen sits on `backgroundDefault`, top bar included. The bar
  takes `backgroundSecondary` only once content scrolls under it.
- **Lists run full width.** iOS's inset-grouped cards (Réseau, Profil, a reader's page) are gone,
  and `SectionCard` is now a plain column.
- **One component per job:**
  - `RecitSearchField` is the one search field;
  - `BookRow` is the one book row: 2:3 cover, title, authors, a grey subtitle line, then a footer
    only when the state is worth saying (« Inventorié » is not);
  - `SheetHeader`, `FormTextField` and `DestructiveTextButton` make every form sheet the same;
  - `ConfirmDialog` puts « Annuler » and the red verb side by side.
- **Initials instead of empty discs.** `CellThumbnail(fallbackName:)` draws initials whenever a
  portrait is missing or fails to load.
- **Red means destruction only.** « Se déconnecter » is neutral, and « Supprimer ce livre » in the
  « … » menu is red.
- **Snackbars can act.** Filing a book on an étagère or in a list offers « Voir ». The snackbar sits
  on the inverse background.

**Screen by screen:**

- **Welcome.** It has the drifting wall of covers of feature 0013: the books last published on
  inventaire.io, painted jackets until they arrive, frozen when system animations are off.
- **Account screens.** The bar is transparent on the green. The button follows the last field
  instead of being pinned over the form. Errors are light text after a red glyph. A disabled button
  is the same button, faded.
- **Inventaire.**
  - The search field no longer adds a status-bar inset under the top bar.
  - A shelf card is as tall as its covers.
  - The current card is centred, and a new étagère is scrolled to.
  - An empty plank carries an « Ajouter des livres » tag, and « no étagère yet » carries
    « Créer une étagère ».
- **An étagère.**
  - Its header says how many books it holds and who sees it.
  - A new sheet, `AddBooksToShelfSheet`, fills it from my inventory, one tap per book. Before, a
    book could only reach an étagère one at a time from its « … » menu.
  - An empty étagère says so, and offers that sheet.
- **A book.**
  - The blurred cover runs under a see-through bar, which turns opaque, with the title, once the
    header has scrolled away.
  - The notes field has an outline.
  - A submenu of « … » is headed by its name and a way back.
  - An error says whether the network or the answer failed.
- **An author·ice.** The portrait, the name, Wikidata's description and the life dates come first,
  then the works.
- **Listes.** The form asks for the name before the type and says « Créer » / « Enregistrer ». A
  row fans out 48 dp covers. The detail shows the description, the count, and each work's authors.
- **Réseau.**
  - A friend's étagères are the inventory's planks and paper labels, read-only.
  - « 130 livres », not « éléments ».
  - Searching readers adds them with a compact tonal icon, so names stay on one line.
- **Profil.**
  - A portrait or initials, then « 3 livres · 1 étagère · 1 liste ».
  - The inventaire.io tag at the rows' width.
  - A « Compte » section.
  - The version at the foot.
- **Supprimer mon compte.** It uses 16 dp margins and a glyph for each thing lost.
- **Dark mode.**
  - Sheets, menus and dialogs float one step lighter than the screen, through the Android-only
    `backgroundRaised` token.
  - Outlined fields are transparent.
  - The paper labels are cream and a step darker.

## Set aside, by decision

| Item | What it proposed |
|---|---|
| T9 | The person's name instead of « Auteur » / « Utilisateur » as the bar title. The author·ice's name is the page's heading instead. |
| A3 | Tinted fields on the green account screens. They stay light grey. |
| L2 | Hiding « Auteur inconnu » on a book. |
| R2 | One search row per work when I and a friend own the same book. |
| N3 | A pending-requests section on the Réseau tab. |
| N4 | Removing one of the two ways into « Ajouter des amis lecteurs ». |
| S4 | Hiding the lists search under about six lists. Still open. |

## Technical surface

- **New files:**
  - `designsystem/`: `SearchField.kt`, `Forms.kt`, `ConfirmDialog.kt`;
  - `ui/common/BookRow.kt`;
  - `ui/inventory/AddBooksToShelfSheet.kt`;
  - `ui/auth/coverwall/` (`CoverWallGeometry`, `CoverWallCatalog`, `CoverWall`);
  - `data/CoverWallRepository.kt`;
  - `network/dto/RecentPublicDtos.kt`;
  - the launcher resources.
- **Pure geometry.** The cover wall's geometry and catalog are pure Kotlin ports of
  `Model/CoverWall/` and are tested the same way.
- **The wall is read on a clock.** `withFrameNanos` feeds a float state, and each slot reads it in
  `graphicsLayer`, so the drift recomposes nothing.
- **Tests: 114 JVM tests.**
  - New: `CoverWallGeometryTest`, `CoverWallCatalogTest`, `InitialsTest`, and
    `EntityRevisionDecodingTest`, which decodes a real 2 551 707 872 revision.
  - Changed: the shelf-metrics test follows the new card height.

## Divergences from iOS, on purpose

- **`backgroundRaised`.** It is an Android-only semantic colour: `backgroundDefault` in light mode,
  `backgroundSecondary` in dark mode. Material elevation reads the other way round from an iOS
  grouped list.
- **The paper labels darken** in dark mode (`ShelfPalette.LabelPaperDark`). On iOS they stay white.
- **The snackbar sits on the inverse background**, which is the Android convention.
- **Lists run full width** where iOS groups them in inset cards.

## Not done, or not verified

- **The keyboard over the account form.** The emulator's keyboard ran in floating mode, so the
  form was checked on screen but never under a full-height keyboard.
- **No device pass and no TalkBack pass** have been done.
- **Cold starts.** They take 11 to 15 s on this emulator, on `main` as on this branch. That is the
  emulator under load, not a regression, but nothing faster was measured.
- **Shared values in Figma.** The Figma library has not been told about `backgroundRaised` or
  `LabelPaperDark`.
