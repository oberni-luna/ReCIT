# Sorting books into étagères, by hand and with help

Shipped on 2026-08-21 from PRD `docs/prd/0008-manual-shelf-sorting.md`
(issues `issues/0036-sorting-surface-missing-states.md` through
`issues/0043-retire-the-auto-sort-review-screen.md`). Design: Figma `Nouveau récits`, section
`Ranger mes livres` (`97:3755`), spec panel `Spec · Tri manuel` (`117:3526`).

> Supersedes the review-and-apply half of `docs/features/0008-ai-auto-sort.md`. That screen
> could only be accepted or refused whole, never edited, and it never saw the étagères the
> user had already built. Its pipeline survives as one button on this surface.

## What it does

One screen lays the whole library out as it will be filed: every étagère as a section with the
books it holds, and last a section titled « À ranger » holding every book that is on no
étagère. A book is filed by dragging it from one section to another, in either direction,
including straight from one étagère to another. A « + » in the navigation bar creates an
étagère on the spot, so the scheme can grow while sorting.

Nothing is written while sorting. The screen opens on a snapshot of the library and
accumulates a stack of changes on top of it; what it shows is the snapshot with the stack
applied. Each étagère says which side of that pending work it is on — no pill when nothing
touches it, « Nouvelle » when it does not exist yet, « Modifiée » when its contents have
changed — and a one-line recap says the same thing in words. « Appliquer le rangement »
executes the stack; « Annuler » throws it away.

A button asks the on-device model for a proposal, which arrives as more changes on the same
pile — nothing special, just a faster way of dragging. Because the model is optional, the
screen works on any device: without Apple Intelligence it has one button fewer, not a wall.

## Technical surface

- **New pure modules** (`Model/Sorting/`): `SortSection`, `SortSnapshot`, `SortChange`,
  `SortDraftID`, `SortProjection`, `SortWritePlan`, `SortApplyLanding`, `SortApplyFailure`,
  `SortDraftNameRule`, `SortProposal`, `SortProposalFailure`, `ManualSortRows`, and
  `SortApplyLedger` (moved from `Model/AutoSort/`). No SwiftUI, no store, no device.
- **New feature** (`Features/Sorting/`): the screen, its list, headers, rows, cards, pills,
  recap, marks, reports, action bar and proposal button. `SortBookRow` moved here from
  `Features/AutoSort/`.
- **New app model** (`AppModels/Sorting/SortSessionModel.swift`): app-scoped, `@Observable`,
  built in `RootView` and injected with `.environment(...)`.
- `ShelfModel` gains `removeItemsAwaitingServer`, the awaiting counterpart of the optimistic
  remove-from-shelf, mirroring the awaiting bulk add down to the sync gate.
- `ShelfFormView` gains an `init(draft:)` that returns a name instead of writing. The
  carousel's create and the edit route are unchanged.
- `AutoSortModel` gains `proposePlan` and loses everything that wrote — apply, ledger,
  phases. `NavigationDestination.autoSort` is replaced by `.manualSort`, and four entry
  points follow it: the settings row, the empty-shelf card, the scan bilan and its debug twin.
- `AutoSortPlanView`, `AutoSortApplyReport` and `AutoSortShelfMark` are deleted.
- Nine Figma frames added under `Ranger mes livres` for the states no mockup covered.

## Notable decisions

- **The snapshot is frozen, behind an opening sync.** The screen syncs, reads the store once
  into value types, and never observes SwiftData again. This is a deliberate departure from
  ADR 0001: the membership gate only stands syncs down *during a write*, so across a session
  lasting minutes a sync triggered elsewhere would rewrite the shelf-to-item relation
  wholesale and move books under the user's fingers. The reasoning is written where the
  snapshot is taken. Do not turn it into a `@Query`.
- **The working state is an ordered stack of changes, not a mutable target state.** The move
  carries its origin as well as its destination, so coalescing — and any future undo — is a
  pure function of the stack alone.
