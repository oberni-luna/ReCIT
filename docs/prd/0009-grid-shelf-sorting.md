# PRD 0009 — Ranger mes livres, in a grid

Supersedes the **surface** of `docs/features/0009-manual-shelf-sorting.md` (PRD 0008). The
model that feature built — frozen snapshot, ordered change stack, one write plan derived as
a diff, awaited apply with a resumable ledger — is kept whole. What is replaced is
everything the user touches: the flattened `List` in edit mode, its row-painted cards, its
headers-as-drop-targets, and the positional `displayOrder` the reorder gesture needed.

Design: Figma `Nouveau récits`, frame `Ranger mes livres · Light` (`160:6659`), cell
`160:6797`, footer `161:6924`.

## Problem Statement

The sorting surface works as a list, and a list is the wrong shape for the job.

- **The library does not read as a library.** Every étagère is a band of full-width rows,
  so four étagères and thirty books fill three screens of scrolling. The user cannot see
  their scheme — the thing they are supposed to be arranging — without scrolling past it.
- **The gesture is borrowed.** Crossing sections is impossible with `List`'s own move, so
  the surface flattens headers and books into one `ForEach` held in edit mode. Every
  consequence of that trick is visible: grips down the left edge, a card repainted row by
  row from `isCardTop` / `isCardBottom`, an empty étagère with no row of its own whose
  *header* has to be the drop target, and a positional order (`displayOrder`) that exists
  only to stop the drop animating twice.
- **A book cannot be filed where the eye is.** Dropping onto the twelfth étagère means
  dragging a row through eleven others, and the destination is a boundary between rows
  rather than a thing.
- **« Appliquer » is at the bottom of everything.** With a large collection the button that
  saves the work is several screens below the work.
- **An étagère cannot be inspected while sorting.** What an étagère *will* hold once the
  session is applied is visible only as rows scattered under a header. There is no way to
  open one, read it, and take a book back off it.

## Solution

One screen, two regions, and a book that is dragged from one to the other.

**The scrolling region is the collection.** Every étagère is a card on a three-column grid:
a fanned pile of its first covers, its name, and how many books it holds. The last cell of
the grid is a **« + Nouvelle étagère » tile**, so the scheme can grow at the point where it
is being used — and an empty grid is that tile alone, which says what to do without an
empty-state screen of its own.

**The anchored region is the work left to do.** « Livres à ranger · n » sits in a panel at
the foot of the screen that never scrolls away: a horizontal carousel of the books on no
étagère, then the recap in words, then three controls — annuler, **Appliquer**, proposer.
Because the panel is fixed, the source of every drag stays under the thumb while the grid
of destinations scrolls beneath the finger, and the button that saves is always one tap
away.

**A book is filed by dragging it, in either direction.** From the carousel onto a card; from
a card — by its topmost cover — onto another card, or back down onto the panel. Dropping on
the « + » tile opens the create form and files the book into the étagère it creates. The
book lands **on top** of the pile with a bounce, which is also where it is picked up from,
so a mistake is undone by the same gesture that made it.

**An étagère opens as it will be, not as the server has it.** Tapping a card pushes a
detail screen rendered from the session's projection — pending books included, drafts
included, since a draft has no server document to read. A swipe there takes a book off the
étagère and back into « à ranger ». Nothing is written.

**Nothing is written until « Appliquer ».** Unchanged from PRD 0008, and still the point of
the screen. While the run writes, the cards being written breathe at 80 % opacity; each one
snaps to full opacity and bounces its books in as it lands; one that fails keeps a badge,
and the footer says what landed, what broke, and what was never touched. Pressing the
button again resumes.

**The whole thing is a flow, presented modally.** Scanning, the bilan, and the sorting
screen are one full-screen cover with one navigation stack — entered at the camera by
onboarding, or straight at the sorting screen from the home. There is no way back out of
sorting except closing, and closing keeps the draft.

## User Stories

1. As a user with a scanned library, I want every étagère on one screen as a card, so that I
   can see the scheme I am filing into without scrolling through its contents.
2. As a user, I want each card to show a pile of its own covers, so that I recognise an
   étagère by its books and not only by its name.
