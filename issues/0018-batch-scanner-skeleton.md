Title: Batch scanner — camera stays open, books add one after another
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0005-batch-scanner.md
Design: Figma node `57:2401`, captured in `grill-me/design/` (read `screens/batch-add.md` and `tokens.md` before starting)

## What to build

Replace the single-shot scan with a scanning *mode*: the camera stays up and books accumulate.
Point at a barcode, the book rises from the bottom over the live feed with a haptic tick, one
tap on the "+" files it, the row confirms and clears, and the camera is already waiting for
the next one. Scan, tap, scan, tap, down a shelf.

This slice is the happy path, end to end. Failure states are issue 0019; camera permission is
issue 0020.

**The existing scan view is rewritten, not kept alongside.** Its current behaviour — read one
code, dismiss, push the book detail — goes away. The lookup use it served is preserved by
making the result row's text tap through to the book detail.

**Presented modally, with its own navigation stack**, so it can carry a close button in the
trailing toolbar and push the book detail without tearing down the camera. The tab bar drawn
in the mockup is mockup furniture — a modal covers it.

**One pending result at a time, and a repeat-scan gate.** This is the least visible and most
important part of the feature, and nothing in the design hints it is needed. The camera
component fires continuously while a barcode is in frame, so: a new code is only accepted when
nothing is pending, and the most recently handled code is ignored until a *different* code is
seen, with a short cooldown so a wobbling camera cannot retrigger it. Without this the flow
re-offers the book the user is still holding, forever, and is unusable.

**The state machine is its own pure module**, driven by events (code seen, lookup resolved,
lookup failed, add started, add finished, add failed, cleared) and holding the gate's memory.
It must know nothing about SwiftUI or the camera package — that separation is what makes it
testable, and it is where the bugs will be.

**Row states in this slice:** looking up (placeholder-redacted, action disabled) → resolved
(cover, title, authors; action enabled) → adding (loader replacing the action's glyph,
disabled) → added (brief confirmation) → cleared.

Note redaction needs *content* to redact — an empty string redacts to nothing — so the
looking-up row renders plausible dummy strings purely to be greyed out.

**The add waits for the server rather than being optimistic.** A deliberate, documented
departure from ADR 0001: in a batch rhythm the confirmation *is* the feature, and an optimistic
add that failed would be discovered twenty books later with no way to tell which ones landed.

**The row is its own view, not the inventory cell.** The design hides the cell's subtitle, tag
and owner, adds a large trailing action, and resolves every colour to its *dark* value. That
last point is the strongest signal in the capture: the row lives on a camera feed, which is
dark and unpredictable regardless of the user's appearance setting, so its colours are
**mode-independent** — the same reasoning that makes the shelf label mode-independent in PRD
0003, in the opposite direction.

**A bottom-up scrim sits behind the row.** Without it, light text over an arbitrary camera
image is unreadable — point the phone at a pale book on a pale table. The design's gradient
variable resolved empty in the capture, so its stops are chosen rather than transcribed.

Created items mirror the existing add-to-inventory defaults for transaction mode and
visibility, and are filed onto no étagère.

## Acceptance criteria

- [ ] The scanner stays open after a book is added; several books can be added without reopening it.
- [ ] A recognised book appears over the camera feed with its cover, title and author.
- [ ] A haptic fires when a book is recognised.
- [ ] While the edition is being looked up, the row shows redacted placeholders at the final layout, so nothing jumps when real data arrives.
- [ ] One tap on the action adds the book to the inventory.
- [ ] While adding, the action shows a loader in place of its glyph and is disabled.
- [ ] A successful add shows a brief confirmation, then the row clears itself.
- [ ] A second code arriving while one is pending is ignored.
- [ ] The book still in front of the camera after being added is not offered again.
- [ ] A different book is recognised immediately.
- [ ] Tapping the row's text pushes the book detail without closing the scanner.
- [ ] A close button in the trailing toolbar leaves the flow and returns the user where they were.
- [ ] The row stays legible over a pale camera image.
- [ ] The row's colours are identical in light and dark appearance.
- [ ] Books added here are indistinguishable from books added through the book detail screen.
- [ ] The state machine is a separate module with no SwiftUI or camera-package dependency.
- [ ] Unit tests cover: the full happy path; a second code ignored while one is pending; the same code ignored after being handled; a different code accepted immediately; the cooldown expiring; and a failed add leaving the row retryable rather than stranded.
- [ ] The old single-shot scan behaviour is gone.

## Blocked by

None - can start immediately.
