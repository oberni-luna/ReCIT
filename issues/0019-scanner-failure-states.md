Title: Scanner failure states — unknown edition, timeout, already owned
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0005-batch-scanner.md

## What to build

The batch scanner's happy path assumes every barcode resolves to a book the user does not yet
own. Neither holds in practice. This slice adds the three states the design never drew.

**Unknown edition.** inventaire is an open, community-maintained database; scanning a book it
has never seen is not an edge case, it is a Tuesday — especially for French editions and
anything recent. The row shows the scanned code with an explanation that inventaire doesn't
know this edition, and no add action. Crucially this must be *distinguishable from a failed
scan*: silently ignoring it looks identical to "the camera didn't read it", so the user keeps
re-aiming at a book that will never resolve and concludes the app is broken.

A **distinct error haptic** marks it, different from the success tick, so the user can move on
without looking.

**Timeout.** The lookup is a network round-trip and the redacted row spins meanwhile; on a bad
connection that is indefinite. Cap it (around ten seconds) and fall into the same unknown-
edition state rather than leaving a placeholder pulsing forever.

**Already owned.** This is the most likely thing to go wrong in real use: the flow exists to
bulk-add a physical shelf, and people lose track of what they have already entered. Without a
check, a second pass over the same shelf silently creates duplicate items. The row shows the
book, marked as already in the inventory, with the add action disabled. Adding a genuine
second copy stays possible from the book detail screen.

**The ownership check must match on the resolved entity's canonical uri, not on the `isbn:`
uri that was requested.** inventaire keys an edition by its own canonical id, which differs
from the ISBN-form uri — a fact the codebase already documents in its edition-pages loader.
Match on the requested uri and the check silently never fires: the feature looks like it works
and quietly creates duplicates. This is the single easiest way to get this slice wrong.

**All three count as "handled"** for the repeat-scan gate built in issue 0018, so a book the
user cannot act on is not re-offered every frame while it sits in view.

A failed add also needs reporting, so the user never walks away believing a book was filed.

## Acceptance criteria

- [ ] A barcode inventaire cannot resolve shows a row naming the scanned code and explaining the edition is unknown.
- [ ] That row offers no add action.
- [ ] A distinct error haptic fires, different from the recognition tick.
- [ ] A lookup that exceeds the timeout lands in the same unknown-edition state.
- [ ] A book already in the user's inventory shows a row marked as such, with the add action disabled.
- [ ] The ownership check matches on the resolved entity's canonical uri, not on the requested `isbn:` uri.
- [ ] Scanning a book already owned never creates a duplicate item.
- [ ] Unknown-edition, timed-out and already-owned results all count as handled by the repeat-scan gate and are not re-offered while the book stays in frame.
- [ ] A failed add surfaces an error and leaves the row in a state the user can retry from.
- [ ] Unit tests cover: the timeout landing in unknown-edition; unknown-edition and already-owned both marking the code handled; and a failed add returning to a retryable state.

## Blocked by

- issues/0018-batch-scanner-skeleton.md — builds the state machine, the row and the repeat-scan gate this slice extends.