3. As a user, I want the number of books written beside an étagère's name, so that I can tell
   a shelf of three from a shelf of three hundred before I drop anything on it.
4. As a user, I want the books that are on no étagère gathered in one panel at the bottom of
   the screen, so that the work left to do is always in front of me.
5. As a user, I want that panel to stay put while the étagères scroll, so that I never have to
   scroll with a book already in my hand.
6. As a user, I want to drag a book from the panel onto an étagère's card, so that filing a
   book is one movement onto the thing itself.
7. As a user, I want the book to land on top of the pile with a bounce, so that I can see
   where it went.
8. As a user, I want to feel a light tap when the book lands, so that I know the drop took
   without watching the card.
9. As a user, I want the card I am hovering to grow and light up, so that I know which
   étagère will receive the book before I let go.
10. As a user, I want to drag the top book off an étagère, so that a wrong drop is undone by
    the same gesture that made it.
11. As a user, I want to drag a book straight from one étagère to another, so that changing my
    mind does not mean two trips through the panel.
12. As a user, I want to drop a book back onto the panel, so that taking a book off a shelf is
    as easy as putting it on.
13. As a user, I want a book dropped back on the étagère it came from to change nothing, so
    that a hesitant gesture is not recorded as work.
14. As a user, I want the preview under my finger to be the book's cover, so that I can see
    what I am carrying.
15. As a user, I want a « + Nouvelle étagère » tile at the end of the grid, so that I can
    create an étagère at the moment I discover I need one.
16. As a user, I want to drop a book onto that tile, so that creating an étagère and filling it
    is a single movement.
17. As a user who cancels the create form after such a drop, I want nothing to have happened,
    so that a change of mind costs nothing.
18. As a user, I want to be refused a name an étagère or a draft already has, while I am still
    looking at the field I typed it into.
19. As a user who has just created an étagère, I want the screen to scroll to it, so that I can
    see it exists.
20. As a user with no étagère at all, I want the tile alone on the screen, so that the only
    thing I can do is the thing I should do.
21. As a user, I want to tap an étagère's card and read what it will hold, pending books
    included, so that I can check my work before saving it.
22. As a user, I want to open an étagère I created a minute ago and have never saved, so that a
    draft is inspectable like any other étagère.
23. As a user on that screen, I want to swipe a book off the étagère, so that I can correct a
    filing without dragging.
24. As a user, I want that swipe to be neither red nor destructive, so that I am not taught to
    fear an action that costs one tap to undo.
25. As a user, I want the book I swipe off to reappear among the books to file, so that it is
    never lost.
26. As a user, I want the pile on a card and the list on the detail screen in the same order, so
    that the book I saw on top is the one at the top.
27. As a user, I want the recap to say in words what saving will do, so that I know what I am
    approving.
28. As a user, I want « Appliquer » always visible, so that saving never means scrolling.
29. As a user, I want a single control that throws the session away, so that starting over is
    possible.
30. As a user, I want that control inert when there is nothing pending, so that it cannot
    destroy work that does not exist.
31. As a user with a session in progress, I want to be asked before it is thrown away, so that
    one mis-tap does not undo an hour of filing.
32. As a user, I want to close the screen and find my session as I left it, so that sorting can
    be done in several sittings.
33. As a user, I want the étagères being written to breathe while the save runs, so that I can
    see the work happening.
34. As a user, I want an étagère to snap to full opacity and bounce its books in as it lands, so
    that progress is legible without reading anything.
35. As a user, I want a spinner on the étagère currently being written, so that I can follow the
    run even with animations turned down.
36. As a user, I want the étagères nobody is writing to left alone, so that nothing looks like
    it is waiting its turn when it is not.
37. As a user, I want every control dead while the save runs, so that I cannot rearrange a
    library that is being written.
38. As a user whose save broke halfway, I want the étagère it broke on marked, so that I know
    which one to look at.
39. As a user whose save broke halfway, I want to read what landed, what broke, and what was
    never touched, so that I know what is mine now.
