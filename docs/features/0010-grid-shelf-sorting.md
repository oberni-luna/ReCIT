# Ranger mes livres, in a grid

Shipped on 2026-08-23 from PRD `docs/prd/0009-grid-shelf-sorting.md`
(issues `issues/0044-verify-grid-drag-and-drop.md` through
`issues/0054-document-the-grid-sorting-surface.md`). Design: Figma `Nouveau récits`, frame
`Ranger mes livres · Light` (`160:6659`), cell `160:6797`, footer `161:6924`.

> Supersedes the **surface** of `docs/features/0009-manual-shelf-sorting.md`, and only the
> surface. The model that feature built — the frozen snapshot, the ordered change stack,
> `SortWritePlan` as a diff of two projections, the awaited apply with its resumable ledger — is
> untouched and is still the reference for how this screen thinks. What is gone is the flattened
> `List` in edit mode, its row-painted cards, its headers-as-drop-targets and the positional
> `displayOrder` its reorder gesture needed.

## What it does

Every étagère is a card on a grid that scrolls — three columns, or two when the collection is
two étagères or fewer: a fanned pile of its first covers, its name, and how many books it holds.
Over it, anchored to the foot of the screen and never scrolling away, a panel holds the books
that are on no étagère as a one-row carousel, then the recap in words, then three controls —
annuler, **Appliquer**, proposer. The grid keeps scrolling *underneath* the panel and dissolves
into it, so nothing is cut off on a line.

A book is filed by dragging it: from the carousel onto a card, from a card's topmost cover onto
another card, or back down onto the panel. Dropping on the grid's « + Nouvelle étagère » tile
opens the create form and files the book into the étagère it creates. A book lands at the front
of its pile with a bounce, which is also where it is picked up from — so a mis-drop is undone by
the reverse gesture. Tapping a card pushes the étagère as it *will be*, drafts and pending books
included, where a swipe takes a book back off it.

Nothing is written until « Appliquer ». While the run writes, the étagères being written breathe
at 80 % opacity and the one in flight carries a spinner; each snaps to full opacity and bounces
its covers in as it lands; one that fails keeps a badge, and the footer says what landed, what
broke and what was never touched. Pressing the button again sends only the rest.

The whole thing is one full-screen flow: scan, bilan, sorting — entered at the camera by
onboarding, straight at the sorting surface from the home and from settings.

## Technical surface

- **New pure modules** (`Model/Sorting/`): `SortGridMetrics` (every measurement from a container
  width), `SortPile` (a card's covers and **which one a drag carries**), `SortBookTransfer` (the
  drag payload). `Model/Utils/DeterministicTilt` is extracted from `ShelfLabelTilt`, amplitude a
  parameter. `SortChange.creation(draftId:name:filling:from:)` is the create-and-fill rule.
- **New feature views** (`Features/Sorting/`): `SortShelvesGridView`, `SortShelfCardCell`,
  `SortShelfCardView`, `SortPileView`, `SortNewShelfTileView`, `SortBookCardView`,
  `SortUnshelvedPanelView`, `SortFooter` / `SortFooterView`, `SortActions`,
  `SortShelfDetailView`, `SortFlowView` (renamed from `Features/Scanner/BatchScanView`),
  `SortFlowRoute`, `SortFilingOption`, and the motion modifiers `SortLandingBounce`,
  `SortStaggeredBounce`, `SortBreathingModifier`, `SortBookDraggable`.
- **New app model**: `AppModels/Sorting/SortFlowPresentation` — app-scoped, one flag, every
  entry point, presented by `RootView` **above** the app's `.refreshable`.
- **Moved to `Features/Components/`**: `ShelfSectionHeader`, and `ShelfCoverView` refactored to
  take `(url, title, size)` with an `InventoryItem` convenience for the shelf screens.
- **Deleted**: `ManualSortListView`, `ManualSortCard`, `ManualSortEmptySectionRow`,
  `ManualSortSectionHeader`, `ManualSortShelfMark`, `Model/Sorting/ManualSortRows` and its test
  suite, `NavigationDestination.manualSort`, and `SortSessionModel.displayOrder` in full.
- **`SortSessionModel`**: `createShelf(named:filling:)` replaces `createShelf(named:)`;
  `moveBook` loses its `order:` parameter; `proposalsLanded` counts arrivals for the animation.
- **Tests**: `SortPileTests`, `SortGridMetricsTests`, `DeterministicTiltTests`,
  `SortCreationTests`, and `SortProjectionTests` rewritten around arrival order. The write-plan,
  landing and ledger suites pass untouched, which is the proof the surface rewrite did not move
  the model.
