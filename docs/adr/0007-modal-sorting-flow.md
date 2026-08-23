# ADR 0007 — The sorting flow as one modal, with a start route

- Status: Accepted
- Date: 2026-08-23
- Supersedes: nothing. It generalises what `BatchScanView` already did for a scanning session
  (PRD 0007) and settles how flows are presented from now on.

## Context

Until PRD 0009, "arrange my books into étagères" was a screen pushed into a tab's navigation
stack, reachable through a case of the app-wide `NavigationDestination` enum, from four
places: the étagères screen's toolbar, the home's empty-shelf card, the settings row and its
debug twin. A fifth path pushed the same case from **inside** a modal — the scanning session's
own `NavigationStack`, from the bilan.

Three things broke as the surface was rebuilt (PRD 0009):

- **The screen's only gesture is a drag.** A `.sheet` keeps its drag-to-dismiss, so a book
  picked up too low takes the screen down with it. The surface has to be presented in something
  that has no such gesture.
- **The tab bar is 83 pt of furniture** under a screen whose bottom region is now content — a
  fixed panel carrying the books to file, the recap and the three controls.
- **Two presentations of one screen.** The scan flow pushed it; the four entry points pushed it
  into a *different* stack. Two of them could be live at once, in two tabs, over one app-scoped
  session — and the enum case existed only so that unrelated tabs could name a screen neither
  of them owns.

Meanwhile `BatchScanView` had already grown the shape that works: it owns the modal, its
navigation stack, its close control and its ending, and it swaps the camera for the bilan
inside that cover rather than stacking a second one.

## Decision

**A flow is one `.fullScreenCover`, owning one `NavigationStack`, entered at a route.**

1. **One container per flow.** `SortFlowView` (formerly `BatchScanView`) owns the cover's
   contents: the stack, the close control, the ending, and which screen is at the root. It is
   named after the flow, not after its first screen.
2. **A start route, not two presentations.** `SortFlowStart` is `.scanning` (camera → bilan →
   surface) or `.sorting` (the surface as the root). Onboarding and the scan buttons enter at
   the camera; the home and settings enter at the surface. One container, one implementation of
   the ending.
3. **Routes inside a flow are local to it.** `SortFlowRoute` and `SortSection.ID` are pushed on
   the flow's own stack through `navigationDestination(for:)`. `NavigationDestination` — the
   app-wide enum every tab dispatches on — **loses** its sorting case. The enum gets *smaller*
   as a flow gets richer, because nothing outside the cover can reach inside it.
4. **`.fullScreenCover`, never `.sheet`, for a flow carrying a drag.**
5. **One presentation point for the flow, and it sits above the app's `.refreshable`.**
   `SortFlowPresentation` is app-scoped and injected like every other model; **`RootView`**
   mounts the cover from it, and every entry point — the four that open at the surface and the
   four scan buttons that open at the camera — raises the same flag. A `NavigationLink` in
   settings becomes a `Button`.

   The *where* is not tidiness. `RootView` puts a `.refreshable` on the app, and a cover
   presented from inside that subtree hands the refresh action to every `ScrollView` in the
   flow — which then steals the downward drags the sorting surface is built on.
   `EnvironmentValues.refresh` is read-only, so a flow carrying a drag **must** be presented
   from outside the modifier that provides it. Any future flow with its own gestures inherits
   this rule.
6. **No back button out of a pushed flow step whose predecessor is a receipt.** The bilan
   reports a session that has ended; going back to it after filing would re-offer work already
   done. The surface hides the back button and offers an explicit close.
7. **Closing a flow keeps its draft.** The sorting session is app-scoped, so the close control
   is "step out", not "discard". Throwing work away is a separate, named, confirmed action.

## Consequences

- **A flow's screens are unreachable from outside it.** That is the point, and it is a
  constraint: a deep link into the sorting surface would have to open the flow at `.sorting`,
  not push a screen. Deep links into flows now have exactly one door each.
- **`dismiss` is not enough inside a flow.** In a pushed view it pops, so a screen that has to
  close the *cover* takes the container's own `leave` as a closure. Pushed steps that want out
  must be handed that, not reach for the environment.
- **The SnackBar does not draw above a cover.** `AppErrorReporter` is observed once, in
  `MainTabView`, which is underneath. Flows therefore have to state their own outcomes: the
  sorting surface marks and names the étagères a run failed on, and writes an empty proposal
  into its footer. Accepted deliberately (PRD 0009) rather than moving the SnackBar host.
- **A flow's session state belongs to a model, not to the container.** The container is
  recreated on every presentation; the app-scoped session is what makes closing and reopening
  find the same draft.
- One tab bar's worth of vertical space comes back to the screen, which is what let the books
  to file, the recap and the controls live in an anchored panel.
- **Local `@State` presentation flags are gone from the four scan buttons.** They each owned a
  cover, which was harmless until the flow grew a screen with gestures — at which point the
  presentation's position in the view tree became a behavioural decision rather than a detail.