40. As a user whose save broke halfway, I want pressing « Appliquer » again to send only the
    rest, so that recovery is not a fresh start.
41. As a user, I want the recap to shrink as the run lands, so that what is left to save is
    always what it says.
42. As a user, I want to ask the phone for a proposal from the same screen, so that help is one
    button among my own gestures.
43. As a user, I want a proposal to arrive as ordinary pending changes, so that I can adjust it
    by dragging instead of accepting or refusing it whole.
44. As a user, I want the cards that a proposal touched to bounce their new books in, so that
    the biggest change of the session is visible.
45. As a user whose proposal produces nothing, I want to be told so, so that the button does not
    look broken.
46. As a user on a phone that cannot run the model, I want no proposal button at all, so that I
    am not offered something impossible.
47. As a user who has Apple Intelligence switched off, I want to be able to tap the button and
    read why it is inert, so that I know it is my setting and not a bug.
48. As a user arriving from a scanning session, I want the bilan and the sorting screen to
    follow one another in one flow, so that filing what I just scanned is the same movement as
    scanning it.
49. As a user arriving from the home, I want to land straight on the sorting screen, so that I
    do not walk through a scan I did not ask for.
50. As a user on the sorting screen, I want no way back to the bilan of a session that has
    already ended, so that I am not re-offered work I have done.
51. As a user, I want the screen to say it is loading while it re-syncs, so that I am not
    arranging a stale library.
52. As a user, I want the bottom panel's shape not to jump when the library arrives, so that the
    screen does not move under my thumb.
53. As a user who has filed everything, I want the panel to stay with a « tout est rangé »
    line, so that I can still take a book back off an étagère — and so that the emptiness is
    the proof I am finished.
54. As a user, I want the piles to lean slightly and differently, so that the shelves look
    handled rather than generated.
55. As a user, I want a given étagère's pile to lean the same way every time I open the screen,
    so that the app does not look unstable.
56. As a user with a large collection, I want the grid and the carousel to scroll smoothly, so
    that filing three hundred books is not a chore.
57. As a user of a screen reader, I want a way to file a book without dragging, so that the
    recommended path through the app is open to me.
58. As a French-speaking user, I want every count and every plural written correctly, so that
    the screen does not read as machine output.

## Implementation Decisions

### The model is kept; only the surface is rebuilt

- **No dirty flag in the store.** Persisting pending membership on `InventoryItem.shelves` /
  `Shelf.items` was considered and rejected: inventory sync assigns that relation wholesale
  from the server payload and is only gated for the duration of one write, so a session
  lasting minutes would have its pending state erased; five unrelated readers of `shelves`
  would render a library that is not the server's; and a mutated target state has no origin,
  so the diff that makes the pill, the recap and the write agree by construction would have
  to be rewritten as three hand-kept rules. The store stays a cache of server state
  (ADR 0001).
- **The session stays in memory**, app-scoped and `@Observable`, exactly as PRD 0008 built
  it. Reactivity across screens comes from the model, not from SwiftData: the pushed detail
  screen renders the same projection. Persisting the *stack* (a single encoded row) was
  identified as the only sane variant of the dirty-flag idea and is out of scope — it buys
  survival across an app kill and nothing else.
- Frozen snapshot, ordered change stack, `SortWritePlan` as a diff of two projections,
  awaited apply, `SortApplyLanding` trimming the stack per confirmed call, resumable
  ledger: all unchanged.

### The order inside a section is derived from the stack

- `displayOrder` is **deleted** — the property, the `order:` parameter on `moveBook`, the
  `SortProjection` parameter, and every reset of it. It existed to hand the list the
  permutation the list had just performed; there is no list any more.
- A section's books are ordered **by arrival**: books the session moved in come first, most
  recently moved first, then snapshot order (inventory `created` desc). Pure function of
  `(snapshot, changes)`.
- Consequence, and the reason for the rule: **the top of a pile is the book just filed**, so
  the book that is picked up is the book that was dropped, and a mis-drop is undone by the
  reverse gesture.

### Geometry is a pure module