- **Shared components changed on the way** — worth knowing, because they serve other screens:
  `CachedAsyncImage` stops treating a cancelled load as a failure and gained a
  `contentAlignment`; `ShelfCoverView` gained a `contentMode` and an `alignment` (both default
  to what the shelves had); `VariableBlurView` gained a `strongEdge` and a `fadeSpan`.
- **New ADR**: `docs/adr/0007-modal-sorting-flow.md`.

## Notable decisions

- **No dirty flag in the store.** Persisting pending membership on `InventoryItem.shelves` was
  the owner's opening proposal and was rejected on three counts: inventory sync assigns that
  relation wholesale and is gated only for the duration of one write, so a session lasting
  minutes would be erased under the user's fingers; five unrelated readers of `shelves` would
  render a library that is not the server's; and a mutated target state has no origin, so the
  diff that makes the pill, the recap and the write agree by construction would become three
  hand-kept rules. The session stays in memory, app-scoped, and the pushed detail screen is
  reactive because the *model* is observable — not because SwiftData is.
- **Order inside a section is derived, not carried.** `displayOrder` existed only to hand
  `List` back the permutation its edit-mode reorder had just performed. With no list, the order
  is a function of `(snapshot, changes)`: books this session filed come first, most recent
  first, then snapshot order. That is what makes the front of a pile the book just dropped —
  and the front of the pile is what a drag takes, so the gesture is its own undo.
- **What gets sent still cannot depend on how the screen arranged itself.** `SortWritePlan`
  sorts each operation's ids by snapshot rank explicitly. Before, that held by accident because
  the projection was in snapshot order; now it is stated, because the projection is not.
- **The drag was retried, deliberately, after failing once.** Feature 0009 recorded that
  `draggable` / `dropDestination` "simply did not take" on device. The diagnosis: the payload
  was on `List` rows **in edit mode**, where the list's reorder recogniser owns the long press.
  A throwaway harness and a real XCUITest press-and-drag (issue 0044) showed the drag firing
  from a horizontal `LazyHStack` onto a `LazyVGrid` card in a plain `ScrollView`. Autoscroll
  during a held drag is **not** verified, and the fallback is written into that issue.
- **The origin does not travel in the payload.** The projection is the only thing that knows
  where a book sits; a carried origin can name a section the book has since left. The payload is
  an id under an app-private `UTType`, so a book cannot be dropped into Notes.
- **One cover is the drag source, not the whole card.** The rest of the card taps through to the
  étagère. The narrow source is the app's existing grammar — on a shelf a *book* is pressed, not
  the card around it (ADR 0006) — and it leaves the tap unambiguous.
- **The bottom panel is content, not chrome**, which is why PRD 0008's argument against a pinned
  bar does not apply. Anchored, it keeps the drag's source under the thumb while the
  destinations scroll, keeps the reverse drop on screen, and keeps « Appliquer » one tap away.
  One row of books, not two: a second row is another card's height taken from the grid on every
  screen.
- **The footer is an emplacement, not a line.** Four readings — the recap, a finished run's
  report, a stopped run's three-part account, and « aucun rangement à proposer ». Because the
  panel is anchored it grows *upwards*, so a four-line failure report is readable on a design
  that allots two.
- **The recap doubles as the progress.** It is derived from the write plan, and the plan shrinks
  as each confirmed write leaves the stack, so it counts itself down. No « n sur m » string, no
  second counter, and no way for the two to disagree.
- **« Terminer » is gone.** It was the same button as « Annuler », relabelled when the stack
  emptied, which only made sense on a pushed screen where that button was also the way out. In a
  modal, leaving is the close control; the round discard simply goes inert, and asks before
  throwing away more than one change.
- **The « + » moved out of the navigation bar and into the grid**, as its last tile — at the
  place the action is used, and doubling as the empty state. Dropping a book on it creates the
  étagère and files the book in one call, so a refused name cannot leave a book filed into a
  draft that does not exist.
- **A failure's badge outlives the run**; the breathing and the dimming do not. Étagères the
  plan does not touch dim with the screen but never breathe — one nobody is writing to must not
  look like one waiting its turn, which is PRD 0008's rule in another vocabulary.
- **The animation is kept under Reduce Motion**, on the owner's call, with the spinner on the
  étagère in flight carrying the same information. A deliberate divergence from an accessibility
  setting, recorded as one.
- **A drag is not the only way to file a book.** Book cards carry « Ranger dans… » and étagère
  cards the reverse, recording exactly the change a drop would: the app's recommended way of
  filing books cannot be sighted-only.
- **Covers reserve a 2:3 frame before their image exists.** Natural height was asked for and
  rejected: nothing knows an image's ratio before the bytes arrive, so a pile of five would
  re-lay itself out five times while the grid scrolls.
- **The projection is read once per render**, by the root view, and value types go down. It is
  recomputed on every read by design (PRD 0008), so a card reading it in its own body would
  walk the whole library per card per animation frame.

