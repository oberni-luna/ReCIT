# PRD — Onboarding: scan a shelf, then let the app arrange it

Status: needs-triage
Area: Onboarding / Inventory / Étagères (see ADR 0001 / 0003)
Depends on: PRD 0005 (batch scanner), PRD 0006 (AI auto-sort)
Design: Figma section `Onboarding` (`73:2829`), captured in `grill-me/design/onboarding/`

## Problem Statement

A new user signs in and lands on an empty bookshelf. Everything the app is good at is behind
two features they have no reason to suspect exist: a batch scanner buried in the search tab's
toolbar, and an automatic shelving flow reachable from the settings screen or from a small
paper note on an empty plank.

So the first session goes one of two ways. Either the user adds a book or two by searching
for them — the slowest path into the app, and the one that makes RECITs look like a
note-taking app with covers — or they put the phone down on an empty screen that says *Oh,
c'est vide ici*.

Both features exist, work, and are the reason the app is worth using. Nothing points at
them at the one moment the user is willing to spend ten minutes: right at the start, standing
in front of their own bookshelf.

The second half of the problem is worse, because it happens to users who *did* find the
scanner. Twenty-four books get scanned in four minutes, and then the inventory is a flat list
of twenty-four books on no étagère — which is the exact state PRD 0006 was built to fix, and
the user has no idea.

## Solution

Two full screens, one at each moment where the user has just earned the next step.

**On first launch with an empty inventory**, an accueil: a bare plank, one sentence about
scanning barcodes one after another, and a single action — *Scanner mes livres* — that opens
the batch scanner directly. An escape hatch, *Plus tard*, that does not lead to a dead end:
the invitation comes back down onto the empty-shelf card, whose paper note then reads
*Scanner mes livres* and whose tap opens the scanner.

**When a scanning session ends having added books**, a bilan: *24 livres ajoutés*, the real
covers of the last books scanned settling onto the plank one by one, and one action — *Ranger
mes livres* — that leads into the auto-sort review screen that already exists.

The bilan belongs to the scanner rather than to the accueil, so it also catches the user who
refused the accueil and found the scanner on their own two weeks later. It stops appearing
once the user has an étagère, which is the state the whole sequence exists to produce.

## User Stories

1. As a new RECITs user with an empty inventory, I want the app to tell me what to do first,
   so that I am not left in front of an empty bookshelf guessing.
2. As a new user, I want the first suggested action to be scanning barcodes rather than
   searching titles, so that I get my whole shelf in rather than one book.
3. As a new user, I want the accueil to say what scanning is actually like — the camera stays
   open, books pile up — so that I know I am starting a session and not a single lookup.
4. As a new user, I want a single obvious button on the accueil, so that I do not have to
   choose between three ways in.
5. As a new user who is not ready to scan right now, I want a way out of the accueil, so that
   I can look around the app first.
6. As a user who chose *Plus tard*, I want to still find the invitation to scan afterwards,
   so that skipping the accueil does not mean hunting through tabs.
7. As a user who chose *Plus tard*, I do not want the accueil to reappear on the next launch,
   so that the app takes my answer seriously.
8. As an existing user reinstalling the app, I do not want a first-launch accueil offering to
   scan my books, given that I own three hundred of them already.
9. As an existing user on a slow connection, I do not want the accueil to flash over my
   inventory while it is still syncing.
10. As a user opening the app for the first time, I want to see the existing syncing
    placeholder rather than an empty shelf, so that nothing looks broken while the app fetches
    my inventory.
11. As a user tapping *Scanner mes livres*, I want the camera to open right away, so that the
    accueil does not become a page I have to navigate out of.
12. As a user who has just scanned a batch, I want the app to tell me how many books it added,
    so that I can trust the session did what I think it did.
13. As a user who has just scanned a batch, I want to see my own covers on the screen, so that
    the confirmation is about *my* books and not a generic illustration.
14. As a user who has just scanned a batch, I want the books to arrive one by one on the
    shelf, so that the moment reads as my library being put away rather than as a dialog.
15. As a user who has just scanned a batch, I want to be told my books are on no étagère and
    offered to arrange them, so that I discover automatic shelving at the moment it is useful.
16. As a user who has just scanned a batch, I want to be told the arrangement happens on my
    phone, so that I am not left wondering whether my library was uploaded.