- `SortGridMetrics` derives, from a container width: étagère column `W = (width − 4×16) / 3`
  (16 pt margins and gutters — 112,33 on a 393 pt screen), book column
  `(width − 16 − 3×12 − 40) / 3` (16 pt margin, three 12 pt gutters, a 40 pt peek of the next
  card — 100 on 393), card height 158, cover ratio 2:3, carousel height.
- The carousel is **one row** with a peek, not two: two rows cost another ~174 pt of the
  anchored panel, which is height taken from the grid on every screen.
- Divergence from the mockup: the mockup's étagère gutter is 12 pt; the code uses 16 pt per
  the owner's formula. The book column's 12 pt gutter and 40 pt peek follow the mockup.

### The pile is a pure module

- `SortPile` maps a section to what its card draws: up to **five** covers (`min(count, 5)`),
  each with a rank, a depth, and a tilt; and names **which one is draggable** — the topmost.
  Position ↔ rank is fixed, so the book grabbed is always the book seen.
- One book renders as its cover alone; zero books render as an empty frame of the same size,
  which is a drop target and is the normal state of a freshly created draft.
- Tilt is `±10°`, derived from the book's title by the deterministic angle machinery
  **extracted from `ShelfLabelTilt`** (djb2 over Unicode scalars + splitmix64 finalizer,
  never `String.hashValue`, which is seeded per process). One rule, two amplitudes: ±1° for
  paper labels, ±10° for covers.