## What the device changed

Everything above is what shipped from the slices. What follows is the record of four rounds of
use on a real phone with a real library, grouped by what they touched rather than by the order
they arrived in — because two of them were the same bug wearing different clothes.

### Layout and chrome

- **Two columns for two étagères or fewer.** Three narrow cards with two empty slots read as a
  screen that failed to load rather than as a small library. The width formula is generalised —
  `(width − (columns + 1) × 16) / columns` — so a row fills its width exactly at either count.
  The « + » tile does not count towards the threshold: it is an affordance, not an étagère.
- **White throughout, structure by outline.** The grey backdrop is gone. Cards carry a token
  border which becomes the accent border while a book hovers, rather than gaining a second one;
  the rule between regions is **black at 20 %**, because a token border reads as a drawn line on
  white where what is wanted is the shadow of one. Nothing has rounded corners any more.
- **The panel floats over the grid** (`safeAreaInset`) instead of sitting beside it, so the
  étagères keep scrolling underneath and dissolve into it: a white gradient from nothing at its
  top edge to solid at the controls, with `VariableBlurView` ramping the same way beneath. Both,
  not either — the gradient alone left scrolled covers competing with the buttons, the blur alone
  left them sharp behind white text. The blur fades over **45 %** of the height and holds full
  radius for the rest: at full span the radius near the top edge is barely anything, and
  « Livres à ranger » sat over sharp covers. Half-opaque white sits behind the controls from the
  rule down, because they are the one thing that must stay readable whatever scrolls past.
- **The hairline separates the controls from the books**, not the region from the grid — that
  edge is the gradient's job now.
- **The books-to-file cells hang from their top edge**, with 2 pt of vertical padding and their
  titles in `content300` (Alegreya Medium 17) over two lines. Centred, a one-line title and a
  two-line title put their covers on different lines and a row read as ragged.
- **No « · 0 » on an empty étagère**: the dashed hole in its art already says it.
- **One close control.** The flow's own cross showed alongside the surface's, and it ended a
  scanning session that was not running.
- **The étagère's own screen is one `Section`** with a footer naming the swipe, on white, which
  is what removed the two part-width separators floating above the first row and under the last.

### The gesture

- **The handle is the cover, never the card.** Attached to the card — 100 × 158 pt of mostly
  transparent background — every press in its margins started a drag and the carousel could not
  be panned at all.
- **The lifted object is the cover as drawn, square and whole.** Two causes, found one after the
  other: a custom preview closure builds a *fresh* `CachedAsyncImage` that the drag session
  snapshots before Nuke can hand the image over, so what travelled was the parchment placeholder
  with a title on it; and on an étagère card the drag was attached *above* the tilt, so it lifted
  a rotated cover clipped by its card. No closure, and attached below the rotation.
- **The pile fans both ways** around its front cover. Opening rightwards only walked a shelf of
  five off towards the card's edge, away from the book a drag would take.
- **The drop badge takes the app's tint.** The system draws the drag session's « + » in the
  accent colour, and a cover does not inherit the app's `.tint`.

### Images — one bug behind three symptoms

**A cancelled image load is no longer a failure** (`CachedAsyncImage`). Covers vanished from the
piles and from the carousel once several books moved at once; a pile looked two books short; and
leaving the screen and coming back put it right. All three were the same thing: the component
draws **nothing at all** in its failed state — not even the parchment placeholder — and
`.task(id:)` does not run again for the same id. Lazy containers recycle their cells and a
re-diffing list tears views down mid-flight, both of which cancel the load, and the `catch`
treated that as a failure. So a blank frame latched until the view's identity changed, which is
exactly what a round trip through the detail screen does. Cancellation is now told apart from a
genuine failure and leaves the state untouched, so the next appearance retries against Nuke's
memory cache. A real failure still draws nothing, deliberately: a broken URL must not leave a
parchment slab on screen forever.

Two consequences worth knowing:

- **Covers fill their frame on this screen** (`ShelfCoverView` gains a `contentMode`, still
  `.fit` everywhere else). A fitted cover leaves transparent bands inside its frame, and a drag
  lifts the bands with the artwork.
