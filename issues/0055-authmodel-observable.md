Title: AuthModel becomes @Observable, before anything is added to it
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0010-ex-libris-pre-login-onboarding.md

## What to build

Convert `Features/Authentication/Model/AuthModel.swift` from Combine's `ObservableObject` to
`@Observable`, and update its ten call sites. No behaviour changes, no new API.

`CLAUDE.md` forbids new `ObservableObject` types, and PRD 0010 is about to double this type's API
surface with `signup` and `resetPassword`. Writing new methods into a type the project's conventions
forbid entrenches the debt instead of paying it. Ten call sites across six files is the cheapest this
file will ever be.

This slice ships alone, and first. It touches `ReCIT.swift` — the `@main` — and therefore every user;
it must be revocable without taking the feature with it.

### The call sites

- `ReCIT.swift:18` — `@StateObject` becomes `@State`
- `ReCIT.swift:29` and `RootView.swift:110` — `.environmentObject(authModel)` becomes `.environment(authModel)`
- `RootView.swift:12` and `ProfileView.swift:13` — `@EnvironmentObject var authModel` becomes `@Environment(AuthModel.self) private var authModel`
- `LoginView.swift:12`, `MainTabView.swift:16` — plain `let` properties, unchanged
- `RootView+RefreshUserData.swift:13`, `ProfileView.swift:46`, `ProfileView.swift:149` — reads and calls, unchanged

`@Published` is dropped from both properties; `@Observable` tracks them.

### The trap to watch

A missing `@EnvironmentObject` crashes at launch with a clear message. A missing
`@Environment(AuthModel.self)` yields `nil` and behaves wrongly, in silence. The two converted sites
must be exercised at runtime, not merely compiled: open the app logged out, and open Réglages logged in.

While here: `isAuthenticated` is declared `= true` and then overwritten in `init` from
`authService.isLoggedIn()`. Keep the initialiser's value as the real one; do not let the conversion
change what a fresh instance reports.

## Acceptance criteria

- [ ] `AuthModel` is `@Observable @MainActor` and imports no Combine
- [ ] No `@Published`, `@StateObject`, `@EnvironmentObject` or `.environmentObject` remains for this type
- [ ] The app builds with no warnings introduced
- [ ] Logged out, the app shows the login screen; signing in reaches the tabs
- [ ] Logged in, Réglages shows the account row and signing out returns to the login screen
- [ ] No other model's injection is touched in this slice

## Blocked by

None - can start immediately
