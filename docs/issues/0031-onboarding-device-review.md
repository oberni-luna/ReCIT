Title: Onboarding — device pass: appearances, two-stage close, Reduce Motion
Labels: needs-triage
Type: HITL
## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

Nothing new. A judgement pass on a real device, on the three things this feature cannot settle
in code review, plus whatever the pass turns up.

### The two-stage close

Closing a scanning session now ends the session rather than leaving it: the close control brings
up the bilan. On device this may well read as the button not having worked. Look at it, and if it
does, fix it where it is cheap — a distinct label or glyph on that control — rather than
redesigning the flow.

### The wash in dark mode

The shelf illustration's wash reads as a bright halo on a black background. That is existing
design-system behaviour (divergence D9 in the design-system doc), but it is far more visible
across a full screen than on a carousel card. Decide whether it stands as-is, and record the
decision either way.

### Reduce Motion, and the appearances

Both screens in light and dark, and the arrival with Reduce Motion on and off. The one thing to
watch: whether the stagger still reads as "one book at a time" once the offset is gone.

### The permission path

`Scanner mes livres` on a phone whose camera access is denied must land on the existing
permission wall, not a black screen. This cannot be exercised on a simulator — the camera
package's simulator path never touches AVFoundation — so it is device-only, as PRD 0005 already
records.

## Acceptance criteria

- [ ] Both screens reviewed on device in light and dark
- [ ] The two-stage close judged, and either accepted with a note or fixed on the close control
- [ ] The dark-mode wash judged, and the decision recorded in the design-system doc
- [ ] The arrival reviewed with Reduce Motion on and off
- [ ] `Scanner mes livres` reaches the existing permission wall on a device with camera access
      denied
- [ ] Anything the pass turns up is either fixed or written down as a known gap

## Blocked by

- issues/0028-onboarding-books-settle-animation.md
- issues/0029-onboarding-tally-unavailable.md
- issues/0030-empty-shelf-card-leads-to-scanner.md
