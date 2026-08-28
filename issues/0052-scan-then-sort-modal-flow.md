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
- ~~The bilan doubles as the invitation to file; no screen is added between it and the sorting
  screen.~~ **Withdrawn — see the amendment below.**
- Accepted, and stated here so it is not re-litigated: `AppErrorReporter`'s SnackBar is owned
  by `MainTabView` and may not draw above the cover. This screen states its own failures —
  failed étagères are marked and named, an empty proposal is written in the footer — and an
  opening-sync failure stays swallowed, as it already was.

## Amendment — the bilan gains a step, and the step is a screen

> **Amended before building.** The rule above said no screen may come between the bilan and the
> sorting screen. It is withdrawn: on a phone that can run the model, « Rangement automatique »
> pushes a **loading screen** while the proposal is computed, and that screen is replaced by the
> sorting surface carrying the proposal. On a phone that cannot, « Ranger mes livres » still
> goes straight to the sorting surface with nothing in it but « À ranger ».
>
> The withdrawn rule was written to keep the flow short. The model's wait is the one thing in
> this flow that is genuinely slow, and the alternatives are worse: a spinner on the bilan holds
> a screen the user has finished reading, and a sorting surface that arrives empty and fills
> itself in reads as a bug the first time the proposal is slow.
>
> **This does not weaken the no-back rule.** The loading screen is *replaced* by the sorting
> surface rather than pushed under it, so the sorting surface still has no back to the bilan and
> still leaves through its explicit close. Backing out of the loading screen itself is fine and
> means "never mind" — nothing has been computed or written yet.
>
> Asked for on a device pass, and specified in
> `issues/0062-tally-leads-into-the-sorting-surface.md`, which carries the two CTAs, the three
> unavailability cases and the mid-load failure. This issue owns the container and the stack;
> that one owns what the bilan offers.

## Acceptance criteria

- [ ] Sorting opens as a full-screen cover, with no tab bar and no drag-to-dismiss.
- [ ] From the home and from settings, the cover opens directly on the sorting screen.
- [ ] From a scanning session, the camera, the bilan and the sorting screen follow one another
      in one stack, inside one cover — with the loading screen between the last two where the
      model runs.
- [ ] The loading screen is replaced by the sorting surface rather than pushed under it, so the
      surface never has a back chevron to the bilan.
- [ ] Backing out of the loading screen itself returns to the bilan, having computed and written
      nothing.
- [ ] The sorting screen offers no way back to the bilan, and an explicit close instead.
- [ ] Closing with pending changes and reopening finds the session unchanged.
- [ ] The discard control asks for confirmation above one pending change, and is inert with
      none.
- [ ] `NavigationDestination` no longer has a sorting case, and no entry point appends one.
- [ ] The étagère detail screen pushes inside the flow's own stack.
- [ ] Onboarding still reaches the camera automatically on first launch.

## Blocked by

- `issues/0046-grid-sorting-surface-read-only.md`
