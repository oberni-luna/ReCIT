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
`UITests/E2EScenarioTests.swift`, and it signs in, scans, searches, sorts, lists, **deletes
everything it created**, and signs out. Its first complete run reproduced — and so got fixed —
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

1. Builds a single `ModelContainer` covering every SwiftData `@Model`: `InventoryItem`, `User`, `Edition`, `EntityList`, `EntityListItem`, `Author`, `Work`, `WpExtract`, `UserTransaction`, `TransactionMessage`. Persistence is on-disk, **not** CloudKit.
2. Creates the long-lived `AuthModel` and attaches it to the scene via `.environmentObject`.
3. Calls `DesignSystem.start()` to register custom fonts (Alegreya, OpenSans) and configure `UINavigationBar` appearance.

`RootView` then instantiates the rest of the shared app models (`UserModel`, `ListModel`, `EntityModel`, `SearchModel`, `InventoryModel`, `TransactionModel`) as `@StateObject` and re-injects them as `EnvironmentObject` into `MainTabView`. Any new shared model belongs in `AppModels/<Domain>/` and must be added in **both** places (`@StateObject` + `.environmentObject`).

Note: every shared model is `@Observable @MainActor`. `AuthModel` was the last Combine `ObservableObject` and was converted in issue 0055 — `@Published`, `@StateObject`, `@EnvironmentObject` and `.environmentObject` now return zero hits across the codebase. Keep it that way.

### Networking

Everything that talks to `inventaire.io` goes through `AppModels/Service/APIService.swift`. It exposes generic `send<T,U>(toEndpoint:method:payload:)` and `fetchData<T>(fromEndpoint:)` over `URLSession.shared`, with errors funnelled through `NetworkError`. `APIService.absoluteImageUrl(_:)` resolves three image-URL shapes (absolute, `/img/...` on inventaire, and Wikimedia `Special:FilePath`).

Authentication is cookie-based: `AuthService` performs `/api/auth?action=login`, captures the `inventaire:session*` cookies from `HTTPCookieStorage.shared`, and persists them to the Keychain under `Env.keychainKey` so subsequent `URLSession.shared` requests stay authenticated.

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

There is no per-feature `NavigationStack`. `MainTabView` owns each tab's `NavigationPath`, and `Features/EntityBrowser/NavigationDestination.swift` is the single enum dispatching to detail screens. To add a new destination:

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

Target: **iOS 26.0+**, **Swift 6.2+**, strict concurrency, SwiftUI-only (no UIKit unless asked). Do not add third-party SPM packages without confirming first — current deps are `LBSnackBar`, `Nuke`, `CodeScanner`, `swift-async-algorithms`, `swift-collections`.

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
- Iterate enumerated sequences directly: `ForEach(x.enumerated(), id: \.element.id)` — don't wrap in `Array(...)`.
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
