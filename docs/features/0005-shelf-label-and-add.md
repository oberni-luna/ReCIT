# Paper labels on the shelves, an add button in the header, edit in the detail screen

Shipped on 2026-08-19 from PRD `docs/prd/0003-shelf-label-and-add-affordances.md`
(issues `issues/0008-modifier-action-shelf-detail.md` through
`issues/0012-figma-shadow-light-style.md`). No new ADR: ADRs 0003, 0004 and 0006 stand.

> Supersedes the card-level pencil affordance of `docs/features/0003-shelf-tap-selection.md`.
> The étagère's name is no longer a grey caption with a pencil beside it, and editing a shelf
> is no longer reachable from its card at all.

> **Amended by PRD `docs/prd/0006-ai-auto-sort.md` (issue
> `issues/0025-auto-sort-entry-points-availability.md`), and again by the design pass that
> followed.** The empty shelf card still takes a press anywhere on it, but that press now
> starts the automatic shelving flow — on every device. Its label reads "Todo / ☐ Ranger mes
> livres" over two lines, rests on the shelf rather than under the plank, and carries a
> chevron. The shelf labels are centred under their planks. See "The empty card's press"
> below.

## What it does

An étagère's name is now a **label**: a small white paper tag with rounded corners, lifted by a
soft shadow, stuck onto the plank's bottom edge and leaning a degree or so as if applied by
hand. It carries the name at reading size with a trailing chevron, so it announces itself as
something you press to open the shelf's book list. A long name truncates with an ellipsis while
the chevron survives, and the tag never grows wider than the books it labels.

Each label leans by an angle derived from its own text, so a given étagère always leans the same
way — on every launch, on every device, and across a carousel scroll that recycles the card.
Renaming a shelf re-rolls its angle; that is the accepted price of storing nothing.

The pencil is gone from the card. Editing an étagère happens where the étagère is: a **Modifier**
action in the detail screen's navigation bar, which opens the same prefilled form as before and
is absent entirely while the shelf hasn't resolved.

Creating one no longer means swiping the carousel to its end: a tinted **Ajouter** button sits in
the "Étagères" section header, reachable at any time. The trailing create card is retired.

A user with no étagère at all sees a single empty shelf — wash and plank, no books — carrying a
label in the same hand-applied style reading "Todo : ranger mes livres dans une étagère", centred
over two lines and with no chevron. Pressing anywhere on that card acts on the note it carries,
and the card disappears the moment the first étagère exists.

## Technical surface

- Screens touched: the shelves carousel and the étagère detail screen (`Features/Shelves`).
- **New in the design system:** `DesignSystem/Tokens/Shadow.swift` — a `DesignSystem.Shadow`
  enum plus a `View.shadow(_:)` modifier, seeded with the one value the shelf label and the
  focus cell's cover art share (black 18%, blur 3, offset (0, 2)).
- **New in the feature:** `ShelfLabelView` (the shared paper tag), `ShelfLabelTilt` (the pure
  tilt function) and `ShelfSectionHeader` (a header view type carrying an optional trailing
  action).
- `ShelfPalette` gains `labelPaper` and `labelInk`, joining the mode-independent `shelf/*`
  family rather than the app's background/foreground roles.
- `ShelfRowView`: the label replaces the name-and-pencil row, navigation goes through a
  `NavigationLink` carrying the shelf destination instead of a manual path append, and the card
  no longer owns an edit sheet. The label overlaps the plank by 14pt from its own top.
- `ShelfDetailView` gains the `.primaryAction` toolbar button, gated on the `@Query` lookup
  resolving, and owns the `ShelfFormView` sheet.