17. As a user who does not want to arrange books right now, I want to leave the bilan without
    doing anything, so that my scan is not held hostage.
18. As a user who left the bilan, I want to find the arrangement offer again on the
    empty-shelf card, so that refusing once does not hide the feature.
19. As a user who scans a second batch a week later, I want the bilan again if I still have no
    étagère, so that the offer follows the moment rather than a one-shot counter.
20. As a user who has already arranged their books once, I do not want the bilan after every
    later scanning session, so that the app stops selling me something I have used.
21. As a user who created an étagère by hand, I do not want to be pitched automatic shelving,
    since I have shown I know what étagères are.
22. As a user who opened the scanner and closed it without adding anything, I do not want a
    bilan announcing zero books, so that the app does not congratulate me on nothing.
23. As a user who opened the scanner from the search tab, I want the same bilan as a user who
    came through the accueil, so that the offer does not depend on which door I used.
24. As a user on a device that cannot run Apple Intelligence, I want the bilan to still
    confirm the books it added, since the scan worked even if the arrangement cannot run.
25. As a user with Apple Intelligence switched off, I want the bilan to say so and point me at
    Settings, so that I can fix it rather than wonder why the button did nothing.
26. As a user whose model is still downloading, I want to be told the arrangement will work
    shortly, so that I try again instead of concluding it is broken.
27. As a user on an ineligible device, I do not want a button that can never work, so that the
    screen does not promise something the hardware cannot deliver.
28. As a user with Reduce Motion on, I want the books to appear without flying in, so that the
    screen respects the setting I chose.
29. As a user with Reduce Motion on, I still want the books to appear one after another, since
    that is what tells me each one landed.
30. As a user in dark mode, I want both screens to render in dark mode, so that they do not
    flash white in a dark room.
31. As a user with two accounts on the same phone, I want the second account to get its own
    accueil, so that my partner's first launch is a first launch.
32. As a user of a phone whose camera access is denied, I want the existing permission wall
    rather than a black screen, so that the accueil does not lead into a dead end.
33. As a French-speaking user with one book scanned, I want the bilan to read *1 livre
    ajouté*, so that the app does not sound machine-generated.
34. As a developer, I want the rule deciding when each screen appears to live in one testable
    place, so that a change to one condition cannot silently break the other.
35. As a developer, I want the scanner's session count to come from the module that already
    processes add events, so that the count cannot drift from what actually landed.
36. As a designer, I want both screens built from existing design-system tokens and the
    existing shelf illustration, so that onboarding does not become a parallel visual language.

## Implementation Decisions

### The gate is a pure module

A new pure type under `Model/Onboarding/` owns both decisions, on the pattern of
`BatchScanStateMachine` and the `Model/AutoSort/` types: no SwiftUI, no SwiftData, no
`UserDefaults`.

Inputs: whether the user's inventory has ever synced, how many books they own, how many
étagères they own, whether the accueil has been answered, and how many books the just-finished
scanning session added. Outputs: whether to present the accueil, and whether to present the
bilan.

Everything else in this PRD reads those two answers. No view re-derives a condition.

### The accueil's condition, and why it waits

The accueil shows when the inventory has synced at least once, the inventory is empty, and the
accueil has never been answered.

The first clause is load-bearing. An empty `@Query` is ambiguous — it can mean "the server has
nothing" or "we have not synced yet", which is the ambiguity `SyncStatusStore` exists to
remove. Inventory freshness is not in that store: it lives on the user's `lastInventorySync`
being non-nil. Without the clause, an existing user reinstalling the app gets a first-launch
accueil over three hundred books that have not arrived yet, and the accueil's own answer flag
then suppresses it forever.

Nothing new is needed to cover the wait: the inventory tab already shows the syncing
placeholder while `lastInventorySync` is nil. The accueil lands after the placeholder, never
over an empty screen.

Both answers count as answering — the CTA and the escape hatch alike. The accueil is a
question asked once.

### The accueil is a cover over the loaded app

The tab host presents the accueil as a full-screen cover. The app is already built behind it,
so *Plus tard* is a dismissal that reveals the inventory rather than a screen transition, and
the empty-shelf card with its changed note is simply what was already there.

