# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**Ex-libris** — iOS app (SwiftUI + SwiftData) that tracks personal books and lets users give, lend, or sell them to friends. Status: pre-1.0, headed for production. App data is sourced from and synced to the third-party [`inventaire.io`](https://inventaire.io) backend (a CouchDB-backed open-data book inventory), so most server entities carry CouchDB-style `_id` / `_rev` string identifiers.

Key features: physical-book inventory, search across editions/works/authors, curated book lists, transactions (give/lend/sell), and a community/friends view.

## Repository layout

```
ReCIT_iOS/                       # Xcode project root (also where you `cd` to build)
├── ReCIT_iOS.xcodeproj          # only project — no workspace
├── ReCIT.swift                  # @main App, builds the shared SwiftData ModelContainer
├── Env.swift                    # API base URL + keychain key per env (currently both → inventaire.io)
├── App/                         # (reserved, currently empty)
├── AppModels/                   # Reference-type "models" injected via env (network + cache layer)
│   ├── Service/                 # APIService + NetworkError (URLSession wrapper, JSON in/out)
│   ├── Entity/                  # EntityModel — author/work get-or-fetch + SwiftData insert
│   ├── List/                    # ListModel + ListDTO — book-list CRUD against /api/lists/*
│   ├── Inventory/, Search/, Transaction/, User/, Common/
│   └── …                        # one *Model.swift + paired *DTO.swift per domain
├── Model/                       # SwiftData @Model types + Codable DTOs + value types
│   ├── UserData/                # EntityList, EntityListItem, InventoryItem, User, UserGroup, …
│   ├── Books/                   # Author, Work, Edition, Entity protocol, WpExtract (Wikipedia)
│   ├── SearchResult/, Transaction/, Utils/
├── Features/                    # One folder per screen/flow (the bulk of the SwiftUI code)
│   ├── MainNavigation/          # RootView, MainTabView — top-level entry + tab host
│   ├── Authentication/          # AuthModel/AuthService/LoginView (session cookies in Keychain)
│   ├── EntityBrowser/           # NavigationDestination enum + Author/Work/Edition detail screens
│   ├── Lists/, Inventory/, Transactions/, Search/, Community/, Profile/, Works/
│   └── Components/              # Cross-feature widgets (AsyncButton, CachedAsyncImage, SnackBar…)
├── DesignSystem/                # Tokens (Color/Spacing/CornerRadius/TextStyle), fonts, button + label styles
├── Assets.xcassets, Localizable.xcstrings
└── Tests/, UITests/             # Swift Testing (@Suite/@Test) + XCUITest targets
```

### Where documents live

Everything written about the project lives under `docs/`, nowhere else:

```
docs/
├── adr/                         # architecture decisions
├── prd/                         # what a feature is meant to be, before it is built —
│                                # deleted once its feature doc exists (see docs/prd/README.md)
├── issues/                      # open work only — shipped issues are deleted, git keeps them
├── features/                    # what a feature turned out to be, once shipped
├── design-system/               # the Figma library and its divergences from code
└── integrations/
```

`issues/` and `prd/` used to exist at the repository root as well, drifting out of sync with
their `docs/` twins; both root copies were deleted on 2026-08-29.

The `toml-skills:*` workflow skills write to the repository root, which is how the split
appeared. Use the `olive-skills:*` fork instead — `olive-skills:to-prd`,
`olive-skills:to-issues`, `olive-skills:implement-feature` — which writes to `docs/`. If
something does land at the root, move it rather than letting the split come back.

## Build, run, test

All `xcodebuild` invocations expect you to run from the repo root (or pass `-project ReCIT_iOS/ReCIT_iOS.xcodeproj`). There is no Fastlane, no SwiftLint config, and no Makefile — Xcode/SPM is the whole toolchain.

```sh
# List schemes / targets / configs
xcodebuild -project ReCIT_iOS/ReCIT_iOS.xcodeproj -list

# Build the app for the simulator
xcodebuild -project ReCIT_iOS/ReCIT_iOS.xcodeproj \
  -scheme ReCIT_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Run the full test target (ReCIT_iOSTests — Swift Testing)
xcodebuild -project ReCIT_iOS/ReCIT_iOS.xcodeproj \
  -scheme ReCIT_iOSTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test

# Run a single test (Swift Testing identifier = TypeName/methodName)
xcodebuild test \
  -project ReCIT_iOS/ReCIT_iOS.xcodeproj \
  -scheme ReCIT_iOSTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ReCIT_iOSTests/InventoryIntegrationTests/inventoryScenario
```

