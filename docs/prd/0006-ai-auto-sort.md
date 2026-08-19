# PRD — Automatic shelving with on-device AI

Status: needs-triage
Area: Inventory / Étagères (see ADR 0001 / 0003 / 0004)
Depends on: PRD 0004 (shelf membership writes)

## Problem Statement

A user who has just scanned two hundred books has two hundred books and no étagères. Sorting
them by hand means inventing a shelf scheme, creating each shelf, then filing every book
through a menu one at a time. Nobody does this. The bookshelf — the app's whole identity —
stays empty, and the inventory stays a flat list.

The judgement involved is real but shallow: looking at what you own, noticing you have forty
science-fiction novels and three poetry collections, and deciding that warrants a
science-fiction shelf but not a poetry one. That is exactly the kind of small, bounded
judgement a language model is good at — and it can run on the phone, so the user's library
never leaves the device.

## Solution

One action: *range mes livres*. The app looks at what is unshelved, works out a set of
étagères that suits the collection — sized to how many books there actually are in each
theme, not one shelf per genre — and shows the proposed arrangement before touching anything.

The user reads the plan: eight étagères, these names, this many books each. They approve it
or they don't. On approval, the shelves are created and filled while the user watches each
one tick off.

It only ever touches books that are on no étagère, so nothing the user arranged by hand is
disturbed, and a run that fails halfway can simply be run again.

## User Stories

1. As a RECITs collector with a freshly scanned library, I want the app to propose a set of
   étagères, so that I do not have to invent a filing scheme myself.
2. As a collector, I want the proposed étagères to reflect what I actually own, so that the
   scheme fits my collection rather than a generic list of genres.
3. As a collector with only three poetry books, I want them folded into a broader étagère
   rather than given their own, so that I do not end up with a shelf holding three books.
4. As a collector with forty science-fiction novels, I want them to get their own étagère, so
   that the shelf is worth having.
5. As a collector, I want to see the whole plan before anything is created, so that I can
   refuse a scheme I dislike.
6. As a collector, I want to see how many books each proposed étagère would hold, so that I
   can judge whether the split is sensible.
7. As a collector, I want to see which books would go where, so that I can spot a
   misclassification before it happens.
8. As a collector, I want to cancel the plan entirely, so that a bad suggestion costs me
   nothing.
9. As a collector who approves the plan, I want to watch each étagère being created and
   filled, so that I know how far along it is.
10. As a collector, I want each étagère ticked off as it completes, so that progress is
    legible without a progress bar.
11. As a collector whose run fails partway, I want to be told which étagères were created and
    which were not, so that I know the real state of my library.
12. As a collector whose run failed partway, I want to run it again and have it pick up what
    is left, so that recovery is one tap.
13. As a collector who has already arranged some étagères by hand, I want those left
    untouched, so that the feature cannot undo my own work.
14. As a collector, I want only books on no étagère considered, so that the feature is purely
    additive.
15. As a collector, I want books the app could not classify left where they are, so that
    nothing is filed on a guess.
16. As a collector, I want my library never to leave my phone, so that what I read stays
    private.
17. As a collector, I want the étagères named in French, so that they match the rest of my
    shelves.
18. As a collector on a device without Apple Intelligence, I want the feature not to be
    advertised, so that I am not shown something I cannot use.
19. As a collector who has Apple Intelligence turned off, I want to be told that is why and
    shown where to enable it, so that I can act on it.
20. As a collector whose model is still downloading, I want to be told it will be available
    shortly, so that I do not think the feature is broken.
21. As a collector with no étagères, I want to reach this from the empty shelf on my home
    screen, so that the invitation to tidy my books is where the emptiness is.
22. As a collector who already has étagères, I want to reach this from the settings screen,
    so that the feature is not only available to new users.
23. As a collector on an ineligible device, I want the empty shelf to still let me create an
    étagère by hand, so that the card is never a dead end.
24. As a collector running this the first time, I want to be told the app is analysing my
    library, so that the initial wait is explained.
25. As a collector running it again, I want it to be faster, so that the analysis is not
    repeated needlessly.
