# 0039 — Black behind the tabs' lists, a step above it in the Profil

Shipped on 2026-10-21, in one commit, on autopilot: no PRD, no issues, no mockup. The request was the
owner's, from four dark-mode screenshots: Listes, Réseau and Recherche on black with their cells
unchanged; Recherche in an inset grouped list in every phase, « Chez mes amis » on the list's own
black; the Profil a little lighter than black but darker than its cells; and the coffee card at the
same side margin as the cells under it.

## What it does

**In dark, the root list of Listes, Réseau and Recherche sits on pure black.** The cells keep the
system's grouped-cell grey, which used to be nearly the same as the screen's `gray/800` and melted
into it; on black they read as cards. The empty and syncing states of Listes take the same black,
since the background is set on the tab's whole content.

**Recherche is an inset grouped list in all four phases** — recents, typing, suggestions, results —
and its empty state (no recent search, no friend's book) is on black too. « Recherches récentes »
is a rounded card like Listes' and Réseau's rows. « Chez mes amis » has no card: its covers sit
straight on the list's black and still run to the screen's right edge, and its header lines up with
« Recherches récentes » above it.

**The Profil sheet is on `gray/900` (#191919) in dark.** A sheet raises its cells to a lighter grey
(#2C2C2E), so its backdrop sits between that and black rather than on black like the tabs.

**The coffee card lines up with the cells under it**: same leading and trailing edge, 8 pt kept
above and below it.

In light, nothing changes: every value involved is `gray/50`, as before.

## Technical surface

- **`DesignSystem.Color.backgroundGrouped`** — `gray/50` / `gray/1000`. Behind a tab's root list.
- **`DesignSystem.Color.backgroundGroupedElevated`** — `gray/50` / `gray/900`. Behind a list shown
  in a sheet.
- **`applyListBackground(_:)`** takes the token, `backgroundSecondary` by default, so the twenty-odd
  pushed screens and forms that call it bare are untouched. `EntityListView` and `NetworkView` pass
  `.backgroundGrouped`; `ProfileView` passes `.backgroundGroupedElevated` on both its faces.
- **`SearchContent`** — `.listStyle(.insetGrouped)` instead of `.plain`, `.backgroundGrouped` on the
  list and on the `EmptyStateView`.
- **`SearchFriendsSection`** — the carousel's section takes `.listSectionMargins(.horizontal, 0)`, so
  the inset section does not cut the row of covers a margin short of the screen's edge, and its
  header takes `.padding(.horizontal, .medium)` back so it aligns with the inset sections' headers.
  The invitation face keeps its inset section.
- **`ProfileView`** — the coffee card's row insets go from `.small` on every side to `.small` above
  and below only.

## Notable decisions

- **Two tokens, not a hard-coded black.** UI code reads tokens; a colour picked in the modifier would
  be the one background in the app with no name. They are named after what they sit under, as
  `systemGroupedBackground` is, not after the screen.
- **Only the three tabs' roots and the Profil.** The request named those screens. Pushed screens —
  a list's detail, a group, a book, « Tout voir » — stay on `gray/800`, so going one level down
  from a tab now goes from black to grey in dark.
- **`gray/900` for the Profil** — an existing primitive, about halfway in luminance between black
  and the elevated cell grey.
- **The carousel goes edge to edge rather than inside the card's margins.** Clipped at the inset, the
  last cover was cut a margin short of the screen, which read as a mistake; the plain list it came
  from let it run off the edge.
- **The coffee card's side shadow is now clipped** by the section's rounded clip, which the old 8 pt
  side inset was there to avoid. The shadow is light and the top and bottom room is kept; on the
  simulator the edge reads clean.

## Owed, and known

- **Seen on the iPhone 17 simulator in dark only**, signed in: Listes, Réseau (Amis), the four
  phases of Recherche and the Profil sheet. Light mode not looked at — its values did not change.
  Réseau's Groupes segment, the « Chez mes amis » invitation face and Dynamic Type sizes not looked
  at.
- **`scripts/e2e.sh` not run.** No accessibility identifier moved.
- **Figma** — D-R8 in `docs/design-system/figma-library.md`: the two tokens are not variables in the
  file yet, and the mocked screens are still on `gray/800` in dark with a plain search list.
- **Android** (`Recit_Android/`) followed in [0041](0041-android-catches-up-with-ios.md), with a third token for the cells.
