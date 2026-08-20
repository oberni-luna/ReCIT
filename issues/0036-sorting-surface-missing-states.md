Title: The states the sorting surface has never been drawn in
Labels: needs-triage
Type: HITL

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

Five states of the sorting screen exist in no mockup, and two of them ARE the feel of the
feature. Draw them in the Figma file (section `Ranger mes livres`), as frames beside the three
that exist, and record them in the design-system doc like every other pass.

| State | Why it cannot be improvised |
|---|---|
| A row while it is being dragged | Lifted, shadowed, and the gap it leaves behind. This is what tells the user the gesture took |
| A section under the finger as a drop target | Without it, dropping is a guess. It must read on a section header AND on an empty section |
| The opening sync | The screen blocks on a server round trip before it freezes its snapshot. That wait needs a face |
| An empty `À ranger` | The section should disappear once the pile is gone. Decide whether anything takes its place |
| The partial-failure report | Three outcomes, not two: created and filled, created but empty, never created. The wording exists in `AutoSortApplyReport`; the layout on this screen does not |

Reuse what is there — `AutoSort / Book Row`, `AutoSort / Shelf Header`, `AutoSort / Note`,
`Bottom Action Bar`. Anything that appears twice (light and dark counts as twice) becomes a
component property, not a redrawn node.

## Acceptance criteria

- [ ] The five states are drawn, light and dark where the pair is meaningful, mode pinned on each
      frame
- [ ] Drop-target feedback is shown both on a populated section and on an empty one
- [ ] The partial-failure report distinguishes created-and-filled, created-but-empty, and
      never-created
- [ ] Every frame contains only instances and named layout containers — zero raw drawing
- [ ] `Spec · Tri manuel` names the new frames and what each one decides
- [ ] `docs/design-system/figma-library.md` lists the new node ids and any component property
      added

## Blocked by

None - can start immediately