26. As a collector, I want an étagère I dislike to be deletable, so that a bad run is
    recoverable.
27. As a collector deleting an étagère, I want my books kept in the inventory, so that
    removing a shelf never costs me the record of owning them.
28. As a collector deleting an étagère, I want to confirm first, so that I do not lose a
    shelf by mistake.
29. As a collector, I want the app never to invent an étagère it did not show me, so that
    what I approved is what I get.
30. As a developer, I want the model's output validated against what it was offered, so that
    a hallucinated shelf name can never reach the user's data.
31. As a developer, I want the assignment of books to shelves done in plain code, so that the
    step that mutates data cannot hallucinate.
32. As a developer, I want the cost of a run bounded by how many distinct genres a library
    has rather than how many books, so that a large library is not disproportionately slow.

## Implementation Decisions

### Prerequisites

- **Deleting an étagère.** The server supports it; the app does not. Shipping bulk shelf
  creation without deletion leaves a user with no way out of a run they dislike. Delivered as
  a confirmed destructive action at the foot of the étagère form in edit mode. Deleting a
  shelf removes the shelf, never the books.
- **Genre data.** No genre or subject is currently persisted on any model. A genre property is
  added to the work model — additive with a default, so SwiftData's lightweight migration
  covers it — and populated by a batched fetch of the unshelved works' entities immediately
  before the first run, then persisted so it is paid once. Folding enrichment into the regular
  entity sync is the better end state but perturbs a sync path that already contends with
  optimistic membership writes; on-demand backfill is needed regardless, for works already
  synced.

### The classifier never sees a book

The on-device model's context window holds a few thousand tokens — far less than a library.
Chunking the inventory and asking the model to sort each chunk fails twice over: each chunk
invents its own shelf names, so near-duplicate étagères appear, and no chunk ever sees the
collection as a whole, which is precisely what sizing shelves to book counts requires.

Instead the work splits into three phases, and the model is only consulted on small,
high-judgement inputs:

- **Phase 1 — taxonomy.** The distinct genres present in the unshelved books, with their
  counts, go in; a set of étagère names suited to that distribution comes out. Small
  regardless of library size, and the counts are what let the model merge a three-book genre
  into a broader shelf.
- **Phase 2 — mapping.** Each *distinct genre* is mapped to one of the shelves phase 1 named.
  Bounded by the number of distinct genres, not by the number of books.
- **Phase 3 — assignment.** Plain local code: each book inherits its genre's shelf. No model,
  fully deterministic, trivially testable.

Cost therefore scales with distinct genres, not with books: a three-thousand-book library
costs what a three-hundred-book one costs.

- **Validation is the seam.** Any shelf name appearing in phase 2's output that phase 1 did
  not declare is a hallucination and is rejected before it can reach the plan. Because phase 3
  is code, the step that actually mutates the user's data cannot invent anything.
- **Prompts are written in French**, so shelf names come out French.
- **Everything runs on-device.** No part of the library is sent anywhere.

### Scope and application

- **Only books on no étagère are considered.** This makes the feature purely additive —
  nothing hand-curated can be disturbed — and makes a re-run after a partial failure do the
  right thing instead of duplicating work.
- **Books whose genre enrichment came back empty stay unshelved.** Wikidata's coverage of
  French mid-list titles is patchy, so this will be a real pile; leaving them alone is honest,
  and falling back to asking the model per book from title and author is exactly the
  recall-dependent path this design avoids.
- **The plan is proposed, reviewed and approved as a whole.** No partial approval in v1;
  per-shelf toggles are the obvious extension if all-or-nothing proves too blunt.
- **Applying waits rather than being optimistic** — a second documented departure from ADR
  0001, alongside the batch scanner's add, for the same reason: the user has just approved a
  large mutation and needs to see it land. The add-items calls depend on the ids returned by
  the create calls, so the two stages are sequenced per shelf, not parallel.
- **The review list becomes the progress list.** Each proposed étagère carries an empty
  checkmark that fills once both its creation and its membership write have landed; a failed
  shelf shows an error mark instead. This makes the partial-failure state self-explanatory
  with no extra screen.