### The end-to-end scenario

One command plays the whole app on a simulator, against the real `inventaire.io`, and opens a
compte-rendu — one row per step, with a screenshot, what it acted on, and OK / KO / non joué:

```sh
scripts/e2e.sh
```

It asks for the test account's password (`OlivierB_test2` by default; `E2E_PASSWORD` and
`E2E_USERNAME` override, `E2E_SIMULATOR` picks the device, `E2E_RESET_ACCOUNT=1` empties the
account first). The report lands in `build/e2e/<timestamp>/report.html`. **inventaire.io
rate-limits sign-ins**, so several runs in quick succession will meet a `429` and report a KO on
the connexion step — wait a few minutes rather than retrying at once. The scheme is `ReCIT_iOSE2E`; the scenario itself is
`UITests/E2EScenarioTests.swift`, and it signs in, **restarts the app and checks it is still
signed in**, scans, searches, sorts, lists, **deletes everything it created**, and signs out. Its first complete run reproduced — and so got fixed —
a crash that had been unreproducible for two days (issue 0065, now in git history), and turned up
a second one still open
([issue 0067](docs/issues/0067-genre-enrichment-writes-to-a-work-that-may-be-gone.md)), which is
what it is for. Read
[docs/features/0012-end-to-end-scenario.md](docs/features/0012-end-to-end-scenario.md) before
touching it — in particular the `e2e.*` accessibility identifiers it depends on, and the two
seams it needs in the app (`AppModels/UITest/UITestHooks.swift`).

**Heads-up on the test target:** `Tests/ReCIT_iOSTests.swift` is an *integration* suite that logs into the real `inventaire.io` production server with hard-coded credentials (`OlivierB_test`) and mutates that account's data. It is now gated behind `.enabled(if: IntegrationConfig.isEnabled)`, so a normal run skips it — but the credentials are still in the repo. Do not add it to automated pipelines without first stubbing the network or moving them out. Everything else is a pure or `MockURLProtocol`-backed suite and is safe to run anywhere.

## Architecture (the parts that span files)

### App entry & dependency injection

`ReCIT.swift` (the `@main`) does three things:

1. Builds a single `ModelContainer` covering every SwiftData `@Model`: `InventoryItem`, `User`, `Edition`, `EntityList`, `EntityListItem`, `Author`, `Work`, `WpExtract`, `UserTransaction`, `TransactionMessage`, `StoredGroup`. Persistence is on-disk, **not** CloudKit.
2. Creates the long-lived `AuthModel` and attaches it to the scene via `.environmentObject`.
3. Calls `DesignSystem.start()` to register custom fonts (Alegreya, OpenSans) and configure `UINavigationBar` appearance.

`RootView` then instantiates the rest of the shared app models (`UserModel`, `ListModel`, `EntityModel`, `SearchModel`, `InventoryModel`, `TransactionModel`) as `@StateObject` and re-injects them as `EnvironmentObject` into `MainTabView`. Any new shared model belongs in `AppModels/<Domain>/` and must be added in **both** places (`@StateObject` + `.environmentObject`).

Note: every shared model is `@Observable @MainActor`. `AuthModel` was the last Combine `ObservableObject` and was converted in issue 0055 — `@Published`, `@StateObject`, `@EnvironmentObject` and `.environmentObject` now return zero hits across the codebase. Keep it that way.

### Networking

Everything that talks to `inventaire.io` goes through `AppModels/Service/APIService.swift`. It exposes generic `send<T,U>(toEndpoint:method:payload:)` and `fetchData<T>(fromEndpoint:)` over `URLSession.shared`, with errors funnelled through `NetworkError`. `APIService.absoluteImageUrl(_:)` resolves three image-URL shapes (absolute, `/img/...` on inventaire, and Wikimedia `Special:FilePath`).

Authentication is cookie-based: `AuthService` performs `POST /api/auth/login`, captures the `inventaire:session*` cookies from the response, and persists them to the Keychain under `Env.keychainKey` so subsequent `URLSession.shared` requests stay authenticated.