- **A lone cover now stands on its plank** (`alignment`, `.bottom` on the shelf's single cover
  and on the onboarding plank's). `ShelfBooksLayout` reserves a fixed 0,66 portrait and a real
  cover rarely matches it, so a wider one — a comic album, an art book — is letterboxed and,
  centred, hovered above the plank. The geometry was always like that; fixing the cancelled
  loads is what made it visible, since parchment fills the frame and a real cover does not.

### Interaction

- **One swipe takes one book off.** A `List` can re-diff under its own swipe animation and fire
  the action again for the row that has taken the swiped one's place. Both ends refuse it: the
  screen re-reads the book from the session before acting, and `moveBook` ignores a move to
  where the book already sits — which protects every caller rather than each one separately.
- **Removing a book from an étagère's screen animates**, with the transaction at the mutation
  rather than on the list: the rows come out of the projection, so the row that leaves and the
  ones closing up behind it are one change to one observable.

### The presentation trio, and the crash between its two halves

Getting the flow out from under the app's pull-to-refresh took two attempts and produced one
crash on the way. The order of three modifiers is the whole mechanism, and each position is
load-bearing:

```
MainTabView
  .refreshable { … }          // innermost: reaches the tabs, stops short of the cover
  .fullScreenCover { flow }   // above it: the flow keeps the downward drags a book is filed with
  .environment(…)             // outermost: the cover is inside these, so the flow finds them
```

A `.refreshable` above the cover hands its action to every `ScrollView` in the flow, which then
steals the drags this screen is built on, and `EnvironmentValues.refresh` is read-only so it
cannot be cleared from within. But a cover above the `.environment` calls inherits none of them
and crashes on the first model it reads. Both were shipped and both were fixed. It is recorded
in ADR 0007 because the next flow with a gesture of its own will face it.

Its other consequence: the scan buttons no longer own their own covers. Every entry point —
four at the surface, four at the camera — raises one app-scoped flag.

## Known gaps

- **Autoscroll during a drag is unverified.** See issue 0044 for the fallback design.
- **The drag payload's `UTType` is exported without an `Info.plist` declaration**, because the
  target generates its plist. Within the app that is enough — the type is unknown to other apps,
  which is the property being bought. Declare it the day a drop must cross an app boundary on
  purpose.
- **Apply ordering**, inherited from feature 0009: operations are grouped per étagère in screen
  order, so a book moving to an étagère that sorts earlier gets its addition before the removal
  that frees it, and a failure in between leaves it on two étagères until the resume.
- **The étagère gutter is 16 pt in code against the mockup's 12 pt**, per the owner's formula
  (divergence D45).
- **The twelve generated state frames predate the design passes above.** They were built from the
  nominal frame as it stood on 2026-08-23 — grey backdrop, a hairline on top of the panel, centred
  book cells, no gradient. They still describe the right *states*, and the wrong skin.
  Regenerating them is a design pass of its own.
- **`VariableBlurView` reaches private QuartzCore API and now has two callers**, not one. The risk
  it documents at its own definition is no longer confined to a secondary screen. Removing it is
  still a file deletion plus two call sites, and the worst case degrades to a uniform blur.
- **The panel's transparent top edge is still a drop target.** A book let go over an étagère card
  seen *through* the gradient is filed into « à ranger ». It is a few points tall and nobody has
  hit it yet; the fix, if it bites, is to shrink the target to the opaque part.
- **The device verdict on the gesture is in**, and it takes — the remaining unknown is only the
  autoscroll above.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> To read them: `git log --diff-filter=D --oneline -- issues/` then `git show <commit>^:<path>`.

- `issues/0044-verify-grid-drag-and-drop.md` — does the drag take — commit `0da1256`
- `issues/0045-figma-frames-for-the-grid-surface.md` — the twelve missing frames — commit `4042de6`
- `issues/0046-grid-sorting-surface-read-only.md` — the surface, read-only — commit `80b7b71`
- `issues/0047-drag-a-book-between-sections.md` — the gesture, both ways — commit `7436f44`
- `issues/0048-new-shelf-tile-and-drop-to-create.md` — the tile — commit `9e9330f`
- `issues/0049-pending-shelf-detail-screen.md` — the étagère as it will be — commit `6759eb0`
- `issues/0050-apply-feedback-on-the-cards.md` — a save, happening — commit `77a0461`
- `issues/0051-proposal-button-in-the-action-bar.md` — the model as a button — commit `2391f14`
- `issues/0052-scan-then-sort-modal-flow.md` — one modal flow — commit `c9363bf`
- `issues/0053-file-a-book-without-dragging.md` — without a drag — commit `326afde`
- `issues/0054-document-the-grid-sorting-surface.md` — this document — commit `54896af`

## Follow-up commits

The device rounds, in order, so a bisect has names to work with:

- `93cdc21` — two columns, the carousel scrolls, the cover travels, square corners
- `892aafa` — white throughout, one close control, the section-based étagère screen, no
  pull-to-refresh in the flow
- `9d54be4` — the flow's cover gets the models it needs (the crash above)
- `6ed4c23` — the modifier order, in ADR 0007
- `b693ba6` — covers fill, book titles at 17 pt, one swipe one book
- `7656696` — a cancelled image load stops latching as a failure
- `ded0b4d` — the grid dissolves into the panel
- `1014cd9` — a faster fade, half-opaque white behind the controls, a softer rule
- `bea51d9` — a lone cover stands on its plank