This gives the tab host a second responsibility beyond its shared error observer. Accepted:
the alternative — a third branch in the composition root, beside the unauthenticated branch —
has to decide before the shared models are injected, which is precisely when the user is not
known yet.

### The bilan belongs to the scanner

Any scanning session that adds at least one book presents the bilan when it ends, including a
session opened from the search tab. The rule lives in one place and survives the user refusing
the accueil.

The bilan **replaces the camera inside the existing modal** rather than stacking a second
cover on top of it. The camera is torn down, the bilan takes the screen, and dismissing the
bilan is what returns the user to where they came from.

Two consequences are accepted rather than worked around. Closing becomes two-stage: the close
control ends the session, it does not leave. And the scanner view stops being "the scanner" and
becomes "the scanning session" — its documentation, which currently describes a modal that
returns control on close, has to be rewritten rather than left to lie.

### What the session hands over, and what the bilan queries

The session count is carried out of the scanner, because a query cannot derive it: three books
added among three hundred is not visible in any snapshot of the store.

The count is owned by the scanner's pure state machine, incremented on the add-finished event
it already processes. The view model holds no counter of its own, and the count is covered by
the state machine's existing test suite from the outset.

The covers are **not** carried. The bilan reads the most recent unshelved books straight from
the store, newest first, and paints those — invariant 1 of ADR 0001: views render from
`@Query`. The query can pick up a book added before this session; harmless, it is recent and
unshelved too.

### The illustration, and the arrival

Both screens reuse the existing shelf illustration — plank, wash — rather than a new asset.

The accueil's plank is **bare**. The inventory is empty by construction; painting invented
spines to have something to animate would put an étagère on screen that resembles data the user
does not have.

The bilan's plank carries real covers, which arrive one by one: opacity 0 → 1, vertical offset
−32 → 0 points, ease-out over 0.32 s, staggered 0.08 s apart, left to right, once per
appearance. Ease-out rather than a spring: a book set down on a plank does not bounce, and the
design system already reserves springs for picking a book up.

Under Reduce Motion the offset is dropped and the fade and the stagger stay. The stagger
carries the meaning — one book at a time — and a fade is not a movement.

The arrival lives in the bilan's own illustration view, not in the shelf's book renderer: that
one is data-driven and redraws on every carousel scroll, and an appearance animation there
would drop the books of every étagère each time one scrolls past. The illustration is therefore
a composition of views — a plank plus animatable books — never a flattened image.

### The empty-shelf card gains a second destination

The card's note and its destination become conditional on the inventory:

| State | Note | Destination |
|---|---|---|
| Inventory empty | *Scanner mes livres* | the scanner |
| Books on no étagère | *Ranger mes livres* | the auto-sort flow |

This revisits a decision PRD 0006 made deliberately, and the reasoning has to be rewritten
rather than quietly reversed. What 0006 removed was a *silent* substitution keyed on hardware:
a note reading *Ranger mes livres* that opened a create-shelf form on an ineligible device,
where the user could not see why. Here the note changes with the state, so the affordance is
stated before it is used. The rule that survives is the one that matters: a card must never
open something other than what its label promises.

### Unavailability reuses what exists, with no new case

The auto-sort entry-point type is exhaustive and its unavailability view already words all
three reasons, including the ineligible device. The bilan therefore reproduces the auto-sort
review screen's own pattern: when the entry point is enabled, show the CTA; otherwise show the
unavailability view, which decides for itself whether a Settings route belongs there.

No new entry-point case is added. Its cases are *shapes* derived from availability, not places
that use them, and the earlier plan to add a "scan tally" case was a category error. The
unavailability wording stays in exactly one file.

### What is persisted

One key: the accueil has been answered, indexed by user id, in an `@Observable` store backed by
an injectable `UserDefaults` — the shape `SyncStatusStore` already uses, made per-user. A second
account on the same phone gets its own accueil, and resetting for QA is per account.

"The user has already arranged their books" is **not** persisted. It is derived: the bilan stops
appearing once the user has at least one étagère, read from the store like everything else.
Creating an étagère by hand therefore also stops the bilan — accepted, since a user who created
one knows what an étagère is.

### Copy and pluralisation

The bilan's title pluralises in the string catalogue, using its plural rules, not in Swift. The
auto-sort screens currently build plurals with inline ternaries; that is not the pattern to
copy.

