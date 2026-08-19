# PRD — Shelf label sticker, add affordance, detail edit

Status: needs-triage
Area: Inventory / Étagères (see ADR 0003 / 0004 / 0006)
Design: Figma `Nouveau récits`, node `34:190` (`Paint=Illustrative`)

## Problem Statement

An étagère's name currently sits as small grey 12pt text floating 16pt below the plank,
next to a bare pencil glyph. Three things go wrong with that.

It doesn't read as part of the shelf. The card is a painted illustration — a watercolour
wash, a wooden plank, painted book spines — and then a line of plain UI text hangs
underneath it, disconnected, in the same style as any other caption in the app. Nothing
says the name belongs to the shelf above it.

It doesn't read as tappable. Tapping the name pushes the shelf's book list, but the name
looks exactly like a static caption, so the affordance is invisible. The user has to
discover it by accident.

The pencil beside it is worse: a 13pt icon-only target sitting 4pt from another target,
well under the 44pt minimum, offering an action (edit the shelf's metadata) that has
nothing to do with browsing books and doesn't deserve permanent card real estate.

Separately, creating an étagère is only possible by scrolling the carousel to its very
end, past every existing shelf, to reach a trailing empty "create" card. With a dozen
shelves that is a dozen swipes to reach the one control that makes a new one. And the
same card doubles as the zero-shelf empty state, so the two roles are tangled: the card
can't be tuned for either without hurting the other.

Finally, once inside a shelf's detail screen there is no way to rename it or change its
visibility — the only edit entry point is back on the carousel card.

## Solution

The étagère's name becomes a **label** — a small white paper tag with rounded corners and
a soft shadow, stuck onto the plank's bottom edge and tilted a degree or so, as if applied
by hand. It carries the name at a comfortable reading size and a trailing chevron, so it
plainly announces itself as something you press to open the shelf. Because it overlaps the
plank, it reads as belonging to that shelf rather than floating below it.

Each label's tilt is derived from its own text, so a given étagère always leans the same
way, every launch, on every device — the shelf looks hand-labelled rather than randomly
jittering.

The pencil disappears from the card. Editing an étagère moves to a **Modifier** action in
the shelf detail screen's navigation bar, where it belongs: you open the shelf, then edit
it.

Creating an étagère moves to a small green **Ajouter** button in the "Étagères" section
header — reachable at any time, no swiping. The trailing create card is retired.

A user with no étagères at all sees a single empty shelf bearing a label in the same
hand-applied style reading "Todo : ranger mes livres dans une étagère" — an empty state
that speaks in the shelf's own visual language instead of a generic placeholder.

## User Stories

1. As a RECITs collector, I want my étagère's name shown on a white label stuck to the
   shelf, so that the name reads as part of the shelf rather than a caption below it.
2. As a collector, I want the étagère name at a comfortable reading size, so that I can
   identify a shelf at a glance while swiping the carousel.
3. As a collector, I want the label to sit close to the plank, overlapping its bottom edge,
   so that it looks stuck onto that specific shelf.
4. As a collector, I want the label to have rounded corners and a soft shadow, so that it
   reads as a physical paper tag lifted slightly off the shelf.
5. As a collector, I want each label tilted very slightly, so that the shelves look
   hand-labelled rather than mechanically laid out.
6. As a collector, I want a given étagère's label to always lean the same way, so that the
   shelf looks stable and recognisable rather than jittering between launches.
7. As a collector, I want the label's tilt to survive scrolling the carousel away and back,
   so that recycled cards don't visibly re-roll their angle.
8. As a collector, I want the tilt to stay within about a degree, so that the labels read
   as hand-placed, not broken.
9. As a collector, I want a chevron on the label, so that it is obvious the label can be
   pressed.
10. As a collector, I want pressing the label to open that étagère's book list, so that the
    label is the way into the shelf.
11. As a collector, I want the whole label — name, chevron and padding — to be the tap
    target, so that I don't have to hit the text precisely.
12. As a collector with a long étagère name, I want the label to grow with the name but
    never exceed the shelf's usable width, so that it stays a tag rather than a banner.
13. As a collector with a very long étagère name, I want the name truncated with an
    ellipsis while the chevron stays visible, so that the label never loses its affordance.
14. As a collector with accented French étagère names, I want them to tilt as varied as any
    others, so that "Classiques français" doesn't share an angle with everything else.
15. As a collector, I want the label to keep dark text on a light tag in dark mode, so that
    it stays legible against the shelf illustration, which has no dark variant.
16. As a collector, I want the label to dim along with the rest of the screen while I'm
    pressing to pick a book, so that nothing competes with the book I'm selecting.
17. As a collector, I want the pencil icon gone from the shelf card, so that the card offers
    one clear target instead of two crowded ones.
18. As a collector, I want a **Modifier** action in the navigation bar of an étagère's
    detail screen, so that I can rename it or change its visibility while looking at it.
19. As a collector, I want that action to open the same étagère form as before, prefilled,
    so that editing behaves exactly as it always has.
20. As a collector, I want the **Modifier** action to be absent when the étagère isn't
    available, so that I can never open a blank form by accident.
21. As a collector, I want the **Modifier** action shown with its label, not as a bare icon,
    so that its purpose is unambiguous and its tap target is real.
22. As a collector, I want an **Ajouter** button in the "Étagères" section header, so that I
    can create an étagère without swiping to the end of the carousel.
23. As a collector, I want that button tinted green, so that it reads as a live action
    rather than a decorative caption.
24. As a collector, I want the **Ajouter** button to have a comfortable tap target despite
    its small text, so that I don't have to aim at a 12pt label.
25. As a collector, I want the **Ajouter** button to open the same create form as before, so
    that creating an étagère is unchanged apart from where I start it.
26. As a collector with many étagères, I want the carousel to end on my last shelf, so that
    swiping doesn't always run into an empty card.
27. As a new user with no étagères, I want to see an empty shelf with a label reading
    "Todo : ranger mes livres dans une étagère", so that the screen explains itself instead
    of showing a void.
28. As a new user, I want that empty-state label to use the same paper-tag look and tilt as
    a real shelf label, so that the empty state speaks the shelf's visual language.
29. As a new user, I want the empty-state label's text centred and allowed to wrap onto two
    lines, so that the full sentence is readable on a narrow card.
30. As a new user, I want the empty-state label to carry no chevron, so that it doesn't
    promise navigation when it opens a form.
31. As a new user, I want tapping anywhere on the empty shelf to open the create form, so
    that the whole card is the affordance.
32. As a new user, I want the large "+" glyph gone from the empty shelf, so that a UI symbol
    isn't floating inside a painted illustration.
33. As a new user, I want the empty shelf to disappear once I have at least one étagère, so
    that it never trails my real shelves.
34. As a designer, I want the label's paper colour and ink defined as shelf tokens rather
    than app background/foreground tokens, so that they don't invert against an
    illustration that has no dark variant.
35. As a developer, I want the shadow shared by the focus cell's cover and the shelf label
    defined once in the design system, so that the two can't drift apart.
36. As a developer, I want a shadow abstraction in the design system, so that the remaining
    hard-coded shadows have an obvious home to migrate into later.
37. As a developer, I want the label rendered by one shared view used by both the shelf card
    and the empty card, so that the two labels can't diverge.
38. As a developer, I want the tilt computed by a pure function with no stored state and no
    schema change, so that it needs no migration and can be unit-tested.
39. As a developer, I want the section header extracted into its own view type, so that it
    can carry an optional action without a view-returning function.
40. As a developer, I want navigation from the label expressed as a navigation link rather
    than a manual path append, so that it matches the rest of the screen.

## Implementation Decisions

- **Tilt is a pure, deterministic function of the label's own text** — not of the shelf, not
  of a stored property, not of a random draw. Text in, an angle in `-1...1` degrees out.
  Deriving it from the text (rather than the shelf's server id) keeps the rule identical for
  the real shelf label and the empty-state label, which has no shelf behind it. Known and
  accepted consequence: renaming an étagère re-rolls its tilt. The hash must fold over
  Unicode scalars, not ASCII bytes — French names are full of accented characters, and an
  ASCII-only fold collapses them.
- **No schema change.** Nothing about the label is persisted; the tilt is recomputed on
  every render from text already in the model. No migration, no default for already-synced
  shelves.
- **One shared label view**, parameterised by text, chevron visibility, line limit and text
  alignment. Both the shelf card and the empty card use it, so the paper colour, radius,
  shadow, padding and tilt rule exist in exactly one place. The shelf card uses it with a
  chevron, one line, leading-aligned; the empty card without a chevron, two lines, centred.
- **The label overlaps the plank's bottom edge by a fixed inset**, taken from the Figma
  frame. It stays inside the card's vertical stack with a negative top padding rather than
  becoming a true overlay: the stack then reserves the label's height automatically at any
  Dynamic Type size, planks stay aligned card-to-card, and the horizontal scroll view can't
  clip the label's lower half. ADR 0003 already records that self-measuring shelf cards
  caused a collection-view update loop — reserving height in the stack keeps the card's
  size deterministic. The overlap is anchored from the label's *top*, so the two-line
  empty-state label simply extends further down and the same inset stays valid.
- **The label's width is content-driven with a ceiling** of the card width minus the books'
  horizontal margins. Short names produce a tag; long names truncate the name with an
  ellipsis while the chevron, being outside the truncating text, always survives.
- **The label draws above the plank and above the press-gesture overlay.** Consequence: the
  narrow band where the label overlaps the plank stops registering book presses. Accepted —
  books stand above the plank, so the loss is marginal.
- **The label is not exempt from the focus veil.** It is part of the card and dims with it
  during a press; only the pressed book is redrawn sharp above the veil (ADR 0006).
- **Navigation from the label uses a navigation link carrying the shelf destination value**,
  replacing the current manual path append, and matching how the "Tous les livres" list
  already navigates. The chevron is drawn explicitly: a navigation link supplies no
  disclosure indicator outside a list, so there is no framework glyph to inherit here.
- **The pencil and its sheet leave the shelf card entirely.** The card's edit state and
  sheet presentation move to the detail screen.
- **Edit moves to the detail screen's navigation bar as a primary action**, shown with both
  icon and title. Deliberately *not* a confirmation action: that slot means "Done/Save" for
  a modal, and renders prominent — wrong weight for a secondary action on a pushed screen.
  The action is gated on the étagère actually resolving, so a deleted or not-yet-synced
  shelf can't open a form that would behave as a create.
- **The section header becomes its own view type** with an optional trailing action,
  replacing the current view-returning function (which the project's own conventions rule
  against). "Étagères" gets the action; "Tous les livres · N" does not.
- **The Ajouter button is a plain-styled button**, tinted with the app's tinted foreground
  role, with vertical padding and an explicit content shape so its tap target clears the
  minimum despite small text. The design system has no small/tertiary button style — its
  three named styles are all full-width large buttons — so the styling is applied directly
  rather than inventing a style for one call site.
- **The trailing create card is retired and repurposed as the zero-shelf empty state.** It
  renders only when the user has no étagères, loses its large "+" glyph, and gains the
  label. Its plank alignment metrics are unchanged.
- **Two new shelf palette entries** — the label's paper and its ink — join the existing
  mode-independent `shelf/*` token family. They are deliberately *not* the app's
  background/foreground tokens: those invert in dark mode, and the shelf illustration is a
  single universal asset with no dark variant, so an inverting label would put near-black
  paper on a cream wash. This is the same reasoning that already keeps the spine contact
  shadow at 45% instead of normalising it to the ambient shadow.
- **A shadow abstraction enters the design system** — an enum plus a view modifier — seeded
  with the single value shared by the focus cell's cover art and the new label. The focus
  cell's hard-coded shadow migrates to it. The other five documented shadow styles stay as
  literals for now and are captured as a follow-up.
- **The new shadow becomes a Figma effect style**, created in the library and bound to the
  label, and documented alongside the existing shadow table. Code stays the source of
  truth; the Figma library is brought into line.

## Testing Decisions

- **What makes a good test here:** it exercises a module's public interface and asserts
  observable output, not how the result is computed. It is pure and deterministic — no
  network, no SwiftUI rendering, no image IO, no reliance on process-seeded hashing. It
  would still pass if the implementation were rewritten, and fail if the behaviour changed.
- **Only the tilt function is tested.** It is the one piece of real logic in this change;
  everything else is view composition, token definitions and toolbar placement, which the
  project's pure-logic test target cannot meaningfully assert on and which has no prior art
  for snapshot testing.
- Coverage: the returned angle always falls within the intended range; the same text always
  yields the same angle across repeated calls (this is what rules out process-seeded
  hashing, whose failure mode is invisible within a single launch); accented French text
  produces varied angles rather than collapsing to one value; and a set of realistic étagère
  names spreads across the range rather than clustering — the one genuine risk in a small
  hash reduced modulo a small number.
- Prior art: the existing shelf books layout suite is the model — pure, seeded, network-free,
  in the unit test target rather than the integration suite that hits the production server.

## Out of Scope

- Migrating the other five documented shadow styles into the new shadow abstraction. Only
  the one shared by the focus cell and the label moves; the rest is captured as a follow-up.
- Giving the shelf illustration (wash, plank) a dark-mode variant. The label works around
  its absence with mode-independent tokens; the illustration itself is untouched.
- Any change to how books are laid out, painted, pressed, focused or opened. The press,
  arm, slide and release behaviour of ADR 0006 is unchanged apart from the narrow band the
  label now covers.
- Any change to the étagère form itself — its fields, its validation, its optimistic write
  path. Only where it is opened from changes.
- Deleting an étagère, or reordering the carousel.
- Filing a book onto an étagère.
- Changing the "Tous les livres" section beyond its header adopting the new header view.
- A new ADR. Nothing here reverses a documented decision; ADRs 0003, 0004 and 0006 stand.

## Further Notes

- The Figma frame's card width matches a common iPhone width at the carousel's existing
  card-width fraction, so the design's measurements transfer as literal points rather than
  needing to be re-derived as ratios.
- The Figma name row still shows a single trailing icon, which is the chevron — confirming
  the pencil's removal is part of the design, not an addition to it.
- The label's height is fixed at one line on the shelf card, which is what keeps the plank
  overlap a constant. If a future design wants multi-line shelf names, the overlap has to
  become a ratio of the label's height instead.
- The empty-state label reuses the shelf label's look but not its behaviour: no chevron,
  because it opens a sheet rather than pushing a screen, and a chevron there would promise
  navigation that doesn't happen.
- Writing the Figma effect style requires the Figma desktop app with the file open. If that
  isn't available, the code and documentation land and the Figma step is reported as
  outstanding rather than silently skipped.
- `prd/` and `issues/` at the repository root are byte-identical, git-tracked duplicates of
  `docs/prd/` and `docs/issues/` — the same duplication as the two `CLAUDE.md` files. Both
  copies are written.
