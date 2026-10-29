# A spinner after « Œuvres de … » and « Éditions de … » while they are fetched

Shipped on 2026-10-29. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

The author screen and the work's « Éditions » screen show what the store already holds at once, then ask
inventaire.io for the rest — the works not held yet, the editions not held yet. Nothing said that more could come:
a list could grow under the reader's eyes, or stay as it was, and the two looked the same.

A **small spinner** now follows the section header's label — « Œuvres de Liu Cixin », « Éditions de La Forêt
sombre » — for as long as the screen is fetching, and goes when it ends, whether the fetch succeeded or not.
VoiceOver reads it « Mise à jour en cours » / « Updating ».

## Technical surface

- **`SectionLoadingIndicator`** (`Features/Components/`) — a `ProgressView` in `controlSize(.small)`, tinted
  `foregroundSecondary` like the header's label, labelled with the new string `section.refreshing` (fr, en).
- **`AuthorDetailView`** — an `isRefreshing` flag, set for the whole of `load` (`defer`), shown after
  `author.works.header` in an `HStack(spacing: .small)`.
- **`WorkEditionGatewayView`** — the same flag around its `load`, which covers the work, its editions and, once a
  day, their merge tasks; passed to **`WorkEditionPicker`** as `isRefreshing`. The spinner sits after
  `work.editions.header` and before the `Spacer`, so the language menu keeps its place at the right.

## Notable decisions

- **The whole of `load`, not only the works or editions call.** The flag is a `defer`, so no path out of `load`
  can leave it spinning. On a work, the merge tasks are part of it: they change the « Doublon signalé » tags of the
  section's rows.
- **One spinner at a time on « Éditions ».** While the list is empty and its own `ProgressView` stands in for it,
  the header shows none.
- **The header's colour, not the accent.** A green spinner read as « wait »; the grey one reads as part of the
  label.
- **The `.loadingWorks` state of the author screen is unchanged.** With no work held at all, the screen still
  says « Chargement des œuvres de … » in full; the spinner only concerns a list that is already showing.

## Not done, not verified

- Built and unit suite green. Seen on the iPhone 17 simulator, in dark, on both screens — with a temporary six-second
  delay, since the real fetches end before a screenshot: the spinner shows after the label, and goes when `load`
  ends. Not seen in light, nor with a header long enough to truncate.
- The end-to-end scenario was not run.
- No Figma frame: `Section Header` has no place for the spinner (D-R9 in the Figma library doc).
