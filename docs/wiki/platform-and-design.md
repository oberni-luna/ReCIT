# Plateformes et design system

iOS 18+ with iOS 26 wrappers, the iPhone Duo, dark-mode grounds. Tokens live in `DesignSystem/` and are mirrored in Figma.

## Code

- `DesignSystem/` — tokens, fonts, styles
- [design-system/figma-library.md](design-system/figma-library.md) — Figma file, node ids, divergences

## Features

- [0039 Black behind the tabs' lists, a step above it in the Profil](features/0039-dark-mode-list-backgrounds.md) — in dark, Listes, Réseau and Recherche on `backgroundGrouped` (black), the Profil sheet on `backgroundGroupedElevated` (`gray/900`); Recherche inset grouped in every phase, « Chez mes amis » edge to edge; the coffee card aligned on the cells; light unchanged, Figma owed (D-R8)
- [0045 Ex-libris on iOS 18](features/0045-running-on-ios-18.md) — 1.5.0 runs from iOS 18.0; no Apple Intelligence proposal below iOS 26, glass and per-edge list insets through wrappers, `ForEach` over `Array(x.enumerated())` again; e2e on iOS 18.6 at 22 OK / 5 KO, not yet diagnosed
- [0053 Ex-libris sur iPhone Duo](features/0053-iphone-duo.md) — covers always 2:3 and extra columns past 200/120 pt cards in « Ranger mes livres » and « Chez mes amis »; the shelf carousel capped at 370 pt; `DesignSystem.ReadableWidth` (540 pt) through `readableWidth()` / `readableContentMargins()` on welcome, auth, book, author, editions and every form; forms' titles inline; « Tous les livres » on two columns past 700 pt; phones unchanged; the system rail on the right accepted; seen unfolded on the simulator, auth screens and scanner unseen, e2e not run
