# Swift — Architecture (ReCIT)

> Project convention module, written at `/wa-setup` from `CLAUDE.md` and the ADRs. Replaces the plugin's `architecture-app.md`, whose four layers (protocol view models, no global `Model/` folder) are not this app's. Where `architecture-global.md` disagrees with this file, this file wins. `CLAUDE.md` wins over both.

## Layers

Three layers, one rule each.

```
Features/<Feature>/      SwiftUI views. Read SwiftData through @Query or a passed @Model.
   → AppModels/<Domain>/  @Observable @MainActor *Model classes: APIService + ModelContext.
      → Model/<Domain>/   SwiftData @Model types, Codable DTOs, pure value types.
```

- **Views render from the store, never from a return value.** `@Query` first, a passed `@Model` second. A `*Model` method returns `Void` or `throws` (ADR 0001).
- **Shared models are injected through the environment.** Created in `RootView`, read with `@Environment(FooModel.self)`. Not a singleton, not an init parameter of every view. New shared model → both places.
- **Every `@Observable` is `@MainActor`.** No `ObservableObject`, `@Published`, `@StateObject`, `@EnvironmentObject`, Combine.
- **Pure decisions live in `Model/` as value types** (`EditionRelevance`, `AuthFailure`, `TransactionStateMachine`), tested without network or SwiftData.

## Server → store

ADR 0001, `docs/wiki/adr/0001-swiftdata-reactive-optimistic.md`.

- The store is a cache of inventaire.io. Identity = server `_id`, `@Attribute(.unique)`, plus `_rev`.
- **Upsert in place, never delete + reinsert.** `ModelContext.upsert(...)`; each `@Model` has `init(dto:)` + `update(from:)`, a non-nil-guarded merge. A sparse payload never wipes good data.
- A write after a round trip re-reads by id, or skips what has gone (feature 0030).

## App → server

- User-initiated writes are optimistic: `OptimisticMutating.optimistic(_:apply:revert:request:reconcile:)`. Local first, request in a model-owned `Task`, reconcile or revert. Placeholders use the `optimistic:` id prefix.
- Failures surface through `AppErrorReporter` → SnackBar in `MainTabView`. Never a local alert for a background write.
- Exceptions are named in their feature doc (server-first edits: editions, works, groups).

## Sessions

ADR 0008, `docs/wiki/adr/0008-session-login-signup-keychain.md`. Read it before touching sign-in, sign-up, cookies or the keychain.

- Nothing outside `AuthService` reads or writes cookies or the keychain.
- A call made before there is a user goes through `publicAPIService` (`URLSession.cookieless`).
- Every server answer worth a sentence is a case on a pure type in `Model/Authentication/`.

## Navigation

- Each tab root and each modal flow owns its `NavigationStack` and `NavigationPath`. Detail screens never add one.
- One enum, `NavigationDestination`, dispatches every detail screen. New destination → case + stable `id` + `viewForDestination(_:)`.

## File tree

- `Features/<Feature>/` per screen or flow, `Features/Components/` across features.
- `AppModels/<Domain>/<Domain>Model.swift` + its `*DTO.swift`. `Model/<Domain>/` one `@Model` per file.
- An extension lives in `<Type>+<Topic>.swift` (`User+Upsert.swift`), not `<Type>Extension.swift`.
- `DesignSystem/` tokens and styles. UI consumes tokens (`.textStyle`, `.foregroundStyle(.foregroundDefault)`, `Spacing`), never literals.

## Platform

- iOS 18.0+. iOS 26 API behind `#available(iOS 26.0, *)` or the existing wrappers (`glassButtonStyle()`, `listRowVerticalInsets(_:)`).
- No new SPM package without asking.
- Android (`Recit_Android/`) is a port: a feature doc says what was ported.

## Review checklist (architecture category — ReCIT)

- View displays a model method's return value → finding.
- Sync deletes then reinserts, or `update(from:)` overwrites with nil → finding.
- User write not optimistic, and no feature doc says why → finding.
- Cookie or keychain access outside `AuthService` → critical.
- Shared model missing from `RootView` or the environment → finding.
- New `NavigationStack` inside a detail screen → finding.
