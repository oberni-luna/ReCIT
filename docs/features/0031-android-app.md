# Ex-libris on Android

Shipped on 2026-10-02, from PRD 0017 and issues 0102–0107, in an autopilot run, on the
`android-app` branch. A native Android app now lives in `Recit_Android/`, beside the iOS one. It
talks to the same inventaire.io and covers the everyday flows: the account, the inventory and its
shelves, search, a book's screen, lists, friends, and the profile.

## What it does

- **Signed out:** the welcome screen (the green veil, without the drifting wall of covers), then
  sign-in, account creation with live checks of the username and e-mail, and the reset-password
  sheet. A session survives a relaunch.
- **Inventaire:**
  - the first-sync banner and its progress bar;
  - my shelves as a snapping carousel of plank cards, each with its tilted paper label;
  - the empty-shelf card, offering only « Rechercher » (there is no scanner);
  - « Tous les livres ».
  - Shelves can be created, edited, deleted and emptied by swipe.
  - The unified search covers recent searches, local matches mine-first, three suggestions, and
    inventaire.io results for books and authors.
- **A book** opens from a copy, an edition, or a work found in search (its best edition is
  resolved and remembered). It shows:
  - the cover, the Wikipedia summary, the authors and the other editions;
  - who in my network holds it;
  - my copy's notes, saved as I type, and its transaction mode.
  - The « … » menu files a copy on a shelf or a work in a list, new ones included, adds the book to
    my inventory, or removes it.
- **A work** with several editions opens the edition picker. **An author** shows their works.
- **Listes:**
  - lists with their fan of covers and their counts;
  - the empty state that explains a list beside a shelf;
  - creation, editing and deletion, and removing elements.
- **Réseau** (friends only):
  - invitations to answer, and my friends with their first-sync bars;
  - finding a reader and asking them;
  - all pending invitations;
  - a reader's page with their shelves and books, or the relation actions when they are not a
    friend yet.
- **Profil:**
  - the account, and the dismissable inventaire.io paper tag;
  - signing out, which forgets the user and keeps the books;
  - deleting the account, from a screen that counts what it costs.

## How the iOS architecture maps

| iOS | Android |
|---|---|
| SwiftData `@Model`, `@Query` | Room rows (`data/db/Entities.kt`), DAOs returning `Flow` |
| many-to-many relationships | cross-reference tables `edition_works`, `work_authors`, `shelf_items` |
| `*Model` in `AppModels/` | repositories in `data/`, built once in `AppContainer` |
| `init(dto:)` / `update(from:)` | `data/model/Merges.kt`, merged field by field, then `@Upsert` |
| `OptimisticMutating.optimistic` | `OptimisticRunner` (application scope; `stillThere` = `subjects`) |
| `AppErrorReporter` + LBSnackBar | `ErrorReporter` + `Messenger`, one `SnackbarHost` in the shell |
| `RootView` sync order | `SessionCoordinator.refresh()` |
| `TabView` + `NavigationStack(path:)` per tab | `NavigationBar` + one Navigation 3 back stack per tab |
| `NavigationDestination` + `viewForDestination` | `sealed interface Destination` + `appEntries` |
| `.navigationTitle` large / inline | `RecitLargeTopBar` / `RecitTopBar` |
| `.searchable`, `.sheet`, `.alert`, `Menu`, `.swipeActions`, `.refreshable` | `SearchBar`, `ModalBottomSheet`, `AlertDialog`, `DropdownMenu`, `SwipeToDismissBox`, `PullToRefreshBox` |
| `URLSession.shared` / `.cookieless` | `sessionClient` with the cookie jar / `publicClient` without one |
| Keychain | `KeystoreSessionVault` (AES-GCM, Android Keystore key) |
| Nuke | Coil 3, over the cookieless client |
| `DesignSystem/Tokens` | `designsystem/` (`RecitTheme.colors`, `.typography`, `Spacing`, `CornerRadius`), fonts and icons copied |
| `Localizable.xcstrings` (FR) | `res/values/strings*.xml`, one file per feature |

ADR 0001 and ADR 0008 hold as written:

- screens read Room;
- a sync merges and never deletes and re-inserts;
- user writes are optimistic except creates and deletes, and the shelf domain is optimistic
  throughout;
- one `AuthService` touches cookies and the vault;
- a jar session counts only when its payload names a user;
- public calls carry no cookie;
- only a `401` on `GET /api/user` signs the user out.

## Technical surface

- Build: `cd Recit_Android && ./gradlew :app:assembleDebug :app:testDebugUnitTest`.
  - AGP 9.4.1, Kotlin 2.4.10, Gradle 9.7.1, compile and target SDK 37, min SDK 28.
  - A `local.properties` with `sdk.dir` is needed and git-ignored.
- Single module `:app`, package `studio.lunabee.nouveaurecit`. The debug build is
  `studio.lunabee.nouveaurecit.dev` and uses its own session namespace, as `Env` does on iOS.
- Dependencies: androidx (Compose BOM 2026.09, Material 3, Navigation 3, Lifecycle, Room 2.8,
  DataStore), kotlinx (coroutines, serialization), OkHttp 5 and Coil 3. There is no DI framework:
  `AppContainer` is the composition root, and screens build their `ViewModel` with
  `recitViewModel { container -> … }`, scoped to their navigation entry.
- 101 JVM tests:
  - authentication types, and `AuthService` over MockWebServer;
  - merges and DTO decoding;
  - edition relevance;
  - search phases, ranking and recents;
  - the presentation logic of the lists, network and profile screens.

## Decisions worth knowing

- **The session lives on the device, encrypted, and dies with the install.** No Android store
  outlives an uninstall the way the keychain does. The vault is a private `SharedPreferences` file
  rather than DataStore, because the root reads `isLoggedIn()` synchronously before its first frame.
- **The jar is in memory.** The vault is the record, and it restores the jar at launch. The
  "jar holds a session the keychain lacks" case of issue 0069 cannot arise.
- **An empty image path is no image.** It is not a Commons URL with no file name.
- **Every query value is encoded** by `HttpUrl`. iOS interpolates most of them raw.
- **Strings that several features share** are prefixed with their feature (`inventory_`, `shelf_`,
  `network_`) so the parallel `strings_<feature>.xml` files cannot collide. A few iOS strings with
  one form became plurals.
- **The empty-shelf card offers only « Rechercher »**, since nothing scans or sorts yet. With books
  but no shelf, it shows its heading and body with no tag.

## Not done, or not verified

- **Never exercised signed in.** The app was installed on an API 35 emulator: it launches, the
  welcome and sign-in screens render, and nothing crashes. No session was opened, so every
  signed-in screen has been compiled and unit-tested but not seen running against inventaire.io. A
  pass on a device with a test account is owed.
- **No end-to-end scenario and no instrumented tests** exist for Android.
- **Not ported:**
  - the batch scanner and creating a book (they need CameraX and ML Kit, new dependencies to
    confirm first);
  - automatic and manual sorting (Apple Intelligence has no on-device equivalent here);
  - painted spines and the press-and-hold focus;
  - the wall of covers and the onboarding after sign-in;
  - tips, transactions (hidden on iOS too), groups, the full-screen cover, reporting by mail;
  - genre enrichment and genre tags.
- No Figma pass: the screens follow the iOS code, not the Figma library.