- **The gesture is the list's own reorder, not a custom drag.** The first implementation used
  `draggable` / `dropDestination` with a typed transfer, because `List`'s built-in move
  cannot cross a `Section`. On device the drag simply did not take. It was replaced by
  flattening headers and books into a single `ForEach` held in edit mode (`ManualSortRows`):
  crossing étagères works because there is only one `ForEach` to cross, and the lift, the
  animation and the grip are the system's. What `Section` was drawing for free — a card per
  étagère — is repainted per row from `isCardTop` / `isCardBottom`, through
  `listRowBackground` so the card runs under the grip rather than stopping short of it.
- **The screen hands the projection the permutation the list performed.** Edit-mode
  reorder is positional — it animates the row into the exact slot the finger chose —
  while membership carries no user-facing order. Any order the projection invented was a
  *different* arrangement, so SwiftUI animated the difference on top of the drop, and a
  dropped row sat over the row it landed on for about half a second. So `onMove` applies
  the same `move(fromOffsets:toOffset:)` to its own row array and passes the resulting book
  order down as `displayOrder`. Nothing is derived twice, so there is no second diff.
  `displayOrder` is **display only**: `SortWritePlan` builds its projections without it, so
  it cannot change a byte of what is sent; it is cleared on discard, on a fresh freeze, and
  as an apply lands. A book it does not mention keeps its snapshot position, so a partial
  order is still a total one.
- A book nudged **inside** its own étagère records no change — there is no membership to
  write — but it keeps its new place, because the display order is taken either way. That
  reorder is never saved, and reopening the screen re-freezes.
- **Do not disable animations on the move.** It is the obvious-looking cure for the double
  animation and it breaks the gesture outright: the list stops reconciling after its own
  reorder, so the cell stays where UIKit moved it, the data never changes, and the headers
  go on reporting the old counts until the screen is rebuilt.
- **An empty étagère has no row of its own: its header is the drop target.** Edit-mode
  reorder only drops a row where a *movable* row already sits, so an étagère with nothing in
  it needs something to aim at — but giving it a placeholder row meant filling it *deleted*
  a row, while the list had just performed a length-preserving move. SwiftUI then had an
  insertion and a deletion to animate on top of the drop, and the placeholder and the
  arriving book overlapped for about a third of a second. Making the row permanent and
  invisible does not work either: in edit mode the list reserves a grip's height for every
  movable row, and the one shape that does collapse (`EmptyView`) leaves it unclear whether
  `onMove`'s indices still match what the user sees — a risk of filing a book onto the wrong
  shelf, which is not worth trading for an animation. So the header of an empty étagère is
  movable, carries the « this shelf is empty » sentence, and claims the boundary just above
  itself; a move then only ever changes which section a book belongs to, never how many rows
  there are. The étagère above stays reachable by aiming at one of its own books.
- **A draft is created even when it ends up empty.** PRD 0008 said the opposite (user story
  35: a shelf nobody filled is a shelf to go and delete). In use that read as the screen
  ignoring an instruction — the étagère is listed among the pending changes and « Appliquer »
  is live, so refusing to create it made the screen contradict itself. Naming an étagère is
  the instruction; filling it is a separate one. Reversed on the owner's call.
- **`SortWritePlan` is a diff of two projections**, the snapshot against the snapshot with the
  stack applied. It therefore describes only memberships the user actually saw on screen, and
  the coalescing falls out of the diff instead of being a rule written twice.
- **One reduction, three readings.** Operations, per-étagère status and recap counts all come
  from `SortWritePlan`, so the pill, the recap and the write cannot contradict each other. A
  parameterised test asserts they agree on shared fixtures. If a rule must change, change it
  there.
- **Writes are awaited, not optimistic** — the same documented departure from ADR 0001 as the
  batch scanner's add. The user has just approved a batch and has to be able to trust what
  landed. Only single, user-initiated gestures stay optimistic.
- **The stack is trimmed per confirmed call, not per group.** This is what makes a resume
  safe: a creation the server confirmed leaves the stack even when the membership write behind
  it fails, so pressing apply again fills a shelf that now exists instead of creating a second
  one of the same name. The bulk add is idempotent; the create is not.
- **A tick means both the creation and the membership write landed.** An étagère created but
  not filled is a failure, not a partial success, and the report says which of the three
  outcomes each one hit.
