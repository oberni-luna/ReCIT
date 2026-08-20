Title: Show a work's genres as tags under the summary on the book screen
Labels: needs-triage
Type: AFK

## Parent

Feature: docs/features/0008-ai-auto-sort.md

## What to build

A work's genres exist in the store since the auto-sort work (PRD 0006) and are shown nowhere.
Put them on the book screen, as tinted tags in a row under the summary.

Design: the `Row / Summary` component in Figma (`38:201`) was adapted for this — it gained a
`meta` frame, horizontal, 8pt gap, holding `Tag` instances with `Color=Tinted` and their glyph
off, sitting under the body text inside the same inset row.

- The tag itself already exists in code: `DesignSystem/LabelStyles/TagLabelStyle.swift`, applied
  as `.labelStyle(.tag)` — the Figma `Tag` component is its mirror. Nothing new belongs in the
  design system here.
- Row: horizontal, wrapping if the genres are long. Two or three genres is the common case; a
  work with eight of them must not push the layout sideways.

## The interplay to get right

Genres are only populated by the enrichment pass, and that pass only ever looks at the works
behind **unshelved** books. So a book the user filed by hand, or one they simply opened without
ever running the arrangement, has an empty `genres` list and no timestamp — the tags would be
absent for most of the library, which reads as the feature not working.

So this issue also gives the enrichment a single-work entry point, and the book screen asks for
one work on appear when that work has never been asked. One work is one or two requests; the
existing batched implementation already covers it, and the timestamp is what stops it asking
twice. A work that comes back with nothing keeps its timestamp and simply shows no tags.

## Where the tags go when there is no summary

`EntitySummaryView` renders nothing at all when Wikipedia has no extract, which on this library
is common. Tags nested inside that view would then disappear for a reason that has nothing to do
with genres.

So: the tags render under the summary when there is one, and on their own when there is not.
That is a departure from the Figma component, which only draws them inside the summary row —
worth stating in the code rather than silently resolving.

## Acceptance criteria

- [ ] A work with genres shows them as tinted tags on the book screen, under the summary, inside
      the same inset row as the design shows
- [ ] The tags use `.labelStyle(.tag)`, not a re-implementation, and no new design-system type is
      added
- [ ] Several genres wrap rather than overflow horizontally, verified with a work carrying at
      least six
- [ ] A work with no genres shows no empty row, no placeholder and no gap
- [ ] Tags appear even where the work has no Wikipedia extract
- [ ] Opening a book whose work has never been asked about triggers a single-work enrichment, and
      opening it again does not ask twice
- [ ] The enrichment call cannot block or delay the screen's first paint
- [ ] Genres are read reactively from the store, per ADR 0001's first invariant — no genre list
      is passed down from a model method's return value
- [ ] Light and dark both checked
- [ ] `docs/design-system/figma-library.md` records the adapted `Row / Summary` (`38:201`) and its
      `meta` frame, and notes the stale `Owner` text node still sitting inside it at x=102, which
      overlaps the second tag

## Out of scope

- Making the tags tappable, or filtering the inventory by genre. This is display only.
- Showing genres anywhere else — the inventory cell, the shelf detail, search results.
- Fixing genre coverage itself, which is `issues/0034-genres-read-from-the-wrong-claim.md`.

## Blocked by

None - can start immediately, though it is worth landing after
`issues/0034-genres-read-from-the-wrong-claim.md` so there is something to look at.
