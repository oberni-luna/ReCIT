# Automatic shelving with on-device AI

Shipped on 2026-08-20 from PRD `docs/prd/0006-ai-auto-sort.md`
(issues `issues/0021-delete-shelf.md` through
`issues/0025-auto-sort-entry-points-availability.md`).

> Amends `docs/features/0005-shelf-label-and-add.md`: the empty-state étagère card, which
> shipped opening the create form on any tap, now starts this flow — and falls back to the
> create form only where Apple Intelligence cannot run.

## What it does

One action proposes a set of étagères for the books that are on none, sized to what the user
actually owns rather than one shelf per genre, and shows the plan before touching anything.
Approve it and the shelves are created and filled while each ticks off in the list. Refuse it
and nothing happened.

It only ever considers unshelved books, so nothing arranged by hand can be disturbed, and a
run that fails halfway can simply be run again. Étagères can now also be deleted, so a plan
you dislike is recoverable.

Everything runs on the phone. No book list leaves the device.

## Technical surface

- Screens: a review-and-progress screen reachable from the settings screen and from the
  empty-state étagère card; a delete action on the étagère form.
- **New pure modules** (`Model/AutoSort/`): `GenreHistogram`, `ShelfMappingValidator` and
  `ValidatedGenreMapping`, `AutoSortPlan`, `AutoSortBook`, `AutoSortName`,
  `AutoSortApplyProgress`.
- **New orchestration** (`AppModels/AutoSort/`): `AutoSortModel` owning the
  `LanguageModelSession`, `AutoSortPrompts`, the two `@Generable` drafts, `AutoSortEntryPoint`.
- **New enrichment** (`AppModels/Genre/`): `GenreEnrichmentModel`, `GenreCoverage`.
- `Work` gains a genre list and an enrichment timestamp — additive, so lightweight migration
  covers it. No new `@Model`.
- `ShelfModel` gains `deleteShelf`, plus server-first variants of create and membership for
  the bulk apply, alongside the optimistic ones.
- Four test suites: histogram, validator, plan assignment, apply ledger, entry point.

## Notable decisions

- **The model is never shown a book.** Its window holds a few thousand tokens. Chunking a
  library and sorting each chunk would have every chunk inventing its own shelf names while
  none of them saw the distribution — which is the one thing sizing shelves depends on.
  Instead: the distinct genres with their counts go in and a taxonomy comes out; each genre is
  mapped to one of those names; then plain code hands every book its genre's shelf. Cost
  scales with distinct genres, not with books.
- **The validator is the seam.** A shelf name in the mapping that the taxonomy never declared
  is rejected before it reaches the plan. It caught a real one during tuning — the model
  answered "bandes dessinées" for the genre "bande dessinée", and those books stayed
  unshelved while the other shelves went through untouched. Matching is strict on purpose;
  tolerating near-misses is the first step back toward guessing.
- **Genre labels, not Wikidata ids.** The entity endpoint returns bare uris; a language model
  cannot group `wd:Q1080374`. A second batched pass resolves them, and the labels are what is
  persisted. An enrichment timestamp records that a work was *asked about*, because an empty
  genre list otherwise conflates "Wikidata has none" with "never fetched" — and with French
  coverage as thin as it is, empty is the common case.
- **Prompt shape came out of five rounds.** Unconstrained, the model returned one shelf per
  genre. Constrained on count, it obeyed and went vague. Told not to say "Divers", it said it
  more. Given examples, it named the examples rather than the collection. What works is a
  positive instruction, no examples, and a bound on name length. Names come out as
  concatenations ("Science-fiction et fantasy") rather than umbrella terms; that is the
  accepted state, and the lever that produced umbrella names also produced copying.
- **A book with several genres is filed under its first**, decided in one place so the
  histogram and the assignment cannot disagree, and so the plan stays a partition — otherwise
  the apply would file a book twice.
- **Applying waits rather than being optimistic**, like the batch scanner's add: the user has
  just approved a large mutation and has to be able to trust what landed.
- **Failure stops and keeps what landed. No rollback** — one that failed mid-way would leave a
  worse state than a clearly reported partial one. The report distinguishes three outcomes,
  not two: a membership failure leaves a shelf *created and empty*, and calling that "not
  created" would send the user hunting for something sitting in their carousel.
- **Re-running is safe by construction**, not by bookkeeping: filed books are no longer
  unshelved, so a fresh plan cannot propose them again. That property is why the
  unshelved-only scoping was chosen.
- **Deletion reverts by snapshot, not by inversion.** SwiftData invalidates a deleted object,
  so the shelf and its items are captured before the local delete and a failure re-inserts it
  under the same id with the books re-attached — which works only because the relation is
  nullify rather than cascade.
- **The three unavailability reasons are treated differently.** An ineligible device hides the
  entry point, since the user can do nothing about it; Apple Intelligence being off is stated
  with a route to Settings; a model still downloading is shown inert and described as
  temporary. Availability is read fresh and the model type is observable, so enabling it and
  returning needs no relaunch.

## Known gaps

- Genre coverage over a real library has never been measured — no run has been made against a
  logged-in account. That number is the honest measure of whether this feature is worth
  keeping, and it is still unknown.
- The plan cannot be edited, only accepted or refused whole.
- Books with no genre data stay unshelved by design; on a thin-coverage library that pile may
  be most of it.
- The shelf sync's first pass is ungated, so a pull-to-refresh inside a delete's round trip
  can make the shelf flash back.
- `deleteShelf`'s revert — snapshot and re-attach — is asserted only by reading.

## Issues

- `issues/0021-delete-shelf.md` — delete an étagère from its form
- `issues/0022-genre-enrichment.md` — fetch and persist genres for works
- `issues/0023-auto-sort-plan-generation.md` — generate and review a shelving plan
- `issues/0024-auto-sort-apply-plan.md` — apply an approved plan
- `issues/0025-auto-sort-entry-points-availability.md` — entry points and availability