**Read [ADR 0008](docs/adr/0008-session-login-signup-keychain.md) before touching anything about sessions** — signing in, signing up, the two copies of the session (jar and keychain) and which one answers `isLoggedIn()`, why public traffic goes through `URLSession.cookieless`, and what a `401` is allowed to do. Two releases have already been broken by changing one of those pieces without the others (issues 0068 and 0069). Short version: nothing outside `AuthService` reads or writes cookies or the keychain, every server answer worth a sentence is a case on a pure type in `Model/Authentication/`, and a call made before there is a user goes through `publicAPIService`.

### Server entities ↔ SwiftData

The pattern repeated across `AppModels/*/<Domain>Model.swift` is:

1. Hit an `inventaire.io` endpoint → decode a DTO (`*DTO.swift` in the same folder).
2. Map the DTO to a SwiftData `@Model` via a `convenience init(<dto>:baseUrl:)` defined on the model itself (see `EntityList(listDTO:baseUrl:)`).
3. `modelContext.insert(...)` and `try modelContext.save()`.

Because the server already owns identity, every persisted model exposes `_id: String` (server doc id) and `_rev: String` (CouchDB revision). `_id` is marked `@Attribute(.unique)`. Treat the local store as a cache of server state, not the source of truth.

### Data architecture — reactive UI, background sync, optimistic writes (see `docs/adr/0001`)

This is the standard for all new data flows. Three invariants:

1. **UI is bound to SwiftData and reactive.** Views render from `@Query` (preferred) or a passed `@Model`; they never read a model method's return value for display. `*Model` methods return `Void`/`throws`.
2. **Server → App is UPSERT-in-place, never delete+reinsert.** Update existing objects by `_id`, insert only the new ones. Object identity must survive a sync or open views go stale. Use `ModelContext.upsert(...)` (`AppModels/Common/RemoteUpsert.swift`); each `@Model` gets `init(dto:)` + `update(from dto:)` (idempotent, non-nil-guarded merge — a sparse payload must not wipe good local data).
3. **App → Server is optimistic, via `OptimisticMutating.optimistic(_:apply:revert:request:reconcile:)`** (`AppModels/Common/OptimisticMutating.swift`): mutate+save locally first (instant UI), run the WS call in a model-owned background `Task`, `reconcile` on success / `revert` on failure. Failures surface through the shared `AppErrorReporter`, observed once in `MainTabView` → SnackBar. Optimistic placeholders use the `optimistic:` id prefix. Only user-initiated writes are optimistic; pure syncs just upsert.

Reference implementations: `TransactionModel` (messages + state changes), `EntityModel` (entity refresh), `ListModel.syncLists` (upsert). Migration of the rest is incremental — see the ADR.

### Navigation

Each tab root (`ShelvesView`, `EntityListView`, `NetworkView`, `ProfileView`) owns its `NavigationStack` and `@State` `NavigationPath`; modal flows (`SortFlowView`, `AuthFlowView`) own theirs; detail screens never add one. `Features/EntityBrowser/NavigationDestination.swift` is the single enum dispatching to detail screens. To add a new destination:

1. Add a case to `NavigationDestination` (and a stable `id` string).
2. Add a `case` to `viewForDestination(_:)` returning the detail view.
3. Push by appending `NavigationDestination.<case>(...)` onto the path.

`path: Binding<NavigationPath>` is threaded through every detail view so deep links can stack further pushes.

### Lists feature note

`EntityList` owns `@Relationship(deleteRule: .cascade) var elements: [EntityListItem]` with `EntityListItem.list: EntityList?` as the inverse. When mutating list contents (`ListModel.addEntitiesToList` / `deleteElementsInList`), the SwiftData side and the server side are kept in lockstep — the server is called first, and SwiftData is only mutated on success.

### Design system

`DesignSystem/Tokens/` defines `Color`, `Spacing`, `CornerRadius`, `TextStyle`. UI code should consume these via the provided modifiers (`.textStyle(.content300)`, `.foregroundStyle(.foregroundDefault)`, `.buttonStyle(.primary())`, `.applyListBackground()`) rather than literal `Color` / `Font` / `padding(8)` values. Fonts are loaded at launch from `DesignSystem/Fonts/` — adding a font means dropping the `.ttf` in that folder *and* adding a case to `TextStyle.CustomFont`.

