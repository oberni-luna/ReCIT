---
issue: 159
status: to-close
wiki: [[features/0053-iphone-duo]], [[platform-and-design]]
note: Sur iPhone Duo plié, le contenu est coupé à droite sur Recherche (« Chez mes ami·es ») et sur le profil d'un·e ami·e (carrousel des étagères). Les scroll views horizontales doivent continuer sous la barre de navigation.
created: 2026-11-18
---

## Context / Decisions

> Sur ces 2 écrans, le contenu est "cropped" à droite sur iPhone Duo (mode plié).
> Tu peux corriger pour que les scroll views horizontales continuent sous la barre de navigation pour iPhone Duo ?

- Sur un iPhone Duo plié (466 × 678 pt), iOS place l'heure, les boutons de navigation et la barre d'onglets dans une colonne système sur le bord droit (feature 0053). Les rangées horizontales s'arrêtent au bord de la safe area, donc avant cette colonne. La carte suivante est coupée net à environ 30 pt de la colonne.
- Trois rangées sont concernées. Toutes doivent défiler sous la colonne système jusqu'au bord de l'écran :
  - « Chez mes ami·es » dans Recherche : `Features/Search/SearchFriendsSection.swift`
  - le carrousel d'étagères sur le profil d'un·e ami·e : `Features/Community/UserShelvesSection.swift`
  - le carrousel d'étagères de l'onglet Inventaire : `Features/Shelves/ShelvesContent.swift`, `shelvesCarousel`. Il partage la mise en page de celui du profil, donc il a sûrement le même défaut.
- Hors scope : le cover flow d'une liste, la rangée d'auteur·ices et le défilement du panneau « À ranger ».
- Ajouté au premier retour : dans « Ranger mes livres », le fond flou du panneau « À ranger » (flou + dégradé) va jusqu'au bord droit de l'écran. Au deuxième retour, le trait au-dessus des boutons aussi.
- Les cartes gardent leur largeur actuelle, toujours calculée sur la largeur de la safe area. La première carte ne bouge pas.
- En fin de rangée, la dernière carte s'arrête avant la colonne système. Elle n'y reste jamais cachée.
- Rien ne change sur un iPhone : sans safe area à droite, il n'y a rien à franchir.
- Déplié en paysage, iOS met aussi la colonne à droite. Le même correctif s'y applique sans travail en plus.
- Le correctif reste local à ces trois rangées. Les en-têtes de section, « Tout voir » et le reste de la page restent dans la safe area.

## Acceptance criteria

- [ ] Duo plié, Recherche au repos avec des ami·es : les couvertures de « Chez mes ami·es » défilent sous la colonne système jusqu'au bord droit de l'écran, sans coupure nette avant la colonne.
- [ ] Duo plié, profil d'un·e ami·e avec au moins deux étagères : le carrousel d'étagères défile sous la colonne système jusqu'au bord droit.
- [ ] Duo plié, onglet Inventaire avec au moins deux étagères : le carrousel d'étagères défile sous la colonne système jusqu'au bord droit.
- [ ] Sur chacune des trois rangées, la première carte est à la même place et a la même largeur qu'avant.
- [ ] Défilée jusqu'au bout, chaque rangée montre sa dernière carte entière, à gauche de la colonne système.
- [ ] Le titre « Chez mes ami·es », « Tout voir » et « Étagères de … » restent alignés comme avant, à gauche de la colonne.
- [ ] Duo plié, « Ranger mes livres » : le fond flou du panneau « À ranger » et le trait au-dessus des boutons vont jusqu'au bord droit de l'écran, sous la colonne système.
- [ ] iPhone 17 : les trois rangées et le panneau « À ranger » sont identiques à avant.

## Implementation

