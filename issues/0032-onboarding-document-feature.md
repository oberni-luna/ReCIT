Title: Onboarding — document the shipped feature
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

The feature write-up, on the pattern of the eight already in `docs/features/`: what it does, its
technical surface, the decisions that are not obvious from the code, and the known gaps.

Three things this one must carry, because they will otherwise be re-litigated:

- **What it amends.** The empty-shelf card's single destination, decided in
  `docs/features/0008-ai-auto-sort.md`, and the scanner's ending, described in
  `docs/features/0007-batch-scanner.md`. Both are superseded in part; say which part.
- **Why the bilan belongs to the scanner** rather than to the accueil, and why the accueil waits
  for the first inventory sync. Those two are the decisions someone will try to simplify.
- **What is derived rather than stored**: one persisted key, and "the user has arranged their
  books" read from owning an étagère — including the accepted consequence that creating one by
  hand also stops the bilan.

Then the index line in `CLAUDE.md`'s shipped-features list, and a note in
`docs/design-system/figma-library.md` recording that the Figma section `Onboarding` (`73:2829`)
went from three proposals to a shipped design, with the frames that match what was built and any
that no longer do.

## Acceptance criteria

- [ ] `docs/features/0009-onboarding-scan-then-sort.md` written on the pattern of the existing
      eight
- [ ] It states what it amends in features 0007 and 0008, and which part
- [ ] It records the bilan's ownership, the sync-first condition, and the single persisted key
      with its derived counterpart
- [ ] It lists the known gaps, including anything the device pass left open
- [ ] `CLAUDE.md`'s shipped-features list carries the new entry
- [ ] `docs/design-system/figma-library.md` records the state of the `Onboarding` section against
      what shipped
- [ ] The issue files and the PRD are left untouched

## Blocked by

- issues/0031-onboarding-device-review.md
