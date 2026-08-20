Title: Onboarding — the accueil, and the rule that decides it
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

A new user signs in, waits out the inventory's first sync, and lands on a full-screen accueil
instead of an empty bookshelf: a bare plank, one sentence about scanning barcodes one after
another, `Scanner mes livres`, and `Plus tard`. Tapping the first opens the batch scanner that
already exists. Tapping either one answers the question for good.

This slice also builds the rule that governs the whole feature, because the accueil is its
first consumer.

### The gate

A pure type under `Model/Onboarding/`, on the pattern of `BatchScanStateMachine` and the
`Model/AutoSort/` types: no SwiftUI, no SwiftData, no `UserDefaults`. It takes whether the
inventory has ever synced, how many books the user owns, and whether the accueil has been
answered, and it answers one question in this slice: does the accueil show?

The bilan's decision joins it in the next slice. Build the type so that arrives as a second
method, not a rewrite.

### Why it waits for the sync

An empty `@Query` is ambiguous — "the server has nothing" or "we have not synced yet" — which
is the ambiguity `SyncStatusStore` exists to remove. Inventory freshness is not in that store:
it is `lastInventorySync` being non-nil on the user.

Without that clause, an existing user reinstalling the app gets a first-launch accueil over
three hundred books that have not arrived yet, and answering it suppresses the accueil forever.
The wait needs no new UI: the inventory tab already shows the syncing placeholder while
`lastInventorySync` is nil.

### The store

One key — the accueil has been answered — indexed by user id, in an `@Observable` store backed
by an injectable `UserDefaults`. That is `SyncStatusStore`'s shape, made per-user, so a second
account on the same phone gets its own accueil and QA can reset one account without touching
the other.

### The presentation

A full-screen cover posed by the tab host. The app is built behind it, so `Plus tard` is a
dismissal that reveals the inventory rather than a screen transition. This gives the tab host a
second responsibility beside its shared error observer; that is the accepted cost, since the
alternative branch in the composition root has to decide before the user is known.

### The screen

Existing tokens and the existing shelf illustration, plank and wash, with **no books**: the
inventory is empty by construction, and invented spines would put an étagère on screen that
resembles data the user does not have. Title in `title200`, body in `content300` secondary,
`Scanner mes livres` as a primary large button, `Plus tard` as a bare button carrying
`action300` and the tinted foreground — nothing added to the design system.

French copy goes in the string catalogue, not inline.

## Acceptance criteria

- [ ] A pure gate type under `Model/Onboarding/` decides whether the accueil shows, with no
      SwiftUI, SwiftData or `UserDefaults` import
- [ ] The accueil shows only when the inventory has synced at least once, holds no books, and
      has never been answered
- [ ] A user whose inventory has never synced sees the existing syncing placeholder and no
      accueil, whatever their book count says
- [ ] A user with books never sees the accueil, and answering is not required to suppress it
- [ ] `Scanner mes livres` and `Plus tard` both mark the accueil answered; it does not return
      on the next launch
- [ ] The answered flag is stored per user id, through an injectable `UserDefaults`, so a
      second account on the same device gets its own accueil
- [ ] `Scanner mes livres` opens the existing batch scanner; `Plus tard` dismisses to the
      inventory
- [ ] The accueil renders in light and dark, with no literal colours and no hard-coded fonts
- [ ] Its plank carries no books
- [ ] All copy lives in `Localizable.xcstrings`
- [ ] Test suite on the gate: never synced, synced and empty and unanswered, synced and empty
      and answered, synced and non-empty
- [ ] Test suite on the store: unanswered by default, answering persists, a second user id is
      unaffected, a value written by one instance is read by the next

## Blocked by

None - can start immediately
