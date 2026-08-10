# ADR 0004 — Shelf creation (read-only → write)

- Status: Accepted
- Date: 2026-08-06

## Context

ADR 0003 introduced the bookshelf as a **read-only** view of the user's inventaire.io
shelves: sync + display, no mutations. The bookshelf carousel (PRD 0001) adds a "create"
card at its end so a user can make a new étagère without leaving the app. That is the
first write in the shelf domain.

## Decision

Allow **creating** a shelf from the app. Scope stays deliberately narrow:

- **Create only.** Renaming, deleting, re-ordering shelves and adding/removing books to a
  shelf remain out of scope.
- **Optimistic write** via the existing `OptimisticMutating` runner: a placeholder `Shelf`
  (with an `optimistic:` id) is inserted locally and shown at once (slotting into the A→Z
  order); `POST /api/shelves?action=create` runs in a model-owned background task; on
  success the placeholder is swapped for the server's canonical shelf; on failure it is
  removed and the error surfaced through `AppErrorReporter` (→ SnackBar).
- **Payload** `{ name, description? }`. Visibility is omitted so the server applies its
  default — **private (`[]`)**. Name is required and non-empty.
- **UI**: a trailing carousel card (empty shelf + large `+`) opens `ShelfFormView`, a
  sheet mirroring `ListFormView` (name + optional description).

## Consequences

- The `Shelf` domain is no longer read-only; future writes (rename/delete/file-a-book)
  build on this same optimistic pattern.
- Membership, sync, and the layout invariants from ADR 0003 are unchanged.
- The read-only framing in ADR 0003 is superseded **only** for shelf creation; everything
  else there still holds.
