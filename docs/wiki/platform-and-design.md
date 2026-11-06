# Plateformes et design system

iOS 18+ with iOS 26 wrappers, the iPhone Duo, dark-mode grounds. Tokens live in `DesignSystem/` and are mirrored in Figma.

## Code

- `DesignSystem/` — tokens, fonts, styles
- [design-system/figma-library.md](design-system/figma-library.md) — Figma file, node ids, divergences

## Features

- [0039 Black behind the tabs' lists, a step above it in the Profil](features/0039-dark-mode-list-backgrounds.md) — in dark, Listes, Réseau and Recherche on `backgroundGrouped` (black), the Profil sheet on `backgroundGroupedElevated` (`gray/900`); Recherche inset grouped in every phase, « Chez mes amis » edge to edge; the coffee card aligned on the cells; light unchanged, Figma owed (D-R8)
- [0045 Ex-libris on iOS 18](features/0045-running-on-ios-18.md) — 1.5.0 runs from iOS 18.0; no Apple Intelligence proposal below iOS 26, glass and per-edge list insets through wrappers, `ForEach` over `Array(x.enumerated())` again; e2e on iOS 18.6 at 22 OK / 5 KO, not yet diagnosed
- [0053 Ex-libris sur iPhone Duo](features/0053-iphone-duo.md) — covers always 2:3 and extra columns past 200/120 pt cards in « Ranger mes livres » and « Chez mes amis »; the shelf carousel capped at 370 pt; `DesignSystem.ReadableWidth` (540 pt) through `readableWidth()` / `readableContentMargins()` on welcome, auth, book, author, editions and every form; forms' titles inline; « Tous les livres » on two columns past 700 pt; phones unchanged; the system rail on the right accepted; seen unfolded on the simulator, auth screens and scanner unseen, e2e not run
- [0084 One prominent « OK » over the keyboard, on the Liste and the Fiche livre](features/0084-keyboard-ok-button.md) — `glassProminentButtonStyle()` (`.glassProminent` from iOS 26, `.borderedProminent` before); padding or `sharedBackgroundVisibility(.hidden)` inside a keyboard `ToolbarItemGroup` makes iOS 26 drop the item; iOS 18 unseen, e2e not run
- [0088 The tab bar leaves with the push, in Réseau and Listes](features/0088-tab-bar-hidden-on-pushed-screens.md) — every screen pushed in Réseau and Listes hides the tab bar, fading with the push and the pop, set once per stack by `hidesTabBarWhenPushed(on:)` from the path; a friend's list loses its tab bar, Inventaire and Recherche keep theirs; per-destination visibility and UIKit's `hidesBottomBarWhenPushed` tried and dropped; seen on the simulator for a friend's profile and list, iOS 18 unseen, e2e not run
