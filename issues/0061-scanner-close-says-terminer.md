Title: The scanner's close control says what it does
Labels: needs-triage
Type: AFK

## Parent

Feature: docs/features/0007-batch-scanner.md

## What to build

The scanning session's control in the top-right corner is a bare `X`, floating over the camera
feed. It becomes a text button reading **« Terminer »**, in the `.confirmationAction` toolbar
placement.

Two reasons, and the second is the one that matters:

- An `X` over a live camera feed reads as *cancel* — as though the books just filed were about
  to be thrown away. Nothing is cancelled: every book was written to the server as it was
  added.
- Since the session gained its ending, **closing is not leaving**. The control ends the session
  and hands over to the bilan; it does not dismiss the flow. A glyph that means "close" while
  doing "finish" is the mismatch to remove.

`.confirmationAction` is also the right placement on its own terms: this is the affirmative way
out of a modal, not its cancellation.

## Check this against the sorting flow's own decision

Issue `0052` (scan-then-sort modal flow) states that « Terminer » *disappears* and that leaving
is the close control. Read in context that concerns the **sorting screen**, whose draft must
survive being left — not the camera, which has nothing pending once a book is filed. Confirm
that reading before implementing, and if the two really do collide, the flow's decision wins
and this issue is withdrawn rather than quietly reworded.

## Scope

- Only the scanning session's own control. The permission wall keeps its `X`: no session has
  started there, so nothing is being finished.
- Wording in the string catalogue, not inline.

## Acceptance criteria

- [ ] The scanning session's control is a text button reading « Terminer », placed in
      `.confirmationAction`
- [ ] It still ends the session rather than dismissing the flow — the bilan follows when it is
      owed, exactly as today
- [ ] The permission wall is untouched
- [ ] The label lives in `Localizable.xcstrings`, with its English counterpart
- [ ] Legible over a bright camera feed as well as a dark one — the glyph had a scrim, a text
      button needs to survive the same background
- [ ] The reading of `0052` above is confirmed or the issue is withdrawn, in writing

## Blocked by

None - can start immediately
