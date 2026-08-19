# PRD — Batch scanning books into the inventory

Status: needs-triage
Area: Inventory / Search (see ADR 0001 / 0002)
Design: Figma `Nouveau récits`, node `57:2401` ("Batch Add") — captured in `grill-me/design/`

## Problem Statement

Adding books to the inventory is a one-at-a-time errand. The scan button reads a single
barcode, closes the scanner, and pushes the book's detail screen, where the user taps
*Ajouter à l'inventaire*. To enter a second book they start over: open the scanner, scan,
wait for a screen to load, tap, go back, open the scanner again.

That is fine for looking up a book in a shop. It is hopeless for the thing people actually
want to do when they first install a book app — stand in front of their own shelves and get
their library into it. A hundred books at four taps and two screen transitions each is not a
task anyone finishes.

The camera is the fast part; everything around it is the slow part.

## Solution

A dedicated scanning mode: the camera stays up, and books accumulate.

Point the phone at a barcode and the book rises from the bottom of the screen — cover, title,
author — over the live feed, with a haptic tick. One tap on the "+" files it into the
inventory; the row confirms and clears itself, and the camera is already waiting for the next
book. Scan, tap, scan, tap, down the shelf.

The camera never closes until the user closes it. Books that inventaire doesn't know, and
books already in the inventory, say so in the same row rather than failing silently. Tapping
the row's text still opens the full book screen, so the old look-something-up use is not lost.

## User Stories

1. As a RECITs collector, I want the scanner to stay open after I add a book, so that I can
   work through a whole shelf without reopening it.
2. As a collector, I want a scanned book to appear over the camera feed, so that I can see
   what was recognised without leaving the camera.
3. As a collector, I want the book's cover, title and author shown, so that I can confirm it
   is the right edition before adding it.
4. As a collector, I want a haptic tick when a book is recognised, so that I know it worked
   without staring at the screen.
5. As a collector, I want a single tap to add the book to my inventory, so that the rhythm
   stays fast.
6. As a collector, I want the button to show a loader while the book is being added, so that
   I know the work is happening.
7. As a collector, I want the button disabled while an add is running, so that I cannot file
   the same book twice by tapping again.
8. As a collector, I want a brief confirmation after a successful add, so that I have proof
   it landed before the row clears.
9. As a collector, I want the row to clear itself after that confirmation, so that I do not
   have to dismiss anything between books.
10. As a collector, I want the row to show placeholder shapes while the edition is being
    looked up, so that the layout does not jump when the real data arrives.
11. As a collector, I want only one book pending at a time, so that a book I have seen
    appear can never be silently replaced before I add it.
12. As a collector, I want the book still in front of the camera after I add it not to be
    offered again immediately, so that the flow does not loop on the same book.
13. As a collector scanning a book inventaire does not know, I want the row to say so, so
    that I can tell a missing database entry from a failed scan.
14. As a collector, I want a distinct haptic for that failure, so that I know to move on
    without looking.
15. As a collector on a poor connection, I want the lookup to give up after a while rather
    than spinning forever, so that the flow does not stall.
16. As a collector scanning a book I already own, I want the row to tell me so and refuse the
    add, so that a second pass over my shelves does not create duplicates.
17. As a collector, I want to tap the row's text to open the full book screen, so that I can
    still use the scanner to look a book up.
18. As a collector, I want a close button in the top corner, so that I can leave the flow at
    any point, including when a book I do not want is showing.
19. As a collector, I want the flow presented modally, so that leaving it returns me exactly
    where I was.
20. As a collector who has denied camera access, I want an explanation and a route to
    Settings, so that I am not staring at a black screen.
21. As a collector pointing the camera at a pale book on a pale surface, I want the book's
    text to stay readable, so that the overlay works against any background.
22. As a collector using the app in light appearance, I want the overlay still legible over
    the camera, so that it does not invert into unreadable dark-on-dark.
23. As a collector, I want books added by this flow to look like books added any other way,
    so that my inventory is consistent.
24. As a collector, I want a failed add to tell me, so that I do not walk away believing a
    book was filed.
25. As a collector, I want the flow to be the same whether I scan five books or fifty, so
    that nothing degrades as I go.
26. As a developer, I want the scan state machine separated from the camera component, so
    that its transitions and its repeat-scan gate can be tested without a camera.
27. As a developer, I want the same-code gate covered by tests, so that the flow cannot
    regress into re-offering a book that is still in frame.

## Implementation Decisions

- **The existing single-shot scan view is rewritten as the batch flow.** Its current behaviour
  — read one code, dismiss, push the book detail — is replaced entirely rather than kept
  alongside. The lookup use it served is preserved by making the result row tappable through
  to the book detail.
- **The flow is a modal with its own navigation stack**, carrying a close button in the
  trailing toolbar slot and able to push the book detail without tearing down the scanner.
  The tab bar drawn in the mockup is mockup furniture; a modal covers it.
