# Signing out forgets the user, and keeps the books

Shipped on 2026-09-27. No PRD and no issues: one slice, decided in an autopilot run.

## What it does

Signing out used to delete two things: my own `User` and the transactions. Everything else fetched under the account
stayed in the store — my friends and their inventories, my étagères and theirs, my lists — and surfaced under the next
account signed in on the same phone: friends it never made, lists it never wrote. A session that ended any other way
(a sync meeting a `401`, a launch whose keychain holds none) deleted nothing at all.

Now, **whenever there is no session, the store holds nothing that belongs to a person**:

| Deleted | Kept |
|---|---|
| `User` (me, friends, strangers met in a transaction) | `Edition` |
| `InventoryItem` (mine and my friends') | `Work` |
| `Shelf` | `Author` |
| `EntityList`, `EntityListItem` | `WpExtract` |
| `UserTransaction`, `TransactionMessage` | |

The bibliographic half is inventaire.io's open data, the same for whoever asks; keeping it spares the next sign-in
refetching every cover. Along with the rows, the first-sync markers of `SyncStatusStore` are reset — otherwise the next
account's Listes, Communauté and Échanges tabs would skip their placeholder and say « rien ici » before their first
sync — and any unsent draft of « Ranger mes livres » is discarded.

## Technical surface

- **`UserModel.wipeUserData(modelContext:)`** — deletes the person-owned models, one object at a time (the batch
  `delete(model:)` fails on `InventoryItem.edition`'s mandatory inverse, see `wipeLocalStore`), and drops `myUser`.
  Transactions go before the items they point at, users last. Idempotent.
- **`deleteUserOwnedRows(in:)`** — the list itself, shared with `wipeLocalStore`, which account deletion still uses and
  which adds the four bibliographic models on top. A new `@Model` that belongs to someone goes in the first; one that
  describes a book, in the second.
- **`RootView.forgetSignedOutUser()`** (`Features/MainNavigation/RootView+ForgetSignedOutUser.swift`) — run from
  `.onChange(of: authModel.isAuthenticated, initial: true)` whenever the flag is `false`, after a `Task.yield()` so
  the tabs are gone before their rows are. `initial` covers a launch without a session.
- **`ProfileView.signOut()`** only calls `authModel.logout()` now. `TransactionModel.deleteLocalTransactions` is gone.
- **`UserModelWipeUserDataTests`** — a store with one of everything: every person-owned model is empty afterwards, the
  edition, work and author survive with their relations and no edition keeps a dangling item; a wipe on an empty store
  is a no-op.

## Notable decisions

- **One place, keyed on the flag, rather than in each button.** Three ways to lose a session, and only one of them
  had a cleanup; `RootView` is the one place that sees all three, because it is what swaps the tabs for the welcome
  screen.
- **Every person, not just me.** A friend's inventory is not bibliographic data — it is who owns what — and belongs
  to the account that was allowed to see it.
- **Per-account `UserDefaults` stay.** Recent searches, the welcome and the tips are keyed by `User._id`, so they
  cannot leak across accounts, and a user who signs back in finds them as they left them. Account deletion still
  clears them (`DeleteAccountView`).
- **A failed wipe is logged, not shown.** It runs on the welcome screen, where there is no snack bar and nothing the
  user could do about it; it runs again on the next launch without a session.

## Not verified

- Not played on a simulator signed in: checked by the unit suite (677 passed, 1 skipped), a simulator build, and the
  end-to-end target's build. The end-to-end scenario, which ends with a sign-out, was not played.
- `GenreEnrichmentModel`'s in-memory coverage figure is not reset; it is recomputed on the next analysis.
