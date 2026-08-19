Title: Camera permission denied in the batch scanner
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0005-batch-scanner.md

## What to build

The batch scanner is a modal whose entire background is a live camera feed. If the user has
denied camera access, that background is nothing — leaving a black screen with a floating
close button and no explanation.

The old single-shot scanner got away with handling none of this: the user tapped Scan, got
nothing, and backed out of a transient sheet. A dedicated scanning mode cannot.

Detect the denied state and replace the feed with a short explanation of why the screen is
empty, plus a button into the system Settings for the app. The close button stays available
throughout.

This is the difference between a feature that looks broken and one that explains itself.

Independent of issue 0019 — the two extend different parts of the flow and can run in
parallel.

## Acceptance criteria

- [ ] With camera access denied, the scanner shows an explanation instead of an empty feed.
- [ ] A button opens the app's entry in the system Settings.
- [ ] The close button remains available and returns the user where they were.
- [ ] Granting access in Settings and returning to the app shows the working scanner, without the user having to relaunch.
- [ ] With access granted, nothing about the flow changes.
- [ ] The permission state is checked when the flow opens, not only on first scan.

## Blocked by

- issues/0018-batch-scanner-skeleton.md — builds the modal this slice adds a state to.
