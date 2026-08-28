Title: The onboarding screens survive a big font
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0010-ex-libris-pre-login-onboarding.md

## What to build

`OnboardingScreenLayout` — the skeleton `C1 · Bienvenue` and `C2 · Bilan` both stand on — is a `VStack`
between two `Spacer()`s. It has no `ScrollView`.

It holds together at default text sizes because C1 carries a title and one sentence. At the accessibility
sizes, and on a 667pt-tall device, the illustration and the copy squeeze the answers off the bottom — and
the answers are the only way out of a full-screen cover.

Make the content scroll and pin the answers, the way the welcome screen built in 0056 does. `CLAUDE.md`
requires Dynamic Type to be respected; this is the screen where failing to costs the most, because there
is no navigation bar to escape through.

Independent of every other slice: it changes an existing screen and shares nothing with the account flow.

## Acceptance criteria

- [ ] At the largest accessibility text size, `C1 · Bienvenue` shows its full copy and both answers
      remain tappable
- [ ] The same for `C2 · Bilan du scan`, including the count in its title
- [ ] The same for the unavailable variant of the bilan
- [ ] The same on a 667pt-tall device
- [ ] At default text sizes the layout is unchanged — nothing scrolls that did not scroll before
- [ ] The illustration keeps its proportions and its share of the width
- [ ] Light and dark unchanged

## Blocked by

None - can start immediately