- Cover art reuses the inventory's renderer — rounded 2 pt, shadow `black 22 %, radius 3,
  x 1, y 2` — refactored to take `(url, title, size)` instead of an `InventoryItem`, since
  this screen holds value types only. The shadow is kept in dark mode: it reads against the
  covers behind it.
- Covers reserve a **2:3 frame before the image exists**. Natural height was asked for and
  rejected: neither Nuke nor `Edition` knows an image's ratio before the bytes arrive, so a
  pile of five would re-lay itself out five times while the grid scrolls.

### The gesture

- SwiftUI `draggable` / `dropDestination`, retried deliberately. The failure recorded in
  feature 0009 was contextual: `draggable` on `List` rows **in edit mode** loses the long
  press to the list's own reorder recogniser. A `ScrollView` + `LazyVGrid` has no competing
  recogniser.
- Payload: `SortBookTransfer`, a book id under an **app-private `UTType`**, so a book cannot
  be dropped into Notes or Messages. The origin is **not** carried — the session resolves it
  from the projection, so a payload cannot name a stale origin.
- Drag preview: the book's cover.
- Drop targets: **the whole étagère card** (title included), the **whole « à ranger » panel**
  (order there is arrival order, so aiming at a slot would mean nothing), and the **« + »
  tile**.
- Drag sources: a **book card** in the carousel, and the **topmost cover only** of an étagère
  card. The rest of the card taps through to the detail screen. Same grammar as the
  inventory, where a book is pressed rather than its card (ADR 0006).
- A tap on a book card does nothing: the card is a handle, and opening a book screen mid-sort
  is a way to lose the session's thread.
- Hover: card scale 1,03 plus an accent border, one `impact(.soft)` on entry only. Landing:
  the arriving cover appears at scale 1,15 and −12 pt in Y, settling on
  `.spring(response: 0.32, dampingFraction: 0.55)`, with an `impact(.light)`.
- A drop on the section a book already sits in produces no change, no bounce and no haptic —
  `SortChange.move` already returns `nil` for it.

### The screen's two regions

- Scrolling region: `LazyVGrid`, three fixed columns, étagère cards in snapshot order
  (server étagères A→Z, then drafts in creation order), then the « + » tile.
- Anchored region, in the safe area: section header, `LazyHStack` carousel, a **variable
  text slot**, and the action bar. Because it is anchored, the slot grows upward and the grid
  shrinks — which is what lets a four-line failure report be read without a tap.
- The text slot has four readings: the recap while idle **and while the run writes** (the
  recap is derived from the write plan, and the plan shrinks as landings trim the stack, so
  the recap *is* the progress — no second counter, no new plural strings); the success
  report; the stopped report with its three parts; and « aucun rangement à proposer » when a
  proposal comes back empty.
- Action bar, in order: round **annuler**, primary **Appliquer**, round **proposer**. Two
  buttons instead of three on a device that cannot run the model. « Terminer » disappears:
  leaving is the close control, and the round annuler is inert when the stack is empty.
- Annuler asks for confirmation when the stack holds more than one change.
- The nav bar's « + » is **removed**: creating an étagère is the grid's tile, at the point of
  use, and one action has one control on a screen.

### The flow is one modal

- `.fullScreenCover`, never `.sheet`: a sheet's drag-to-dismiss fights a drag-and-drop
  gesture.
- **One container** owns the modal, its `NavigationStack`, its close control and its ending —
  the role `BatchScanView` already plays, renamed and given a **start route**: `.scanning`
  (camera → bilan → sorting) or `.sorting` (straight to the sorting screen). Onboarding
  enters at the camera; the four home and settings entry points enter at sorting.
- Routes are **local** to the flow (sorting, and an étagère by `SortSection.ID`, which is
  already `Hashable`). `NavigationDestination.manualSort` is deleted from the app-wide enum,
  and the `NavigationLink` in the profile becomes a button.
- **No back from the sorting screen**, whichever route was taken: the bilan is the receipt of
  a session that has ended, and re-offering « Ranger mes livres » after a save would be a
  lie. The close control is explicit (a cross), and closing **keeps** the draft.
- The bilan doubles as the invitation to sort; no screen is added between them.
- Errors reported by `AppErrorReporter` surface in a SnackBar owned by `MainTabView`, which
  may not draw above a cover. Accepted: this screen states its own failures — failed
  étagères are marked and named, and an empty proposal is said in the text slot.

### Creating an étagère

- `createShelf(named:filling:)` replaces `createShelf(named:)`: one call, one set of guards,
  appending the creation and — when the caller passes a book — the move into it. Two separate
  calls would let a future caller file a book into a draft that was refused, which the
  projection would silently ignore.
- The create form is the existing draft-returning form, with the existing name rule (a name
  already borne by an étagère **or** a draft is refused). A duplicate name is not quietly
  re-routed into the homonym.
- After creation: scroll to the new card **first**, then bounce the book in.
- Renaming a draft is out of scope; there is no `renameShelf` change.

### Applying

- Writes stay awaited, per-étagère, stopping where they break, resumable by pressing the
  button again — unchanged.
- While the run writes: the grid and the carousel drop to 80 % opacity and stop accepting
  touches; the étagères **the plan writes to** breathe (scale 1,00 ↔ 1,02, 1,2 s,
  `easeInOut`, in phase) and carry a spinner; étagères the plan does not touch neither dim
  nor breathe.
- As each étagère lands: back to full opacity, and its visible covers bounce in one at a
  time, 0,08 s apart — the stagger already used by the onboarding plank.
- A failed étagère keeps a warning badge after the run settles. Étagères never attempted
  return to normal and keep their work in the stack.
- **Deliberate divergence:** the breathing loop and the bounces are kept under Reduce Motion,
  on the owner's call; the spinner is what carries the information when a user has animations
  turned down.

### Accessibility

- A custom accessibility action on each book card — « Ranger dans… » — lists the étagères and
  files the book, so the screen is usable without a drag. The étagère card exposes the
  reverse for its top book.

## Testing Decisions

A good test here states a rule the user can see and asserts it on values: given a snapshot
and a stack, *this* is the order; given a width, *this* is a column. It never reaches into a
view, a store or a network, and it never asserts that a particular method was called. Prior
art in the repo: `SortProjectionTests`, `SortWritePlanTests`, `SortApplyLandingTests`,
`SortDraftNameRuleTests`, `ShelfLabelTiltTests`, `ShelfBooksLayoutTests` — all Swift Testing
suites over pure types.

Tested modules:

- **`SortProjection`** (updated suite): a book moved this session comes first in its section;
  the most recent move wins; books nobody moved keep snapshot order behind them; a move
  inside a section changes the order but records nothing; the existing invariant — every
  book in exactly one section — still holds. The `displayOrder` cases are deleted.
- **`SortPile`**: at most five covers; one book yields one cover; zero books yield an empty
  pile; ranks and depths are stable; **the draggable book is the first of the section**,
  which is the assertion that stops the wrong book being grabbed.
- **`DeterministicTilt`**: within ±amplitude; identical for identical text across processes
  (the `hashValue` trap); accented French titles spread rather than collapse; ±1° and ±10°
  amplitudes both behave.
- **`SortGridMetrics`**: étagère and book column widths, gutters, peek and heights at 320 /
  375 / 393 / 430 pt — the sizes that silently break on a small phone.
- **`SortSessionModel.createShelf(named:filling:)`**: a refused name appends **nothing**
  (neither creation nor move); an accepted name appends exactly two changes in order; a
  busy session appends nothing.
- **`SortWritePlan` / `SortApplyLanding` / `SortApplyLedger`**: existing suites must keep
  passing untouched. They are the proof that the surface rewrite did not move the model.

No UI test for the drag: XCUITest over drag-and-drop is flaky, and the one thing worth
knowing — that the gesture takes on a device — is exactly what a simulator run does not
say. A device spike covers it once, before the screen is built: does `draggable` fire in a
`LazyVGrid`, does it fire from inside a horizontal carousel, and does the grid autoscroll
while a drag is held near its edge.

## Out of Scope

- Persisting the change stack across an app kill.
- Renaming or deleting an étagère from the sorting surface (`ShelfFormView` writes
  immediately; this screen writes nothing).
- Reordering books inside an étagère as a saved property — membership carries no server-side
  order, and the pile's order is a reading of the session.
- Opening a book's detail screen from the sorting surface.
- Two rows in the carousel.
- Any change to the AI proposal pipeline itself; only its button and the landing animation
  are touched.
- The known apply-ordering gap inherited from feature 0009: operations are grouped per
  étagère in screen order, so a book moving to an étagère that sorts earlier gets its
  addition before the removal that frees it, and a failure in between leaves it on two
  étagères until the resume.

## Further Notes

**Risks, in the order they can bite.**

1. **The drag may not take.** It did not, once, in a `List` in edit mode. The diagnosis is
   that edit mode was the cause, but the spike comes before the screen so that a wrong
   diagnosis costs 30 lines rather than a rebuilt surface. Fallback: a `DragGesture` with an
   overlay redrawing the cover under the finger and targets resolved from
   `anchorPreference` — the mechanism the press-to-select overlay already uses (ADR 0006),
   ~150 lines to maintain against ~10.
2. **Autoscroll while dragging.** `UICollectionView` does it natively; a SwiftUI
   `ScrollView` with a drop destination is unproven here. Fallback: 60 pt sensitive bands at
   the top and bottom of the grid driving a `ScrollViewReader`.
3. **The carousel's horizontal pan versus the long press.** Different axes and different
   recognisers, so they should cohabit — but this is the same class of collision that killed
   the first gesture.
4. **Render cost.** Five covers per card, thirty cards, plus a carousel that can hold three
   hundred books. Lazy containers keep off-screen cells unmounted and Nuke caches; the first
   thing to cut if it stutters is the per-cover shadow, not the laziness. No
   `drawingGroup()`: it flattens to a bitmap and breaks the asynchronous cross-fades.
5. **The projection is recomputed on every read**, by design. The root view must read it
   **once** per body and pass value types down; a card that read the model in its own body
   would pay a walk over the whole library per card per animation frame.

**Documentation to follow.** An ADR for the modal flow — one container, a start route, local
routes, no way back, and an app-wide navigation enum that gets smaller — because that
decision outlives this feature and the next flow will cite it. The frozen snapshot and the
awaited apply are already documented in feature 0009 and in the code.

**Figma.** Twelve frames are missing and will be generated into the file from these
decisions, then corrected by the owner: opening sync, empty grid (the tile alone), « tout
est rangé », cards at one and two books, an empty draft card, a hovered drop target, an
apply in progress, a failed étagère with the three-part report, a status pill on a card, the
pushed étagère detail screen — which has no mockup at all — and the dark twin of the
nominal state.