The escape hatch is a bare button carrying design-system tokens — the action text style, the
tinted foreground — and adds nothing to the design system. It appears three times across these
screens; a fourth occurrence is the point at which it should become a real button style with its
Figma counterpart.

## Testing Decisions

A good test here states an external behaviour and would survive a rewrite of the thing it
tests: it drives a module through its public surface and asserts what comes out. It never
reaches for private state, never asserts on view bodies, and never asserts the order in which
internals were touched. Prior art: the five suites from PRD 0006 (histogram, validator, plan
assignment, apply ledger, entry point) and the scanner's state-machine suite from PRD 0005,
which tests a cooldown with an injected clock instead of sleeping.

**The gate module.** The centre of the feature and the reason it is a separate type. Cases:
inventory never synced (nothing shows, whatever the counts say); synced and empty and
unanswered (accueil); synced and empty and answered (nothing); synced and non-empty (nothing,
the reinstalling-user case); session added zero books (no bilan); session added books with no
étagère (bilan); session added books with an étagère already there (no bilan); session added
books, user created an étagère by hand (no bilan, the accepted consequence).

**The persistence store.** Injected `UserDefaults`, per the store it is modelled on. Cases:
unanswered by default; answering persists; a second user id is unaffected by the first user's
answer; a value written by one instance is read by the next.

**The scanner's state machine.** Extend the existing suite rather than start a new one. Cases:
count starts at zero; increments only on a completed add; a failed add does not increment; a
repeated barcode that the gate rejects does not increment; the count survives the row clearing
and the next book being offered.

Not unit-tested, and stated as such: the two screens themselves, the cover presentation, the
arrival animation, and Reduce Motion — all verified by hand in the simulator, in both
appearances. The camera permission path remains device-only, as PRD 0005 already records.

## Out of Scope

- **Any new entry point for the scanner or the auto-sort flow.** This PRD points at the two
  that exist; it does not add a third.
- **Reworking the scanner itself.** Its result row, its repeat gate, its permission wall and
  its failure states are untouched. Only its ending changes.
- **Reworking the auto-sort review screen.** The bilan pushes the screen that exists.
- **Dark variants of the two derived states** (the post-refusal empty shelf, the bilan's
  unavailable form) as Figma frames — they are token-bound, so they follow, but they were not
  drawn.
- **A tour of the rest of the app.** No coach marks, no tab-by-tab walkthrough, no progress
  checklist. Two moments, two screens.
- **Backing off after repeated refusals.** A user who answers *Plus tard* at every scanning
  session sees the bilan at every scanning session, until they have an étagère.
- **Onboarding for a user who joins with a non-empty inventory.** They get no accueil at all,
  which is the intent, not a gap to fill later.
- **Fixing the inline plural ternaries on the auto-sort screens.** Tracked separately; this
  feature just does not reproduce them.
- **The dark-mode wash.** The shelf illustration's wash reads as a bright halo on a black
  background. That is existing design-system behaviour (divergence D9), more visible on a
  full screen than on a carousel card, and it is not this PRD's job to fix.

## Further Notes

The sequence is deliberately asymmetric. The accueil promises with words over a bare plank; the
bilan pays with the user's own covers. Inverting that — painting fake books on the accueil to
make it prettier — was considered and rejected during design: it would show an étagère that
looks like an inventory the user does not have, in the one screen whose entire point is that
they do not have one yet.

The bilan's ownership is the load-bearing decision of this PRD. Putting it on the scanner
rather than on the accueil is what makes the feature more than a first-launch flourish: the
moment worth interrupting is not the first launch, it is the end of a scanning session, and
that moment recurs.

Two known frictions to watch in review. The two-stage close may read as the close button not
working the first time — worth a second look on device, since the fix (a distinct label on that
control) is cheap. And the empty-shelf card now has two destinations, which is exactly the shape
PRD 0006 backed out of for different reasons; if the note ever stops changing with the state,
that decision has to be re-opened, not patched.

Design source: Figma section `Onboarding` (`73:2829`), with the resolved ruleset on its spec
panel. The full decision log from the design session is in
`grill-me/design/onboarding/decisions.md`, and the motion parameters in
`grill-me/design/onboarding/motion.md`.
