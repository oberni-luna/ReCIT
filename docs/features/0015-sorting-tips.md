# The tips of « Ranger mes livres »

Shipped on 2026-09-11 from PRD `docs/prd/0013-sorting-tips.md`. Five issues, 0077 to 0081 —
**plus issue 0082, the manual device pass, which is still outstanding.** The PRD is kept until
that pass is done; see "What is still owed" below.

## What it does

« Ranger mes livres » is a screen whose whole grammar is gestural and none of whose gestures
showed. Three TipKit cards now say the three things it never said, each invalidated by the gesture
it teaches, one on screen at a time. Someone who already does the gesture never sees the card that
explains it.

1. **« Glissez pour ranger »** points at the first book of the carousel, on opening the surface as
   soon as there is a book to file, and says the gesture *and its inverse*. It goes for good at the
   first successful drop.
2. **« Rien n'est encore enregistré »** points at « Appliquer » and arrives only once there is
   something to save — so never before the first card has served. It sends the reader to the recap
   just below, where the decision is already written, instead of adding a fourth reading to the
   footer. It goes at the first « Appliquer » launched.
3. **« Laissez proposer un rangement »** points at the wand button, only where Apple Intelligence
   runs and only once the drag has been learned. It goes as soon as a proposal is requested.

And the footer gave back its first sentence: the idle reading is now just « Rien à appliquer pour
le moment. » — except on a collection with no shelf at all, where the instruction stays, because
the gesture then has nowhere to drop.

## Technical surface

- **`Model/Tips/SortTipGate`** — a pure namespace, no TipKit, SwiftUI, SwiftData or `UserDefaults`.
  It returns **one** tip rather than three predicates, so "never two on screen" and "which comes
  first" are readable facts rather than a race between booleans. `isReady`, `isApplying` and
  `isProposing` are guarded once at the top, for every tip, so a fourth tip cannot forget them.
  Each tip is then a single clause.
- **`Model/Tips/SortTip`** — the three named once, `String`-raw-valued for stable persisted ids;
  declaration order is the order they are offered.
- **`AppModels/Tips/TipsStore`** — shaped like `OnboardingStore`: observed set, injectable
  `UserDefaults` mirror, keyed per user. Built in `RootView` and injected.
- **`Features/Components/TipCardStyle`, `TipPointerView`, `TipPointerShape`** — the mock's card and
  its 20 × 9 pointer, which stays **outside** the card so the card never knows what it aims at.
  Design-system tokens only.
- **`Features/Sorting/Sort*Tip`, `SortTipBanner`, `SortTipAim`, `SortApplyAlignment`,
  `SortProposalAlignment`** — three mute `Tip`s in one `TipGroup(.ordered)`, and the aiming
  machinery: a custom `HorizontalAlignment` published by the view that knows where its button sits,
  with the pointer as a separate layout child.
- **`ProfileDebugSection`** — « Réafficher les astuces », `#if DEBUG`, untranslated, with the
  learned count on the section's existing state line.

Invalidation is three counters on `SortSessionModel` — `booksFiledFromUnshelved`,
`appliesLaunched`, `proposalsRequested` — all `private(set)`, all incremented past the busy guard.
A refused drop and a press on a busy screen teach nothing. The view observes; it does not decide.

## Notable decisions

- **A `Tip` with no `#Rule` at all was impossible.** TipKit treats it as always eligible and the
  `@Parameter` drives nothing. Read as the PRD's actual words — «sans `#Rule` *de fond*» — each tip
  carries one trivial clause over a boolean the gate sets, and nothing else.
- **Closing a card does not call `invalidate(reason:)`.** TipKit's invalidation is per
  *application*, so it would hide the tip from the second account on a shared phone, and make a
  close permanent — both of which the PRD forbids. A close uses non-persisted view state, so the
  card returns on the next visit.
- **SORT-3 reads `isEnabled`, not `isVisible`.** A greyed button explains itself with its own
  alert, and a card promising the iPhone reads your titles should not appear when the device
  cannot. This is also what makes "switch Apple Intelligence on and come back" work without a
  relaunch, since the entry point derives from the observable availability.
- **The banners are layout siblings, not overlays**, which is how they cover no `e2e.*` target.
- **The footer exception is a second key**, not string surgery, carrying the old sentence verbatim
  in both languages so no copy drifted. "No shelf" is read from `session.projection`, so a drafted
  shelf counts as a live drop target.
- **The panel is one line shorter before the first drag** and grows when the first change lands —
  a direct consequence of shortening the footer. No reserved height was invented; if the jump reads
  badly on device, that is the follow-up.

## What is still owed — issue 0082

The PRD takes **no automated suite** for this feature; the recette is manual and deliberate.
« Réafficher les astuces » in the profile's Debug section is the tool. Nothing below has been done:

- [ ] `scripts/e2e.sh` passes with the tips active, no step masked by a card. If the scenario has
      to close tips, say so in [0012](0012-end-to-end-scenario.md).
- [ ] The three cards read in VoiceOver: announced on arrival, close button reachable.
- [ ] At the largest text size no card truncates or overflows.
- [ ] The three cards checked in light and dark, in French and English.
- [ ] On a device without Apple Intelligence, no card mentions the proposal.
- [ ] **A ceiling is chosen** for how often a card closed without the gesture comes back — the PRD
      asks for "not indefinitely" and no number has been picked. Record it here.
- [ ] The cards checked against their Figma frames `314:8109`, `314:8199`, `314:8247`. **None of
      the three was ever opened**: the Figma MCP server was unauthenticated for the whole
      implementation, so copy and placement come from the PRD text and `figma-library.md` alone.
- [ ] Screenshots attached, or the compte-rendu says what was seen.
- [ ] Then: delete `docs/prd/0013-sorting-tips.md`.

The states to replay, each after a « Réafficher les astuces »: first opening with books to file;
opening with nothing to file; opening during the sync; first drop; first « Appliquer »; first
proposal; a card closed without the gesture, three times running; two accounts on one phone;
sign out and back in.

## Issues

- `docs/issues/0077-sort-tip-drag-to-file.md` — SORT-1, and the spine — b1202dc
- `docs/issues/0078-debug-row-replay-tips.md` — the Debug row — fa1caef
- `docs/issues/0079-sort-tip-nothing-saved-yet.md` — SORT-2 — 957dd15
- `docs/issues/0080-sort-tip-let-it-propose.md` — SORT-3 — 54c7387
- `docs/issues/0081-footer-gives-back-its-first-sentence.md` — the footer — 9988fec
- `docs/issues/0082-sorting-tips-device-review.md` — **open**, the device pass above