- **One pending result at a time.** The camera component fires continuously while a barcode is
  in frame, so recognition is gated: a new code is only accepted when nothing is pending, and
  the most recently handled code is ignored until a different code is seen, with a short
  cooldown so a wobbling camera cannot retrigger it. Not-found and dismissed results count as
  handled for this purpose. Without this gate the flow re-offers the book the user is still
  holding, indefinitely.
- **The state machine is a separate, pure module**, driven by events (code seen, lookup
  resolved, lookup failed, add started, add finished, add failed, cleared) and holding the
  gate's memory. It knows nothing about SwiftUI or the camera package, which is what makes it
  testable.
- **States the row must render:** looking up (placeholder-redacted, action disabled), resolved
  (real data, action enabled), not found (the scanned code and an explanation, no action),
  already owned (the book, marked, action disabled), adding (loader in place of the action's
  glyph, disabled), added (brief confirmation, then cleared).
- **Redaction needs content to redact** — an empty string redacts to nothing — so the
  looking-up row renders plausible dummy strings purely to be greyed out.
- **The add waits for the server rather than being optimistic.** This is a deliberate
  departure from ADR 0001, whose optimistic rule governs the rest of the app. In a batch
  rhythm the confirmation *is* the feature: an optimistic add that failed would be discovered
  twenty books later, with no way to tell which ones landed. The loader and the confirmation
  are the point.
- **Ownership is checked against the resolved entity's canonical uri**, not against the
  `isbn:` uri that was requested. inventaire keys an edition by its own canonical id, which
  differs from the ISBN-form uri — a fact the codebase already documents elsewhere. Matching
  on the requested uri means the check never fires and duplicates are created silently.
- **The lookup is bounded by a timeout**, after which the row falls into the not-found state
  rather than leaving a placeholder pulsing.
- **Created items mirror the existing add-to-inventory defaults** for transaction mode and
  visibility, and are filed onto no étagère. Choosing a target étagère for the session is a
  natural follow-up — the item-creation payload already carries a shelves field, currently
  always sent empty — but is out of scope here.
- **The overlay's colours are mode-independent**, fixed at their dark values. It sits on a
  live camera feed, which is dark and unpredictable regardless of the user's appearance
  setting. This is the same reasoning that makes the shelf label mode-independent in PRD
  0003, in the opposite direction: that one sits on a permanently light illustration.
- **A bottom-up scrim sits behind the row**, without which light text over an arbitrary camera
  image is unreadable. The design's gradient variable resolved empty in the capture, so the
  stops are chosen rather than transcribed.
- **Camera permission denial is handled explicitly**, replacing the feed with an explanation
  and a route to Settings, rather than presenting a black screen with a floating close button.
- **The result row is its own view, not the inventory cell.** The design hides the inventory
  cell's subtitle, tag and owner, and adds a large trailing action and mode-independent
  colours. It is an overlay chip for a camera feed, not a list row on a light surface.

## Testing Decisions

- **What makes a good test here:** it drives the module's public interface with events and
  asserts the resulting state, not the internals that produced it. Pure and deterministic —
  no camera, no network, no SwiftUI. It would still pass if the implementation were rewritten
  and fail if the behaviour changed.
- **Tested: the scan state machine, including the repeat-scan gate.** Assert the full happy
  path (code seen → looking up → resolved → adding → added → cleared); that a second code
  arriving while one is pending is ignored; that the same code is ignored after being handled
  until a different code appears; that a different code is accepted immediately; that the
  cooldown expires; that not-found and already-owned both count as handled; that a lookup
  timeout lands in not-found; and that a failed add returns to a state where the user can
  retry rather than stranding the row.
- **Not tested:** the camera component (third-party, needs hardware), the row's rendering, the
  network layer, and the permission screen.
- Prior art: the shelf books layout suite — pure, seeded, network-free, in the unit test
  target, never the integration suite that hits the production server.

## Out of Scope

- Choosing a target étagère for the scanning session. The payload field exists and this is
  the obvious next step, but it changes the toolbar this PRD specifies.
- Creating an edition on inventaire when a scanned ISBN is unknown. Genuinely useful for an
  open database, and a whole feature — entity creation, work matching, author matching.
- Adding a second copy of a book already owned, from this flow. Still possible from the book
  detail screen.
- Any per-row skip control. The close button is the way out.
- Scanning anything other than EAN-13.
- Reviewing or undoing a batch after the fact.
- Offline scanning with a deferred lookup queue.

## Further Notes

- The design captures exactly one state — a book found. Every other state in this PRD was
  decided in discussion, not read from the mockup, and none of them are drawn.
- The mockup's colours all resolved to their dark values, which is the strongest single
  signal in the capture: the overlay is meant to live on a camera feed, not to follow the app
  appearance.
- The repeat-scan gate is the least visible and most important part of this feature. Without
  it the flow is unusable in practice, and nothing in the design hints that it is needed.
- Waiting rather than being optimistic makes this the second documented exception to ADR 0001
  in the shelves area, after the AI auto-sort's apply step. Both are bulk operations where
  the user has to be able to trust what landed.