- **Partial failure stops and reports.** What landed is kept. No rollback — a rollback that
  itself fails mid-way leaves a worse state than a clearly reported partial one, and the
  unshelved-only scoping makes re-running safe.

### Availability and entry points

- **The three unavailability reasons are treated differently**, not blanketed: an ineligible
  device hides the feature, since the user can do nothing about it; Apple Intelligence being
  switched off is stated with a route to Settings, since it is actionable; a model still
  downloading is shown disabled and described as temporary.
- **Two entry points.** The empty-state étagère card on the home screen — whose label already
  reads as a note to tidy one's books — triggers the flow when tapped; and the settings
  screen, which is the *only* route for a user who already has étagères, since the empty card
  is by definition not shown to them. The whole card is the target, not just its label:
  splitting a painted card into two hit zones is the problem the shelf card's pencil removal
  solved.
- **On an ineligible device the empty card falls back to opening the create form**, which is
  its behaviour today, so it is never a dead end.

## Testing Decisions

- **What makes a good test here:** it drives a pure module's public interface and asserts its
  output. No model, no network, no SwiftUI, no context — deterministic on every run. Notably,
  the model's own output is *not* tested; it is non-deterministic by nature, which is exactly
  why the validation and assignment steps that surround it are pure and are tested.
- **Tested: the genre histogram.** Given a set of items, assert the distinct genres and their
  counts; that books with no genre are excluded from the histogram but counted as unclassified;
  that a book carrying several genres is handled per the chosen rule; and that an empty
  inventory yields an empty histogram rather than failing.
- **Tested: the output validator.** Assert that a mapping referring only to declared shelf
  names passes; that any invented name is rejected; that a mapping omitting a genre is
  handled; that duplicate or case-differing names are resolved deterministically; and that an
  empty or malformed response is rejected rather than partially accepted. This is the guard
  that stops a hallucination reaching the user's data and deserves the most coverage of
  anything in this PRD.
- **Tested: phase-3 assignment.** Given a genre-to-shelf mapping and a set of books, assert
  the resulting plan puts each book on the shelf its genre maps to; that books with no genre
  are left out; that books whose genre is absent from the mapping are left out rather than
  defaulted; that shelf counts in the plan match its contents; and that a shelf ending up
  empty is dropped from the plan.
- **Not tested:** the model session and its prompts, the plan review and progress screens,
  the availability checks, the enrichment fetch, and the network layer.
- Prior art: the shelf books layout suite — pure, seeded, network-free, in the unit test
  target rather than the integration suite that hits the production server.

## Out of Scope

- Re-sorting books that are already on an étagère, or letting the model see existing étagères
  and prefer filing into them. The natural v2, and the reason the v1 scoping is deliberately
  additive.
- Editing the proposed plan — renaming shelves, moving books between them, dropping individual
  shelves. Approval is all-or-nothing.
- Per-book classification from title and author for books with no genre data.
- Folding genre enrichment into the regular entity sync.
- Undoing a completed run in one action, beyond deleting the shelves individually.
- Any server-side or cloud model. This is on-device only.
- Scheduling, or re-running automatically as the library grows.

## Further Notes

- The design rests on a single insight: the model's job is designing a taxonomy, not labelling
  books. Taxonomy design is a small input with high judgement, which suits a small on-device
  model; per-book labelling is a large input with low judgement, which does not. Every other
  decision — the bounded cost, the validation seam, the deterministic mutation — falls out of
  that split.
- This PRD supersedes part of PRD 0003. Issue 0011 shipped with the empty-state card opening
  the create form on any tap; that becomes the *fallback* behaviour for devices where the AI
  is unavailable. That issue's acceptance criteria and feature doc need amending rather than
  being left to drift.
- Shelf deletion is listed here as a prerequisite because this feature creates the need for
  it, but it is independently useful and could ship on its own at any time.
- Genre enrichment adds a second reason to want the entity sync reworked; the membership
  contention described in PRD 0004 is the first.