The design system is mirrored into Figma (variables, text styles, shadow styles, a `Tokens` page). Read [docs/design-system/figma-library.md](docs/design-system/figma-library.md) **before** touching that file — it carries the `fileKey`, the node ids, the token tables with their Swift symbols, and the list of code/Figma divergences. Code is the source of truth; divergences get documented there, not silently fixed.

## Swift / SwiftUI conventions

Target: **iOS 18.0+** (since 1.5.0; it was iOS 26.0 before), **Swift 6.2+**, strict concurrency, SwiftUI-only (no UIKit unless asked). Do not add third-party SPM packages without confirming first — current deps are `LBSnackBar`, `Nuke`, `CodeScanner`, `swift-async-algorithms`, `swift-collections`.

Anything from iOS 26 goes behind `#available(iOS 26.0, *)`. Glass and the per-edge list insets already have wrappers that do it — `glassButtonStyle()` and `interactiveGlassCircle()` in `DesignSystem/Extensions/View+glass.swift`, `listRowVerticalInsets(_:)` and `listSectionHorizontalMargins(_:)` in `DesignSystem/List/View+listMargins.swift` — and auto-sort (Foundation Models) reports `.deviceNotEligible` before iOS 26, which hides its entry points. To try the app on an iOS 18 simulator, **build for that simulator**, not for an iOS 26+ one and then install: Xcode only embeds `libswiftCompatibilitySpan.dylib` when the build's destination lacks `Span`, and without it the app dies at launch with `Library not loaded: @rpath/libswiftCompatibilitySpan.dylib`. A generic-device or archive build embeds it.

### Swift

- `@Observable` classes are always `@MainActor`.
- Prefer Swift-native string/collection APIs over Foundation equivalents (`replacing(_:with:)` over `replacingOccurrences`, `URL.documentsDirectory` + `appending(path:)`, etc.).
- Filter user-typed text with `localizedStandardContains()`, never `contains()`.
- No C-style format strings — use `Text(value, format: .number.precision(.fractionLength(2)))`.
- Prefer static member lookup (`.circle`, `.borderedProminent`) over initializing the struct.
- Modern concurrency only — no `DispatchQueue.main.async`, no `Task.sleep(nanoseconds:)` (use `Task.sleep(for:)`).
- Avoid `try!` / `!` outside truly unrecoverable code paths.

### SwiftUI

- `foregroundStyle()` over `foregroundColor()`; `clipShape(.rect(cornerRadius:))` over `cornerRadius()`.
- `Tab` API over `tabItem()`; `NavigationStack` + `navigationDestination(for:)` — never `NavigationView`.
- `@Observable` only — no `ObservableObject` anywhere; none remains.
- Two-arg `onChange(_:_:)` or zero-arg variant; never the deprecated single-arg form.
- `Button` over `onTapGesture()` unless tap location / count is genuinely needed.
- Buttons with an image must also carry text: `Button("Tap me", systemImage: "plus", action: …)`.
- Split sub-views into new `View` structs, not computed properties.
- No `UIScreen.main.bounds`; no `GeometryReader` if `containerRelativeFrame()` / `visualEffect()` will do.
- Wrap enumerated sequences for `ForEach`: `ForEach(Array(x.enumerated()), id: \.element.id)`. `EnumeratedSequence` is a `RandomAccessCollection` only from iOS 26, and the app runs from iOS 18; the targets are in the Swift 5 language mode, so the compiler only warns.
- Hide scroll indicators with `.scrollIndicators(.hidden)`, not the initializer flag.
- `.bold()` instead of `.fontWeight(.bold)`; don't force font sizes — use Dynamic Type.
- Avoid `AnyView`. Avoid hard-coded padding / spacing values unless asked.
- Use `ImageRenderer` (not `UIGraphicsImageRenderer`) for SwiftUI → image.
- No UIKit colors in SwiftUI code.

### SwiftData

This project does **not** use CloudKit, so the standard SwiftData rules apply: `@Attribute(.unique)` is fine, properties don't have to be optional, and relationships don't have to be optional. Keep each `@Model` in its own file under `Model/`.

### Code style

