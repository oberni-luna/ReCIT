---
issue: 10
status: todo
wiki: [[design-system/figma-library]], [[features/0005-shelf-label-and-add]]
note: Migrated from docs/issues/0014-factorize-shadow-styles.md. Android counterpart split to #49.
created: 2026-11-06
---

## Context / Decisions

> six literal shadows into DesignSystem.Shadow
>
> Follow-up to the shadow abstraction introduced with the shelf label (feature 0005). That change created
> `DesignSystem.Shadow` and `View.shadow(_:)` seeded with `.light` only, and left the other documented shadows
> as literals. Finish the job: one case per remaining documented shadow, every call site through the modifier,
> no literal shadow in feature code. Factorisation, not a redesign: nothing changes on screen.

- **Code moved since the issue was written.** Of the six shadows it lists, four are still literals, two are gone:

  | Figma style | Value (color, radius, x, y) | Call sites today |
  |---|---|---|
  | `Shadow/Painted Book` | black 16 %, 1.5, 0, 1.5 | `Features/Shelves/PaintedBookView.swift:75`, `Features/Components/CoverWallView.swift:114` |
  | `Shadow/Book Spine` | black 45 %, 1, 0, 0.5 | `Features/Shelves/ShelfBookTitle.swift:36` (the title on the spine) |
  | `Shadow/Lying Book` | black 22 %, 3, 1, 2 | `Features/Components/ShelfCoverView.swift:74` (every shelf cover, standing or lying) |
  | `Shadow/Entity Glow` | black 10 %, 10, 0, 0 | `Features/EntityBrowser/EntityImageView.swift:25` |
  | `Shadow/Pressed` | — | none: `ScaleButtonStyle` was deleted |
  | `Shadow/Thumbnail` | — | none: `CellThumbnail` has no shadow any more |

- **`Pressed` and `Thumbnail` get no case.** A case nobody calls is dead code. Their Figma styles stay untouched.
- **Case names follow the Figma styles**: `.paintedBook`, `.bookSpine`, `.lyingBook`, `.entityGlow`, next to
  the existing `.light`. The doc's table then maps each style to its case one for one. Their names no longer
  describe every use (`.lyingBook` shades standing covers too, `.bookSpine` shades the title text): accepted,
  noted in the doc rather than renamed.
- **Values are the contract**, copied exactly from the call sites above. `.bookSpine` keeps its heavy 45 % — it
  reads as contact, not elevation, never normalised toward `.light`. `.lyingBook` keeps its x = 1, the only
  non-zero horizontal offset, which sells the light direction.
- **Dark mode out of scope.** Every shadow is pure black in both modes, so invisible on a dark background. Not
  fixed here; consolidating the values is what makes that fix one edit later.
- **iOS only.** Android's 8 `Modifier.shadow(elevation = …)` literals are another design (elevation, not
  x/y/blur): draft #49.
- **Where it lives**: `ReCIT_iOS/DesignSystem/Tokens/Shadow.swift` only grows; its header comment drops "the
  other documented shadows stay literals for now". No new file.
- **Doc**: `docs/wiki/design-system/figma-library.md` → « Styles d'effet — 7 ombres »: each Source cell names the
  `DesignSystem.Shadow` case and its call sites, `Pressed` and `Thumbnail` read « retirée du code », and the
  paragraph saying `Shadow/Light` is the only non-literal source goes.

## Acceptance criteria

- [ ] `DesignSystem.Shadow` has exactly five cases: `.light`, `.paintedBook`, `.bookSpine`, `.lyingBook`, `.entityGlow`.
- [ ] Each new case returns the color, radius and offset of the table above, unchanged.
- [ ] `grep -rn "\.shadow(color:" ReCIT_iOS --include='*.swift'` only hits `DesignSystem/Tokens/Shadow.swift`.
- [ ] The five call sites above use `.shadow(.<case>)`.
- [ ] Étagère carousel, focus overlay, « Ranger mes livres » cards, the welcome wall of covers and the book screen header look the same as before, light and dark.
- [ ] The doc's shadow table names the enum case as each style's Swift symbol; `Pressed` and `Thumbnail` read « retirée du code »; the pending-migration note is gone.
- [ ] Build passes with SwiftLint, baseline not grown.

## Implementation

## Review

## Verification

## Feedback
