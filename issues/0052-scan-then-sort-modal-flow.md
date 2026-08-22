## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

One modal flow for scanning and filing, entered at either end.

- **`.fullScreenCover`, never `.sheet`**: a sheet's drag-to-dismiss fights the screen's
  drag-and-drop.
- **One container** owns the cover, its `NavigationStack`, its close control and its ending —
  the role `BatchScanView` already plays. It is renamed to say so, and given a **start route**:
  `.scanning` (camera → bilan → sorting) or `.sorting` (straight to the sorting screen).
  Onboarding enters at the camera; the home and settings entry points enter at sorting.
- **Routes are local to the flow** — the sorting screen, and an étagère by `SortSection.ID`,
  which is already `Hashable`. `NavigationDestination.manualSort` is **deleted** from the
  app-wide enum, and the four entry points (`ShelvesView`, `ShelvesContent`, `ProfileView` —
  today a `NavigationLink`, which becomes a button — and `ProfileDebugSection`) present the
  cover instead of appending to a tab's path.
- **No back out of the sorting screen**, whichever route was taken. The bilan is the receipt of
  a session that has already ended, and re-offering « Ranger mes livres » after a save would be
  a lie. The back chevron is replaced by an explicit close.
- **Closing keeps the draft.** The session is app-scoped and a user who leaves must find their
  work as they left it. The only thing that throws work away is the discard control — which
  **asks for confirmation** when the stack holds more than one change, and is inert when it is
  empty. « Terminer » therefore disappears: leaving is the close control.
- The bilan doubles as the invitation to file; no screen is added between it and the sorting
  screen.
- Accepted, and stated here so it is not re-litigated: `AppErrorReporter`'s SnackBar is owned
  by `MainTabView` and may not draw above the cover. This screen states its own failures —
  failed étagères are marked and named, an empty proposal is written in the footer — and an
  opening-sync failure stays swallowed, as it already was.

## Acceptance criteria

- [ ] Sorting opens as a full-screen cover, with no tab bar and no drag-to-dismiss.
- [ ] From the home and from settings, the cover opens directly on the sorting screen.
- [ ] From a scanning session, the camera, the bilan and the sorting screen follow one another
      in one stack, inside one cover.
- [ ] The sorting screen offers no way back to the bilan, and an explicit close instead.
- [ ] Closing with pending changes and reopening finds the session unchanged.
- [ ] The discard control asks for confirmation above one pending change, and is inert with
      none.
- [ ] `NavigationDestination` no longer has a sorting case, and no entry point appends one.
- [ ] The étagère detail screen pushes inside the flow's own stack.
- [ ] Onboarding still reaches the camera automatically on first launch.

## Blocked by

- `issues/0046-grid-sorting-surface-read-only.md`