- `ShelvesContent` renders the header with its action, owns the create sheet its entry points
  open, and picks the empty card *or* the carousel — never both. (Since issue 0025 it also
  decides what the empty card's press means; see "The empty card's press".)
- `ShelfCreateCardView` becomes `ShelfEmptyStateView`: no "+" glyph, a label instead, and its
  plank metrics come from `ShelfCardMetrics` instead of three private copies of them.
- `ShelfFocusBookCell` drops its literal shadow for `.shadow(.light)`; the other five documented
  shadows stay literals for now (follow-up: `issues/0014-factorize-shadow-styles.md`).
- Figma: the `Shadow/Light` effect style and the `shadow/light`, `shelf/label/paper` and
  `shelf/label/ink` variables were created and bound on both `Shelf Card` variants — see
  `docs/design-system/figma-library.md`.
- No SwiftData schema change.

## Notable decisions

- **The tilt is a pure function of the label's own text**, not of the shelf and not of a stored
  property, so the empty-state label — which has no shelf behind it — obeys the same rule, and
  nothing has to be persisted or migrated.
- It folds over Unicode **scalars**, not ASCII bytes: French shelf names are full of accented
  characters and an ASCII fold collapses them onto one angle. It never touches
  `String.hashValue`, which is seeded per process and would re-roll every label at every launch
  — a failure invisible inside any single run, which is why a test pins it.
- A djb2 fold is finished with splitmix64's mixer before the modulo: djb2 alone leaves
  similarly-shaped names in neighbouring buckets, which on a shelf of French names reads as
  every label leaning the same way.
- **One label view for both cards**, parameterised by chevron, line limit and alignment, so the
  paper, radius, shadow, padding and lean cannot diverge between a real shelf and the empty one.
- The label lives **inside the card's vertical stack** with a negative top padding rather than
  being a true overlay. The stack then reserves its height at any Dynamic Type size, planks stay
  aligned card-to-card, and the horizontal scroll view cannot clip its lower half — self-measuring
  shelf cards are what caused the collection-view update loop recorded in ADR 0003.
- The chevron sits **outside** the truncating text, so a name too long for the card loses its
  tail and never its affordance.
- **The label draws above the plank and above the press gesture**, so the narrow band where it
  overlaps stops registering book presses. Accepted: books stand above the plank.
- **The label is not exempt from the focus veil.** It belongs to the card and dims with it while
  a book is being pressed; only the pressed book comes back sharp (ADR 0006).
- **Paper and ink are shelf tokens, not app tokens.** `background/default` and
  `foreground/default` invert in dark mode while the shelf illustration is a single universal
  asset with no dark variant — an inverting label would stick near-black paper onto a cream
  wash. Same reasoning that keeps the spine's contact shadow at 45%.
- **Modifier is a primary action, not a confirmation action**: the confirmation slot means
  "Done/Save" for a modal and renders prominent, which is the wrong weight for a secondary
  action on a pushed screen. It is shown with title *and* icon, so a pencil over a shelf of
  books isn't read as annotating a book, and it is gated on the shelf resolving — an ungated
  button would open a form that silently behaves as a *create*.
- **Ajouter is styled in place rather than through a button style**: the design system's three
  named styles are all full-width large buttons, far too heavy for a section header, and one
  call site doesn't justify a fourth. Its padding and content shape widen the 12pt label's
  target to roughly 31pt — deliberately short of the 44pt minimum, because reaching it would
  make this header half again as tall as the one below it for an action that sits alone in its
  row, where a miss costs nothing.
- **The empty card is not a carousel item.** A snapping, view-aligned scroll view holding a
  single card would offer a paging gesture with nowhere to page to, so `ShelvesContent` picks
  the card or the carousel instead of nesting one in the other.
- The empty card carries **no "+" glyph and no chevron**: the header owns creation now, a UI
  symbol floating inside a painted illustration reads as pasted on, and a chevron would promise
  a push where a sheet opens.

## The empty card's press

*Amended after this feature shipped, by PRD 0006 / issue 0025.*

As shipped here, a press anywhere on the empty card opened the create form. It now starts the
automatic shelving flow instead: the label reads as a note to tidy one's books, so acting on it
by doing exactly that is what the card was already promising.

On every device, including those that cannot run Apple Intelligence — there the flow states the
reason. 0025 originally shipped a fallback to the create form for that case and it was removed
within the day: a note about tidying books that silently opens a create-shelf form does not
read as an unsupported device, it reads as the wrong screen, and a silent substitution makes
the failure invisible. Naming the reason beats swapping in a different feature. The manual
route was never at stake — the section header's "Ajouter" creates an étagère by hand.

Two things about this feature are what make the change cheap. The tap target was already the
whole card rather than the label alone, so nothing about the hit testing moves — splitting a
painted card into two hit zones is the problem removing the pencil solved, and it is not
reintroduced here. And creation had already moved to the section header's "Ajouter", so handing
the card's press to something else costs the user no route.

The card still carries no chevron, and now for a second reason on top of its centred text: where
the press leads depends on the device, so a chevron would promise a push that only sometimes
happens. `ShelfEmptyStateView` is unchanged beyond its comments — it paints an empty shelf and
reports a press; `ShelvesContent` decides what that press means.

## Tuning

The lean is `ShelfLabelTilt.maximumDegrees` (1°) cut into `steps` (2001, odd so dead upright is
reachable). The paper's ceiling is `ShelfCardMetrics.booksWidth`, and how far it rides up over
the plank is `labelOverlap` (14pt), declared identically in `ShelfRowView` and
`ShelfEmptyStateView`. The shadow is `DesignSystem.Shadow.light`.

## Tests

`ShelfLabelTiltTests` (9) covers the range, that the same text always leans the same way and
that an equal string built another way agrees with it (which is what rules out process-seeded
hashing), that accented French names neither collapse onto one angle nor ignore the accent, that
a set of realistic étagère names spreads across the range rather than clustering, and that leans
go both ways. Only the tilt is tested: everything else here is view composition, token
definitions and toolbar placement, which the pure-logic test target cannot meaningfully assert
on.
