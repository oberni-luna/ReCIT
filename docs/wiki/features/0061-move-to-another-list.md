# Moving a book to another list

Shipped on 2026-10-30. A single-slice autopilot run: no PRD, no issue, the decision log summarised below is the spec.
It changes the list screen of [0060](0060-list-cover-flow.md).

## What it does

On a list of works or of authors, the row under « Mon commentaire » no longer reads « Voir la fiche du livre » /
« de l'auteur·ice »: the cover in front already opens the page when tapped. It reads **« Déplacer dans une autre
liste »**.

- **The row opens a menu** of the user's other lists **of the same type** — works lists for a work, authors lists for
  an author —, sorted by name. A list that already holds the element is shown greyed, with « Déjà dans cette liste »
  under its name.
- **Picking a list moves the element there, with its comment**: added to the list picked, the comment written on the
  new element, taken out of this list. The row spins meanwhile; once the server has answered, the element leaves the
  cover flow and the selection passes to its neighbour.
- **A SnackBar says « Déplacé dans « … » »**, or the shared error SnackBar says what failed.
- **No other list of the type: no row.** The comment's section then holds the comment alone.
- **The row is inert** while the comment is being written (its draft is only saved when the field is left), and for an
  element just added whose server id has not come back yet.

## Technical surface

- **`ListMoveRow`** (`Features/Lists/`) — a `Menu` in the comment's section of `ListCoverFlowScreen`, the lists from
  `@Query`, the SnackBar through `\.snackBar`, failures through `AppErrorReporter`. Accessibility identifier
  `e2e.listMove`.
- **`ListMoveDestination`** (`Model/Lists/`, pure, tested) — which lists the menu offers, in which order, and which are
  greyed.
- **`ListModel.moveElement(modelContext:item:from:to:)`** — `PUT /api/lists/add-elements` on the destination, then
  `PUT /api/lists/update-element` with the comment when there is one, then `PUT /api/lists/remove-elements` on the
  source. Tested with `MockAPIService`: the three calls in order, no comment call without a comment, nothing moved when
  the add fails, the element in both lists when the removal fails.
- `ListCoverFlowScreen` loses `openLabel`; `open(_:)` stays, for the cover.
- Strings: `list.detail.move`, `list.detail.move.already`, `list.detail.moved_to_named %@`, fr and en;
  `list.detail.open.work` and `.author` removed.

## Notable decisions

- **Server-first, not optimistic.** A move is three calls; made optimistic, a failure halfway would have to undo an
  add that did land, or put back an element the server had removed. Each call waits for the one before and a failure
  stops the rest, so the element is never taken out of a list before it is in the other: at worst it is in both, and
  the store says so — what landed on the server is filed locally before the error is thrown.
- **The comment travels through `update-element`**: `add-elements` takes uris only.
- **A list that already holds the element is greyed, not hidden.** inventaire.io answers `alreadyInList` and creates
  nothing, so a move there would only take the element out of this list and drop its comment. Should the store be
  stale and the server say so anyway, the element is still taken out of the source and the destination keeps its own
  comment.
- **No « Nouvelle liste… » line in the menu**: the row is hidden when there is nowhere to go. Left for later.

## Not done, not verified

- Built; unit suite green (1186 passed, the integration scenario skipped).
- Seen on the iPhone 17 simulator in light: the row in place of « Voir la fiche », the menu offering the two other
  works lists and not the authors list. **No move was made**: the simulator's account is real data.
- Not seen: a move for real, the SnackBar, the spinner, a greyed list, the error path, an authors list, dark mode,
  iOS 18.
- Android: ported in [0062](0062-android-catches-up-with-1-7-0.md). Figma's `Liste détails` frames still draw « Voir la fiche ».
- The end-to-end scenario was not run.