- New `View.listRowScrollClipDisabled()` in `DesignSystem/List/View+listMargins.swift`, next to `listSectionHorizontalMargins`: `scrollClipDisabled()` from iOS 26, no-op before.
  - A `List` row gets no trailing safe area to ignore (measured 0 in a harness), so `ignoresSafeArea` does nothing there. Turning the clip off lets the cards draw under the system column while the scroll view's frame, the card width and the last card's resting place stay inside the safe area.
  - iOS 26+ only: before iOS 26 `listSectionHorizontalMargins(0)` is a no-op, the section keeps its margins and the cards must not spill into them. The Duo runs iOS 27+.
- Applied on the carousels of `SearchFriendsSection` and `UserShelvesSection`.
- `ShelvesContent.shelvesCarousel` unchanged: in a harness of the same layout (GeometryReader → vertical ScrollView → horizontal ScrollView), the outer ScrollView already reaches under the trailing safe area. Inferred, not seen in the real app.
- Harness: throwaway SwiftUI app in the scratchpad on the folded iPhone Duo simulator (466 × 678), reproducing the List row, the List in a UIPageViewController (as `TabPager`) and the Inventaire layout. Real app not launched.
- Risk: the clip is off vertically too. On a friend's étagère carousel, the paper label's shadow past its 8 pt `labelBleed` may now show faintly under the row.
- Build ✅ (iPhone 17, SwiftLint clean, baseline untouched) · tests ✅ (ReCIT_iOSTests).
- Round 1: `SortUnshelvedPanelView` background `.ignoresSafeArea(edges: .bottom)` → `[.horizontal, .bottom]` (inline).
- Round 2: the hairline above the controls `.ignoresSafeArea(edges: .horizontal)` (inline).

## Review

### Round validation — 2026-11-18

Scope: cumulative diff `main..HEAD`. Inline hunks (`SortUnshelvedPanelView.swift`) judged harder: clean.

- 🟡 [correctness] `UserShelvesSection.swift:97` étagère cards could spill into the readable margins unfolded in portrait → withdrawn: harness shows a section with `listSectionHorizontalMargins(0)` keeps a full-width row under `readableContentMargins`; already edge to edge before #159.
- 🟡 [structure] `View+scrollsUnderTrailingSafeArea` named for the trailing edge while lifting the clip on all four → fixed: renamed `listRowScrollClipDisabled()`, moved to `DesignSystem/List/View+listMargins.swift`, old file deleted.
- 🟡 [style] `View+listMargins.swift:5` file header did not cover the new wrapper → fixed: header widened.

Autofix: 2 rounds (rename + move, header comment). Build ✅ · tests ✅. Final verdict: clean, LENSES style ✓ · elegance ✓ · structure ✓ · correctness ✓.

## Verification

manual validation — not run by agent

round 1: manual validation — not run by agent. Seen by the main thread on the folded Duo simulator: the blurred background reaches the right edge.

round 2: manual validation — not run by agent. Seen by the main thread on the Duo simulator unfolded in landscape: hairline and background reach the right edge.

## Feedback

### Round 1 — 2026-11-18

- Asked: « Sur l'écran de rangement, j'aimerai que le background flou aille jusqu'au bord de l'écran, tu peux corriger ? »
- Triage: adjustment (the « À ranger » panel was out of scope; the user chose to fold it into #159). Criterion added.
- Change: `Features/Sorting/SortUnshelvedPanelView.swift`, the panel's background ignores the horizontal safe area too. `inline`.
- Build ✅ (Duo + iPhone 17) · tests ✅ · review: deferred → /wa-validate · verify: run yours (seen on the Duo simulator by the main thread).
- Not changed: the hairline above the controls still stops at the safe area (done in round 2).
- Rule captured: none.

### Round 2 — 2026-11-18

- Asked: « Oui, prolonge-le » (the hairline above the controls of « À ranger »).
- Triage: adjustment. Criterion updated.
- Change: `Features/Sorting/SortUnshelvedPanelView.swift`, the hairline ignores the horizontal safe area. `inline`.
- Build ✅ (Duo + iPhone 17) · tests ✅ · review: deferred → /wa-validate · verify: run yours (seen on the Duo simulator, unfolded landscape, by the main thread).
- Rule captured: none.
