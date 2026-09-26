# A list's row shows what it holds

Shipped on 2026-09-26, from proposal **A · Encart enrichi** of the Figma section `Listes · Propositions`
(`464:12460`). No PRD and no issues: one slice, decided in an autopilot run.

## What it does

A row of the Lists tab used to say a list's name and its explanation, and nothing of what was in it. It now reads,
left to right:

- **the first three covers, fanned out** — the first element in front, in the order the list keeps them. A list of
  authors shows round portraits instead of book covers. A list with fewer elements shows only what it has; an
  empty list shows one grey slot, so the names still line up from row to row;
- **the name**, then **the explanation** on one line (left out when there is none);
- **how many elements it holds, in words**: « 12 œuvres », « 1 auteur·ice », « 2 maisons d'édition ».

The chevron is still the `NavigationLink`'s; the swipe-to-delete is unchanged.

## Technical surface

- **`ListRowView`** (`Features/Lists/`) — the row; `EntityListView` renders it instead of its inline `VStack`.
- **`ListCoverFan`** — the fan. It reads `Work` / `Author` from SwiftData with a `@Query` on the previewed uris, and a
  `.task(id:)` asks `EntityModel.getOrFetchWorks` / `getOrFetchAuthors` for them: cache first, so only entities the
  store lacks go to the network, and covers appear as they land (ADR 0001). Built from `CellThumbnail` `.small`
  (portrait, `.minimal` corners, or square `.full` for authors), 13 pt apart; hidden from accessibility, the row
  reads as one element.
- **`ListCoverPreview.uris(of:)`** — which uris to fan: sorted by `ordinal` like `EntityListDetail`, deduplicated,
  at most three. Pure.
- **`EntityListType.countLabel(_:)`** — the count as a plural catalogue entry, `list.count.{work,author,publisher}
  %lld`, fr and en, marked `manual`.
- **`ListCoverPreviewTests`** — order, short and empty lists, a repeated element, and the French counts.
- On the way, the tab's search filters with `localizedStandardContains` (D17) and the explanation's system
  `.secondary` gives way to `.foregroundSecondary` (D18).

## Notable decisions

- **Covers, not spines.** The étagère shows the spines of books you have; a list shows the faces of books you are
  thinking about. That is the thread through the five Figma proposals, and A is its quietest form.
- **Fetched lazily, per row.** Nothing is prefetched at sync: a row asks for its three entities when it appears.
  Prefetching every list's elements at launch was left out.
- **One line of explanation**, as the frame has it; the full text is one tap away in the list itself.

## Diverges from the frame

- Covers are 36 × 48 (`CellThumbnail` `.small` portrait), not the frame's 38 × 56; authors are 36 pt circles, not 40.
- The frame always draws three slots, the grey ones standing for covers not loaded yet; the code draws only as many
  as the list has elements, so a one-book list does not look half loaded.

## Not verified

- Not seen signed in on a device or a simulator: the change was checked by the unit suite (675 passed, 1 skipped)
  and a simulator build. The end-to-end scenario was not played; its `e2e.listRow` identifier is unchanged.
- Covers of a publisher list: nothing is fetched for that type, which the detail screen does not render either (D53).