- **The button rule is derived from whether the stack is empty**, with no "has applied" flag. A
  successful apply empties the stack, so « Terminer » appears by itself; resuming sorting turns
  it back into « Annuler ». A sticky flag would leave the screen's only destructive button
  labelled « Terminer ».
- **Reconciliation treats an existing étagère and a draft as the same kind of name.** Both are
  names on screen, so both absorb a proposal instead of spawning a twin. The comparison is
  `AutoSortName.key` throughout — trimmed, case- and diacritic-insensitive — never a second
  implementation.
- **An emptied étagère is modified, never deleted.** There is no delete operation in this
  feature — a drag never takes a shelf away behind the user's back.
- **The action buttons sit at the foot of the list, not in the mockup's pinned bar.** The tab
  bar is already underneath and two bars is 166 pt of chrome.
- **« À ranger » stays on screen when it empties**, with its count at zero. It is the only
  target that takes a book *out* of an étagère, so removing it would kill half the symmetry
  the handle promises — and a count at zero is the only proof the work is finished.
- **Copy is real catalogue keys in both locales, with plural substitutions.** This deliberately
  does not repeat divergences D37 and D38, recorded against the retired auto-sort screens.
- **No genre line on the rows, against the design.** The design puts the book's genre under
  its author, and the pipeline's own `primaryGenre` is what filled it — but the live data is
  Wikidata's `wdt:P136` claims, which return labels like « Figure d'autorité ». A line that
  says nothing about the book reads as a bug, so it is gone from the row; the pipeline still
  uses the genre to *decide* where a book goes.

## A design-system bug this feature surfaced

Every OpenSans face silently fell back to the system font, which is why the screen's headers
dwarfed its Alegreya titles and the rows read as wrong even though their measurements matched
the design. `UIFont(name:)` resolves a **PostScript** name, which is not the file name: the
faces ship as `OpenSans-Extrabold` and `OpenSans-Semibold` (lowercase `b`), and the regular one
is plain `OpenSans`. All three were wrong, so `action200`, `action300`, `caption200`, `title50`
and `title200` were San Francisco everywhere in the app. `Bundle.url(forResource:)` is
case-sensitive too, so one file was never registered — and `setupFonts` used `break` rather than
`continue`, so that one failure also cost every face declared after it.

This was divergence D6, recorded as the top priority and open since the design system was
mirrored. `Tests/DesignSystemFontTests.swift` now asserts that every face resolves and that no
text style falls back — the only way to catch a bug the compiler cannot see and that looks like
a design decision on screen.

## Known gaps

- **Apply ordering.** Operations are grouped per étagère in screen order, so
  removals-before-additions holds within a group but not across them. A book moving to an
  étagère that sorts earlier gets its addition first, so a failure in between leaves it on two
  étagères until the resume. Never lost, and the projection still shows it once.
- The three drag frames (`Tri manuel · Glissement`, `Dépôt sur étagère vide`) describe the
  custom drag that was replaced. The lift, the freed slot and the drop highlight are the
  system's now, and not ours to style. Marked superseded rather than deleted.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> The paths below are the ones they had then; issues have since moved under `docs/`.
> To read them: `git log --diff-filter=D --oneline -- issues/ docs/issues/` then
> `git show <commit>^:<path>`.

- `issues/0036-sorting-surface-missing-states.md` — the states never drawn — commit `f276573`
- `issues/0037-sorting-surface-read-only.md` — the surface, read-only — commit `7ca8c2a`
- `issues/0038-sorting-surface-drag-and-drop.md` — the gesture — commit `ed42baa`
- `issues/0039-sorting-surface-pills-and-recap.md` — pills and recap — commit `e9b9e12`
- `issues/0040-sorting-surface-apply.md` — applying, and failing halfway — commit `63f7a2f`
- `issues/0041-sorting-surface-create-shelf-inline.md` — creating inline — commit `f75c2bf`
- `issues/0042-sorting-surface-ai-proposal.md` — the model as one generator — commit `16b4be6`
- `issues/0043-retire-the-auto-sort-review-screen.md` — the demolition — commit `56c3632`
