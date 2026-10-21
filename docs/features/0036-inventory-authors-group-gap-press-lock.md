# Authors on every row, one gap under a group's header, a press that locks before it ends

Shipped on 2026-10-21. No PRD and no issues: three independent visual fixes on iOS, decided in an
autopilot run whose decision log is summarised below, one commit each. Numbered 0036 rather than 0035:
the `reseau-graphe` branch already writes a `0035-network-graph.md`, and the two would collide on merge.

## What it does

**Every book in « Tous les livres » names its authors.** Some rows showed a title and nothing under it.
They were editions the app had first met as entities — through the scanner, the search or the book
screen. An edition entity carries no author names, so `Edition.init(entityDto:)` builds one with none;
when the copy was then added, or synced, the edition already held was handed back as it was, and the
item's snapshot — the only place the names live — never reached it. The snapshot now fills them in.
Until a full sync has run, and for a snapshot that names nobody, the row falls back on the authors of
the edition's works. A row with still no name draws no empty line.

**One gap under a group's header, the same with or without the note.** A group's screen left a wide
band between its header card and the first section's title (« Demandes à valider », « Membres »), wider
still when there was nothing under the card. The buttons and the note under the card lived in a section
emitted even when empty, so an admin who may leave got an empty row framed by two of the list's default
gaps. That section is now left out when empty, the sections are spaced by `medium` (16 pt), and the
buttons' row has no vertical inset: from the last thing under the header to the next section's title,
the distance is one gap whether « Vous êtes le seul admin… » is there or not.

**A pressed book locks halfway through the hold.** Selection mode used to arm at the very end of the
0.5 s hold, after the book had stopped growing. It now arms at 0.25 s, as the veil starts coming in:
the medium haptic and the book's cell land then, while the book is still growing. (Two thirds through
was tried first, and still felt late.) The growth and the veil keep their timing, so
the press lasts exactly as long as before. Lifting from that point opens the book.

## Technical surface

- **Authors.** `EntitySnapshotDTO.authorNames` (`AppModels/Inventory/ItemsDTO.swift`) reads
  `entity:authors` once, split on commas and trimmed — it used to be split in three places, leaving a
  leading space on every name but the first. `Edition.mergeAuthorNames(from:)` takes the snapshot's names
  when it has some; `ModelContext.edition(uri:snapshot:apiService:)` calls it on the held edition (adding a
  copy), and `InventoryModel` on the edition of an item it already knows (every sync).
  `Edition.displayedAuthorNames` is what `InventoryCell` and `ShelfFocusBookCell` show: `authorNames`, or
  the works' authors sorted with `localizedStandardCompare`. Three tests in `EntityUpsertTests`.
- **Group gap.** `GroupActionsView.hasContent(for:in:myUserId:)` says whether the actions section has
  anything to show — false only for an admin or member who may leave. `GroupDetailView` emits the section
  on that, with `.listRowInsets(.vertical, .zero)`, and spaces the list with
  `.listSectionSpacing(.custom(DesignSystem.Spacing.medium.rawValue))`. One test in `ReaderGroupTests`.
- **Press lock.** `ShelfPressRecognizer.armProgress` (0.5) joins `holdDuration` and `focusProgress`; the
  arm task sleeps to `focusProgress`, fires `onFocusing`, then sleeps to `armProgress` and arms.
  `ShelfRowView` is unchanged but for a comment. ADR 0006 is amended (beat 3).
- No SwiftData schema change, no new string.

## Notable decisions

- **Fix the data and the display, both.** Filling the names from the snapshot keeps editions right from
  now on, but only heals what a sync touches, and an inventory syncs fully only when a copy has been added
  since the last one. The fallback on the works' authors heals what is already in the store at once.
- **The works' authors are sorted.** `Edition.authors` comes out of a `Set`; the fallback sorts by name so
  a row does not reorder from one render to the next. The snapshot's own order wins whenever it exists.
- **A token gap, not `.compact`.** The request was for one smaller gap, always the same; `medium` says what
  it is, where `.compact` is whatever the system makes of it.
- **Only the arm moved.** Shortening the spring or the veil would have changed the total length, which the
  request ruled out; the veil still starts at half the hold, so a tap does not flash the screen.

## Not done, not verified

- Built, and the unit suite green (833 passed, the integration suite skipped as always). **None of the
  three was seen on a simulator or a device**: the simulator's app is signed out, and signing in means a
  real inventaire.io account. Unchecked by eye — the authors on rows that had none, the 16 pt gap on the
  group screen in its three shapes (buttons, note, nothing), and how the earlier lock feels under a thumb.
  The haptic needs a device in any case.
- The end-to-end scenario was not run.
- **The gray band behind the Réseau segmented control was not touched.** It is `NetworkSegmentBand`, which
  exists only on the `reseau-graphe` branch (a `safeAreaInset` with an opaque ground); on `main` the control
  is a transparent list row and has no band.
- `reseau-graphe` also edits `GroupDetailView` (its `@Query` of stored groups); merging it will touch the
  same file, a few lines apart.
