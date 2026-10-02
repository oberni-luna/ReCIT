# The group the Réseau badge is about

Shipped on 2026-10-02. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

The Réseau tab's badge counts what waits on an answer from me (feature 0028): friend invitations, group
invitations, and requests to join the groups I administer. The last kind had nowhere to point — the badge said
« 1 », and every group in « Mes groupes » looked the same.

A **red dot** now follows a group's name in « Mes groupes » when it holds requests to join that I, as one of its
admins, can answer. VoiceOver reads it « 1 demande à examiner » / « 2 demandes à examiner ». The group's own screen
already lists those requests first, answered from the row.

## Technical surface

- **`ReaderGroup.requestsToReview(by:)`** (`Model/Groups/`) — the `requested` count for an admin, 0 for anyone
  else. Covered in `ReaderGroupTests`.
- **`GroupModel.requestsToReview`** — what the tab's badge adds up — is now the sum of that over my admin groups,
  so the dots and the badge cannot disagree.
- **`GroupCellView`** takes a `pendingCount` (0 by default, and always 0 for a search result) and puts
  **`PendingDot`** (`Features/Network/Groups/`) after the name: a 10 pt circle in `foregroundError`, identifier
  `e2e.groups.pending`.
- **`GroupsSegmentView`** passes the count for « Mes groupes » only.
- String `groups.requests.pending %lld`, plural, fr and en.

## Notable decisions

- **A dot, not a number.** The group's screen counts the requests; the dot only has to say which group.
- **No dot on an invitation or on a request I sent.** An invitation is already its own section, first in the
  segment; a request I sent waits on someone else, and the badge does not count it.
- **`foregroundError`, not the system red.** The tab bar's badge is drawn by the system in its own red; the dot
  uses the design system's (`color/red/800` light, `color/red/400` dark). Close, not identical.

## Not done, not verified

- Built and unit suite green. **Never seen on a simulator or a device** — it needs an account administering a group
  with a pending request; the dot's place beside a name that wraps onto two lines is unchecked by eye.
- The end-to-end scenario was not run, and does not cover groups.
- No Figma frame for the dot.
