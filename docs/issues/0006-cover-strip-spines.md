Title: Cover-strip spines replacing the Metal shader
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0002-spine-strip-scrub-margin.md

## What to build

Render each spine from the book's own cover instead of the Metal watercolour shader. A new
`SpineStripLoader` loads the cover through the existing cached image pipeline, crops the
leftmost ~10px column, and returns a small strip image plus a title colour (black or white)
chosen from the strip's average luminance. The strip is stretched to the spine via a
resizable image, with the title overlaid and shadowed. This applies to both standing spines
and lying pile books; a single-book shelf still shows its full cover face-on. When no strip
is available yet (or the book has no cover), a parchment placeholder with the title is shown.
Strips are cached in memory (recomputed on a cold start); nothing new is persisted. Remove
`Watercolor.metal` and the `.colorEffect` usage.

## Acceptance criteria

- [ ] Spines are built from the leftmost ~10px of the real cover, stretched.
- [ ] The title is black or white per the strip's average luminance, with a shadow, always legible.
- [ ] Standing spines and pile books both use the strip; the 1-book face-on cover is unchanged.
- [ ] A parchment + title placeholder shows before the cover loads / when there's no cover.
- [ ] Strips are memory-cached; scrolling the shelf stays smooth (no per-frame cropping).
- [ ] No extra network cost beyond loading the cover once.
- [ ] `Watercolor.metal` and the shader effect are removed; app builds without them.
- [ ] Unit tests cover luminance → title colour (bright→black, dark→white, around threshold) and the leftmost-N-px crop geometry.

## Blocked by

None - can start immediately.
