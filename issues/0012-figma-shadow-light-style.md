Title: Create the Shadow/Light effect style in the Figma library and bind it to the shelf label
Labels: needs-triage
Type: HITL

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Bring the Figma library into line with the new shadow introduced in code. Create a
`Shadow/Light` effect style in the design-system file, matching the value that the shelf
label and the focus cell's cover art now share, and bind it to the shelf label in the
design. Its colour binds to a shadow variable like every other shadow style in the library,
rather than carrying a raw value.

The label's paper and ink also need their variables in the `shelf/*` family, mirroring the
new palette entries, and the label in the design should use them rather than the app's
background/foreground variables.

Code stays the source of truth: this brings Figma to the code, not the reverse.

**Why HITL:** writing to Figma drives the Figma desktop app, so the file must be open there
and the write confirmed by eye. If the app isn't available, this issue stays open and is
reported as outstanding — it must not be silently skipped or faked, and the documentation
in 0013 must not claim it landed.

Note the documented divergence that every shadow in the library is pure black in both modes
and therefore invisible against a dark background. `Shadow/Light` inherits that and is
acceptable here: it falls on the shelf illustration, which is light in both modes.

## Acceptance criteria

- [ ] A `Shadow/Light` effect style exists in the design-system Figma file.
- [ ] Its offset and blur match the value shared by the shelf label and the focus cell cover in code.
- [ ] Its colour is bound to a shadow variable, not a raw value, consistent with the other shadow styles.
- [ ] The style is applied to the shelf label in the design.
- [ ] Variables for the label's paper and ink exist in the `shelf/*` family and are bound on the label.
- [ ] If the Figma desktop app is unavailable, the issue stays open and the blocker is reported explicitly.

## Blocked by

- issues/0009-shelf-label-sticker.md — the shadow and palette entries must exist in code first, since code is the source of truth.
