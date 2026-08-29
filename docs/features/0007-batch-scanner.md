# Batch scanning books into the inventory

Shipped on 2026-08-20 from PRD `docs/prd/0005-batch-scanner.md`
(issues `issues/0018-batch-scanner-skeleton.md` through
`issues/0020-scanner-camera-permission.md`). Design: Figma node `57:2401`, captured in
`grill-me/design/`.

> Supersedes the single-shot scanner. Its one virtue — scanning to look a book up — survives
> as the result row's tappable text.

## What it does

Scanning is a mode rather than an errand. The camera stays up and books accumulate: point at
a barcode, the book rises from the bottom over the live feed with a haptic tick, one tap
files it, the row confirms and clears, and the camera is already waiting for the next one.
Scan, tap, scan, tap, down a shelf.

Books inventaire has never heard of say so instead of failing silently. Books already in the
inventory say so and refuse the add, which is what stops a second pass over the same shelf
creating duplicates. A denied camera permission explains itself instead of showing a black
screen.

## Technical surface

- Screens: a full-screen modal presented from the search screen's toolbar, with its own
  navigation stack so it can push the book detail without tearing the camera down.
- **New pure module** (`Model/Scan/`): `BatchScanStateMachine` and its state/event types, plus
  `ScannedBook`. No SwiftUI, no dependency on the camera package.
- **New feature** (`Features/Scanner/`): the modal, its view model, the result row and its
  parts, the permission screen, `CameraAccess`, and `ScanOverlayPalette`.
- The old single-shot scan view is deleted.
- Items are created through the existing inventory write, mirroring its transaction and
  visibility defaults, and are filed onto no étagère.

## Notable decisions

- **The repeat-scan gate is the feature.** The camera reports a barcode continuously while it
  stays in frame, so a book just added would be offered again forever. One result is pending
  at a time, and the code just handled stays gated until a different one appears or it has
  been out of frame long enough — every sighting pushes that deadline back, so a wobbling
  hand does not count as the book having been put down. Nothing in the design hints this is
  needed, and the flow is unusable without it.
- **The state machine is separate from the camera and from SwiftUI**, which is what makes the
  gate testable at all. It has an injected clock, so the cooldown is tested without sleeping.
- **The add waits on the server rather than being optimistic** — a documented departure from
  ADR 0001. In a batch the confirmation is the point: an optimistic failure would surface
  twenty books later with no way to tell which ones landed.
- **The ownership check keys on the resolved canonical uri**, not the `isbn:` uri that was
  requested. Those differ, and matching the wrong one means the check silently never fires —
  the feature looks correct while creating duplicates. It reuses the predicate the book
  screen already owns, so the two cannot drift.
- **The notice states self-clear after a beat.** A row that is not idle refuses every new
  barcode, so a notice that stayed up would strand the scanner. The machine forces this; the
  design does not mention it.
- **The overlay's colours are fixed, not mode-aware.** It sits on a camera feed, which is dark
  whatever the user's appearance setting says — the mirror of why the shelf label is fixed
  light. A scrim behind the row keeps light text legible over an arbitrary image; the
  design's gradient variable resolved empty, so its stops are chosen rather than
  transcribed.
- **A failed add reports through the snack bar, not the shared error channel.** The scanner is
  a full-screen modal and the tab's shared error observer draws underneath it. A documented
  exception to ADR 0001's single channel, forced by presentation rather than chosen.
- **`.restricted` and `.denied` are treated differently.** Both replace the feed with an
  explanation, but only a denial gets a route to Settings — a device restriction is not the
  user's switch to flip.

## Known gaps

- The permission screen cannot be exercised on a simulator: the camera package's simulator
  path never touches AVFoundation, so `.notDetermined` is read as authorised there to keep
  the flow usable. Device only.
- The camera usage description is still English in a French app. Localising it properly needs
  an `InfoPlist.strings` file.
- No étagère can be targeted for a scanning session. The item-creation payload already
  carries the field; it is the obvious next step.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> To read them: `git log --diff-filter=D --oneline -- issues/` then `git show <commit>^:<path>`.

- `issues/0018-batch-scanner-skeleton.md` — the camera stays open, books add one after another
- `issues/0019-scanner-failure-states.md` — unknown edition, timeout, already owned
- `issues/0020-scanner-camera-permission.md` — camera permission denied