- Always declare the type on `let` / `var` (not on `if let` / `guard let`).
- On `if let` / `guard let`, when the new binding has the same name as the optional, use the shorthand: `guard let myProperty else { ... }`.
- Prefer `.init(...)` over explicit type names when initializing (except array / dictionary / set literals).
- Omit `return` in single-expression functions and computed properties.
- No type annotation on SwiftUI environments (`@Environment(\.dismiss) var dismiss`).
- Multi-parameter function signatures and `.init(...)` calls go vertical, one argument per line, closing paren on its own line.
- No trailing whitespace on blank lines.
- One type per file; new code lives under the matching `Features/<Feature>/` or `Model/<Subdomain>/` folder.

## Things that look weird but are intentional

- **`AppModels/` vs `Model/`** — `Model/` is SwiftData + DTOs + value types (data). `AppModels/` is the reference-type service layer (`*Model.swift` classes that wrap `APIService` + `ModelContext`). The split is consistent across every domain.
- **Both `Env.development` and `Env.production` point at `https://inventaire.io`** — there is no staging server; `Env` exists mainly to switch the Keychain namespace between dev and prod builds.

## Shipped features

- [0001 The shelf carousel, and making a shelf from inside the app](docs/features/0001-shelf-carousel-and-creation.md) — étagères as a snapping horizontal carousel, a shelf created optimistically from the app, the layout maths lifted into a testable module
- [0002 Cover-strip spines, reliable scrub, shelf margin](docs/features/0002-spine-strip-scrub-margin.md) — spines from cover art, UIKit scrub, 24pt book margin
- [0003 Tap-to-select shelves, spines for lying books](docs/features/0003-shelf-tap-selection.md) — tap grows the nearest book, tap again opens it; quarter-turned cover for pile books (supersedes the scrub in 0002)
- [0004 Press-and-hold book selection with a focus overlay](docs/features/0004-shelf-press-selection.md) — press grows a book ×2, the screen recedes behind a half-strength veil, the book's cell fades in above it, slide picks, release opens (supersedes the tapping in 0003)
- [0005 Paper labels, header add button, edit in the detail screen](docs/features/0005-shelf-label-and-add.md) — the shelf name becomes a tilted paper tag, "Ajouter" moves to the section header, editing moves to the étagère's navigation bar (supersedes the card-level pencil in 0003)
- [0006 Adding and removing books from étagères](docs/features/0006-shelf-membership.md) — file a book from its "..." menu, swipe it off the shelf you're looking at
- [0007 Batch scanning books into the inventory](docs/features/0007-batch-scanner.md) — the camera stays open and books accumulate; supersedes the single-shot scanner
- [0008 Automatic shelving with on-device AI](docs/features/0008-ai-auto-sort.md) — proposes étagères sized to the collection; its review-and-apply half is superseded by 0009
- [0009 Sorting books into étagères, by hand and with help](docs/features/0009-manual-shelf-sorting.md) — drag books between étagères and « À ranger », nothing written until you apply; its surface is superseded by 0010
- [0010 Ranger mes livres, in a grid](docs/features/0010-grid-shelf-sorting.md) — étagères as cards over an anchored panel of books to file, drag both ways, one modal flow
- [0011 Ex-libris — pre-login welcome and native account flow](docs/features/0011-ex-libris-pre-login-onboarding.md) — the app says what it is for before asking who you are
- [0012 The end-to-end scenario, and the compte-rendu it leaves behind](docs/features/0012-end-to-end-scenario.md) — `scripts/e2e.sh` plays the whole app on a simulator and reports every step with a screenshot and an OK / KO
- [0013 The welcome screen's wall of covers](docs/features/0013-welcome-cover-wall.md) — the pre-login screen opens on a drifting wall of the books inventaire.io just published, painted jackets underneath, dark in both appearances
- [0014 Unified search, in the inventory screen](docs/features/0014-unified-inventory-search.md) — one field for my books, my friends' and inventaire.io; the Recherche tab retires (it came back in 0037)
- [0015 The tips of « Ranger mes livres »](docs/features/0015-sorting-tips.md) — three TipKit cards, each killed by the gesture it teaches; device pass still owed
- [0016 Creating a list or an étagère from a book](docs/features/0016-create-a-list-or-shelf-from-a-book.md) — the "…" menu stops going silent when you own nothing yet
- [0017 Supprimer son compte, depuis le bas du Profil](docs/features/0017-deleting-your-account.md) — `DELETE /api/user` behind a screen that counts what it costs and an alert that acts; the local store is wiped whole, and only after the server says `ok`
- [0017 Signaler un membre ou un échange](docs/features/0017-report-user-generated-content.md) — a « … » on a profile and on a transaction opens a pre-filled report mail; the blocking half of guideline 1.2 is still owed
- [0018 Se faire un réseau de lecteurs](docs/features/0018-reader-network.md) — chercher un lecteur, lui demander, répondre à une invitation, retirer un ami ; les quatre états de `/api/relations`
- [0019 Les étagères qu'un ami partage](docs/features/0019-a-friends-shared-shelves.md) — le carrousel du profil d'un ami, posé sur rien, consultable et pas modifiable ; et la portée de suppression qui manquait à `upsert`
- [0020 Créer un livre qu'inventaire.io n'a pas](docs/features/0020-creating-a-book-that-inventaire-lacks.md) — un scan sans résultat devient une contribution : titre, auteur, couverture photographiée, et deux écrans qui empêchent le doublon d'auteur et d'œuvre
- [0021 The empty shelf says what the first step is](docs/features/0021-empty-shelf-first-steps.md) — a sentence above the plank, and one paper tag per way in: scan, search, or sort
- [0022 The empty Lists tab says what a list is for](docs/features/0022-empty-lists-tab-explains-a-list.md) — a paper tag setting a list beside an étagère, and one that creates the first list
- [0023 A list's type, named in words](docs/features/0023-list-type-labels.md) — the list form's picker says Œuvre, Auteur·ice, Maison d'édition instead of inventaire.io's raw values
- [0024 A list's row shows what it holds](docs/features/0024-list-rows-show-their-covers.md) — the Lists tab fans out each list's first covers and counts its elements in words
- [0025 Signing out forgets the user, and keeps the books](docs/features/0025-sign-out-forgets-the-user.md) — every way a session ends empties users, items, étagères, lists and transactions; editions, works and authors stay
- [0026 The Profil says the app is inventaire.io underneath](docs/features/0026-profile-says-it-is-inventaire.md) — a dismissable paper tag under the account, linking inventaire.io and its open data
- [0027 How far a first sync has got](docs/features/0027-first-sync-progress.md) — a determinate bar over items received / announced for my inventory, each friend's cell and their profile; friends show before their books, which sync last, one by one
- [0028 Un onglet Réseau, et les groupes d'inventaire.io](docs/features/0028-network-tab-and-groups.md) — Amis | Groupes in a tab of their own with a badge; join, answer, leave, invite, run and create groups, every gesture optimistic but creation (groups persisted since 0035)
- [0029 A book's cover, full screen](docs/features/0029-full-screen-cover.md) — tap the header's cover to see it fitted to the whole screen; double-tap between fit and fill, pinch, drag, swipe down to close
- [0030 Works, authors and editions upserted in place](docs/features/0030-entities-upserted-in-place.md) — one way into the store for entities, so a sync stops wiping genres and colours; what removed issue 0067's row; writes after a round trip re-read or skip what has gone
- [0031 Ex-libris on Android](docs/features/0031-android-app.md) — `Recit_Android/`, Room + Compose + Navigation 3: account, inventory and shelves, search, book, lists, friends, profile; scanner, sorting, transactions and groups not ported; first run signed in during 0036
- [0032 « Enregistrer », and a question before leaving « Ranger mes livres » unsaved](docs/features/0032-sorting-save-and-leave.md) — the primary button renamed; the cross asks « Quitter sans enregistrer ? » over unsaved changes until answered « Quitter » once
- [0033 The group the Réseau badge is about](docs/features/0033-group-pending-dot.md) — a red dot after the name of each group with requests to join waiting on me as its admin
- [0034 À propos d'inventaire.io, la version, et un café pour Ex-libris](docs/features/0034-profile-about-and-support.md) — a white À propos screen whose étagère carries my three latest books; the version at the foot of the Profil; a dismissable card and a StoreKit 2 donation sheet (3 / 5 / 10 €, half to inventaire.io); the paper tag of 0026 retired; products not yet on App Store Connect
- [0035 The Réseau network as a graph](docs/features/0035-network-graph.md) — « Tout » draws me, my groups and friends; pinch, touch, answer; DEBUG only
- [0036 Authors on every row, one gap under a group's header, a press that locks before it ends](docs/features/0036-inventory-authors-group-gap-press-lock.md) — snapshot names fill editions first met as entities, with the works' authors as fallback; the group screen's empty actions section dropped and its gaps set to `medium`; selection arms halfway through the hold, same total length
- [0037 A Recherche tab, and what my friends just shelved](docs/features/0037-search-tab.md) — the search leaves the inventory for a tab with the system's search role; at rest, the recent searches and my friends' ten latest books in « Ranger mes livres »'s cards, gone at the first character; `TabRouter` for the cross-tab asks; e2e not run
- [0038 The Profil leaves the tab bar, behind my avatar](docs/features/0038-profile-behind-the-avatar.md) — a round button at the top left of Inventaire, Listes and Réseau, the icon in the bar's glass or the account's picture, opens the profile as a sheet; `TabRouter` holds the flag; e2e not run
- [0039 Black behind the tabs' lists, a step above it in the Profil](docs/features/0039-dark-mode-list-backgrounds.md) — in dark, Listes, Réseau and Recherche on `backgroundGrouped` (black), the Profil sheet on `backgroundGroupedElevated` (`gray/900`); Recherche inset grouped in every phase, « Chez mes amis » edge to edge; the coffee card aligned on the cells; light unchanged, Figma owed (D-R8)
- [0040 Recherche's field always there, a list's detail on black](docs/features/0040-search-field-pinned-list-detail-on-black.md) — on iOS 27 the search tab sits in the bar and its field is pinned under the title (`.navigationBarDrawer(.always)`), iOS 26 unchanged; `EntityListDetail` on `backgroundGrouped`; real app unseen on iOS 27, list detail unseen
- [0041 Android catches up with iOS](docs/features/0041-android-catches-up-with-ios.md) — on `Recit_Android/`: authors on every row, À propos and the version (no donations), the Profil behind the avatar as a full-height overlay, a Recherche tab with « Chez mes amis », black behind the tabs' lists with a third token for the cells; never seen signed in
- [0042 Scanning and sorting books, on Android](docs/features/0042-android-scan-and-sort.md) — CameraX + ML Kit batch scanner and « Ranger mes livres » by hand in one full-screen flow, the bilan between them; the drag is the app's own; no proposal, no book creation; never run on a device
- [0043 Creating a book inventaire.io lacks, on Android](docs/features/0043-android-create-a-missing-book.md) — the scanner's unknown row opens « Nouveau livre »: title, author picked or created, cover by the camera app, dry run then `resolve`, filed and counted; drafts by ISBN; never run on a device
- [0044 Ex-libris on Android, reviewed and redressed](docs/features/0044-android-visual-review.md) — a screen-by-screen review, 46 fixes: books from search open again (`lastrevid` is a `Long`), Wikimedia images load (a named user agent), the cache shows before the network; an app icon, one surface per screen, one book row, one search field, one sheet; the welcome wall of covers; an étagère filled from itself
- [0045 Ex-libris on iOS 18](docs/features/0045-running-on-ios-18.md) — 1.5.0 runs from iOS 18.0; no Apple Intelligence proposal below iOS 26, glass and per-edge list insets through wrappers, `ForEach` over `Array(x.enumerated())` again; e2e on iOS 18.6 at 22 OK / 5 KO, not yet diagnosed
- [0046 Groups on Android](docs/features/0046-android-groups.md) — Réseau gets Amis | Groupes: invitations, my groups with the admin tag and the red dot, sent requests; a group's screen by role, members, invite, find, create, settings; held in memory like iOS 0028, synced after the relations; never seen signed in
- [0047 Nouveau livre, l'œuvre d'abord](docs/features/0047-new-book-work-first.md) — a scan inventaire.io does not know opens on a search for the work: a work found leaves only the edition to describe, none found creates the work with its authors and the edition in one form; covers from the camera, Photos, Files or an address; a notice and a « ? » about bibliographic data; a known work now named in `resolve`, an uploaded cover sent absolute; seen on the simulator up to « Nouvelle œuvre », never published, e2e not run
