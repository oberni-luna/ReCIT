Title: Create a shelf from the carousel (card + form + optimistic write)
Labels: needs-triage
Type: HITL

## Parent

PRD: docs/prd/0001-bookshelf-carousel-and-create.md

## What to build

Add the ability to create a new étagère from the app — the first write in the shelf
domain (ADR 0003 was read-only). An empty "create" shelf card (plank + wash, a large +,
"Nouvelle étagère" label) sits at the end of the carousel. Tapping it presents
`ShelfFormView`, a sheet mirroring `ListFormView` (name field + optional description,
submit via `AsyncButton`). Submitting calls `ShelfModel.createShelf` which performs an
optimistic `POST /api/shelves`: a placeholder Shelf appears immediately (private
visibility by default), the request runs in a background task, reconciles to the server's
canonical shelf on success, and reverts on failure with the error surfaced via
`AppErrorReporter`. The new shelf slots into the A→Z order. Record the read→write decision
in a short ADR 0004.

HITL: first server write in this domain — needs ADR 0004 sign-off and a create-UX review.

## Acceptance criteria

- [ ] A create card renders at the end of the carousel with a large + and label.
- [ ] Tapping it presents the shelf form (name + optional description).
- [ ] Submitting creates the shelf optimistically; it appears at once in A→Z order.
- [ ] Success reconciles to the server shelf id; failure reverts and surfaces the error.
- [ ] New shelves default to private visibility.
- [ ] Unit tests (mocked `APIServicing`) cover optimistic insert, success reconcile, failure revert.
- [ ] ADR 0004 records the shift from read-only to allowing shelf creation.

## Blocked by

- #0002 (Horizontal snapping shelf carousel)
