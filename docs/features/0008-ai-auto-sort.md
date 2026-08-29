# Automatic shelving with on-device AI

Shipped on 2026-08-20 from PRD `docs/prd/0006-ai-auto-sort.md` (deleted — git history)
(issues `issues/0021-delete-shelf.md` through
`issues/0025-auto-sort-entry-points-availability.md`).

> Amends `docs/features/0005-shelf-label-and-add.md`: the empty-state étagère card, which
> shipped opening the create form on any tap, now starts this flow on every device. Where
> Apple Intelligence cannot run, the flow says so.

> **Half of this is superseded by PRD `docs/prd/0008-manual-shelf-sorting.md` (deleted — git history)** (issue
> `issues/0043-retire-the-auto-sort-review-screen.md`, 2026-08-21): the review-and-apply
> screen and its write path are gone, replaced by the sorting surface. The pipeline below
> — histogram, taxonomy, validator, plan — is untouched and is what the surface's
> « Proposer un rangement » button runs. See "What was superseded" at the foot.

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
- **Hiding applies only to the entry point that can be hidden** — the settings one. The
  empty-state étagère card is the empty state itself, so it always leads into the flow and the
  flow states the reason. It briefly fell back to the create form on an ineligible device
  instead; that was removed within the day, because a note about tidying books that silently
  opens a create-shelf form reads as the wrong screen rather than as an unsupported device,
  and a silent substitution hides the failure entirely.

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

## What was superseded

*Added 2026-08-21, by PRD 0008 / issue 0043.*

**The review-and-apply flow was replaced by the sorting surface** (`Features/Sorting/`,
`ManualSortView`). Not amended — replaced: the screen is deleted and the app is left with one
implementation of "create étagères and fill them", `SortSessionModel`.

What went, and what stands in its place:

| Gone | Replaced by |
|---|---|
| `AutoSortPlanView` — the review-turned-progress list, and the `autoSort` navigation destination | `ManualSortView` / `ManualSortListView`, reached at `NavigationDestination.manualSort` |
| `AutoSortModel.apply`, its `applying` / `applied` phases, its stored plan, phase, histogram, rejections and ledger, and `AutoSortApplyFailure` | `SortSessionModel.apply` and `SortWritePlan` |
| `AutoSortApplyReport` | `ManualSortApplyReport` + `ManualSortApplyStoppedReport` |
| `AutoSortShelfMark` | `ManualSortShelfMark` |
| `AutoSortApplyProgress` (`Model/AutoSort/`) | the same reduction, moved and renamed: `SortApplyLedger` (`Model/Sorting/`). Its suite moved with it |
| `AutoSortBookRow` (`Features/AutoSort/`) | the same row, moved and renamed: `SortBookRow` (`Features/Sorting/`), now read only by the surface |

What stayed, and why:

- **The whole pure pipeline**, unchanged and still under test: `GenreHistogram`,
  `ShelfMappingValidator`, `ValidatedGenreMapping`, `AutoSortPlan`, `AutoSortBook`,
  `AutoSortName`, and `AutoSortPrompts` — which is documented as drifting whenever a
  constraint is added, and was not touched.
- **`AutoSortModel`**, reduced to what it now is: availability, and `proposePlan`, which runs
  the three phases over a collection the caller names and hands the plan back. It publishes
  nothing and writes nothing, because it no longer has a screen.
- **`AutoSortEntryPoint`** and **`AutoSortUnavailableView`**: the availability rule still
  decides the settings row's shape, and the wording is still used by the scan bilan.

The three entry points move with the destination. The settings row and the empty-shelf card open
the sorting surface, as does the scan bilan's « Ranger mes livres ». The empty-shelf card still
leads in **on every device** — the decision recorded in 0005's "The empty card's press" — and the
reason is still stated where it now belongs: as a sentence beside the missing proposal button
(`ManualSortProposalButton`), not as a wall in front of a screen that works.

The two gaps this feature listed as known are closed by the replacement rather than by a fix: the
plan can now be edited, because it lands as ordinary changes on a stack, and books with no genre
data can be filed by hand instead of staying unshelved. Genre coverage over a real library is
still unmeasured.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> The paths below are the ones they had then; issues have since moved under `docs/`.
> To read them: `git log --diff-filter=D --oneline -- issues/ docs/issues/` then
> `git show <commit>^:<path>`.

- `issues/0021-delete-shelf.md` — delete an étagère from its form
- `issues/0022-genre-enrichment.md` — fetch and persist genres for works
- `issues/0023-auto-sort-plan-generation.md` — generate and review a shelving plan
- `issues/0024-auto-sort-apply-plan.md` — apply an approved plan
- `issues/0025-auto-sort-entry-points-availability.md` — entry points and availability
