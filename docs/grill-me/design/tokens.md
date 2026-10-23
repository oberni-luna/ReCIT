# Réseau · Graphe — tokens

Every colour, type, spacing, radius, stroke, shadow and opacity used by the `Réseau · Graphe` section
(`512:15486`, file `S7IvC6GvlcUFe5IgbtvQq6`, page `Screens` `20:4`), mapped to the Swift design system in
`ReCIT_iOS/DesignSystem/Tokens/`. Back to the [overview](overview.md).

**How the values were read.** `get_variable_defs` on the six frames (`512:15513`, `512:15657`, `520:15762`,
`522:15982`, `522:16586`, `522:16671`) and the six components (`512:16006`, `512:16016`, `512:16061`,
`519:16390`, `519:16401`, `521:15969`); `get_design_context` on every component; then a **read-only**
Plugin-API pass over every node of the six frames, which returns what the variable list cannot: which
variable each fill and stroke is bound to, stroke weights, dash patterns, node opacities, raw (unbound)
radii and paddings, and the actual endpoints of every edge. Nothing in the file was changed.

**Mode.** The section is drawn in **light mode only**. Dark values below are not read from these frames:
they are the `Dark` mode of the `Color` collection, which mirrors `Color.swift` (the source of truth — see
[figma-library.md](../../design-system/figma-library.md#sémantiques--color-source--designsystemtokenscolorswift)).

---

## Verdict on « Aucun token nouveau »

The spec frame says **« Aucun token nouveau. »** Checked against the Swift tokens:

- **True for colour.** Every fill and stroke in the four graph screens and the six graph components is bound
  to an existing `Color` variable, and each of those has a `DesignSystem.Color` case. No raw colour appears
  outside system chrome (status bar, nav bar R5/R6, tab bar).
- **True for text styles, with one exception.** Every text node uses one of the ten existing styles, except
  the initials of `Graph / Friend · Dot` — **raw Open Sans Regular 9 pt**, no style, no `TextStyle` case.
- **True for elevation.** Only `Shadow/Light` (→ `DesignSystem.Shadow.light`) is used by the new nodes.
  `Shadow/Thumbnail` appears only inside the reused list cells of R5/R6.
- **Not true at the Swift level for metrics.** The spec means *no new Figma variable*. But the drawing carries
  raw values that have **no Swift token**, and implementation has to put them somewhere (precedent:
  `ShelfCardMetrics`, `SortGridMetrics` hold feature-local metrics). The full list:

| Value | Where | Why no token |
|---|---|---|
| Open Sans Regular **9 pt** | `Graph / Friend · Dot` initials | No 9 pt style; smallest is 12 pt (`footnote200`, `action200`, `caption200`) |
| Radius **14** | `Graph / Group · Compact` tile (52 × 52) | Scale is 0 / 4 / 8 / 12 / 24 / 360 |
| Radius **3** | Sheet grabber (36 × 5), minimap viewport | Off scale (Figma has `radius/hairline` 1 and `radius/book` 2, neither in Swift) |
| Radius **1** | Zoom-out minus bar (14 × 2) | Equals Figma `radius/hairline`, which has no Swift case (literal `.rect(cornerRadius: 1)` elsewhere) |
| Padding **3 / 10** (vertical / horizontal) | « Vous » pastille in `Graph / Me` | Spacing scale is 0 / 2 / 4 / 8 / 12 / 16 / 24 / 32 / 64 |
| Padding **6** (vertical) | Counter pill « 42 amis · 7 groupes » | Same |
| Gap **−10** | `Graph / Me`: label overlaps the avatar by 10 | Negative, and 10 is off scale |
| Gap **−8** | Sheet: overlapping « amis en commun » avatars | Negative (magnitude = `.small`) |
| Stroke widths **1.5, 2, 2.5, 3** (and 1) | Edges, avatar rings, group borders | No stroke-width token in Swift (`Constant.borderWidth` = 1 is dead code, D5) |
| Dash patterns **4,4 · 3,3 · 4,3** | Invitation edge (R1/R2, R3) and `Role=Invited` border | No dash token anywhere |
| Opacities **12 %, 30 %, 50 %, 60 %, 80 %** | Edges and dimmed nodes | No `Opacity` type in Swift; Figma's `Opacity` collection only holds `plank` 92 and `backdrop` 20 |
| Paint opacity **12 %** on `foreground/tinted` | Minimap viewport fill | A tint at alpha, not a token |
| Scale **0.7** | « Vous » in R3 | A zoom factor, not a token |
| Sizes 100, 72, 52, 46 × 136, 44, 32, 24, 96 × 140 | Node and control metrics | Only 24 / 36 / 48 / 64 exist, as `ThumbnailSize` in `Features/Components/CellThumbnail.swift` |

---

## Colours

Values are the resolved hex. `#RRGGBBAA` where the token carries alpha. "Same case" means the Swift `case`
is shared, so the two tokens are equal by construction.

| Figma variable | Light | Dark | Swift (`DesignSystem.Color`) | Used in this section for |
|---|---|---|---|---|
| `foreground/default` | `#191919` (gray/900) | `#F1F1F1` (gray/50) | `.foregroundDefault` | Friend / group names, sheet title, nav title « Réseau », zoom-control glyphs (+, −, recentrer), `Icon` strokes, selected segment label |
| `foreground/inverse` | `#F1F1F1` (gray/50) | `#191919` (gray/900) | `.foregroundInverse` | « Vous » pastille text; name + detail of `Graph / Group` `Role=Admin, State=Highlighted` |
| `foreground/secondary` | `#00000080` (black 50 %) | `#FFFFFF99` (white 60 %) | `.foregroundSecondary` | Group detail line (« 12 membres »), sheet body, counter text, unselected segments, section headers, « Invitation de Camille » (R6) |
| `foreground/tinted` | `#558154` (green/700) | `#E7FFCE` (green/200) | `.foregroundTinted` (same case as `.borderTinted`) | **All tinted edges** (ami ↔ groupe, vous ↔ groupe, invitation); Highlighted friend ring; initials (44 pt avatar and 24 pt dot); `Role=Invited` dashed border and its detail line; minimap viewport stroke and 12 % fill; Tinted pill / row-link labels |
| `foreground/tinted-inverse` | `#F2FAE9` (green/100) | `#344E41` (green/900) | `.foregroundTintedInverse` | `Button / Large` Primary label « Ouvrir le groupe », « Accepter » pill label |
| `background/default` | `#FFFFFF` (gray/0) | `#000000` (gray/1000) | `.backgroundDefault` | **Graph screens' background and nav bar (R1–R4)**; Friend Default avatar fill; Member/Invited group card fill; Admin tile fill; zoom controls; counter; minimap; sheet; selected segment; 2 pt ring around the sheet's « amis en commun » avatars; list cards (R5/R6) |
| `background/secondary` | `#F1F1F1` (gray/50) | `#2A2A2A` (gray/800) | `.backgroundSecondary` (`applyListBackground()`) | R5 / R6 screen background |
| `background/tinted` | `#F2FAE9` (green/100) | `#344E41` (green/900) | `.backgroundTinted` | Friend Highlighted avatar fill; Admin group card fill; Member/Invited group tile; `Graph / Friend · Dot` fill; `Graph / Group · Compact` tile fill; « Refuser » pill; Admin tag (R6) |
| `background/tinted-inverse` | `#3A5A40` (green/800) | `#E7FFCE` (green/200) | `.backgroundTintedInverse` | « Vous » ring (3 pt) and pastille; Admin Highlighted card (fill **and** 1 pt stroke); `Graph / Group · Compact` 2 pt border; `Button / Large` Primary; « Accepter » pill |
| `background/disable` | `#E8ECE6` (gray/200) | `#FFFFFF1A` (white 10 %) | `.backgroundDisable` | Segmented control track; `Thumbnail` placeholder (R6 groups without picture) |
| `border/default` | `#0000001A` (black 10 %) | `#FFFFFF1A` (white 10 %) | `.borderDefault` | **Vous ↔ ami edges**; Friend Default avatar 1 pt stroke; dot 1 pt stroke; zoom controls / counter / minimap 1 pt stroke; zoom-control separators; sheet grabber fill; list separators |
| `border/tinted` | `#558154` (green/700) | `#E7FFCE` (green/200) | `.borderTinted` (same case as `.foregroundTinted`) | 1 pt border of `Graph / Group` `Role=Member` and `Role=Admin` (Default) |
| `shadow/light` | `#0000002E` (black 18 %) | `#0000002E` (same) | `DesignSystem.Shadow.light.color` | Colour of `Shadow/Light` |
| `shadow/soft` | `#0000001A` (black 10 %) | `#0000001A` (same) | **no enum case** — literal `Color.black.opacity(0.1)` in `CellThumbnail.swift:71` (issue 0014) | Colour of `Shadow/Thumbnail` (R5/R6 cells only) |

**Raw colours (system chrome, not tokens):** `Chrome / Tab Bar · Réseau` and the R5/R6 `Chrome / Nav Bar`
are filled `#F9F9F9` at 94 %. The R1–R4 nav bar is overridden to `background/default`, which is what the spec
means by « Le graphe est sur background/default (blanc), barre de navigation comprise ». Status bar and home
indicator are literal by design (their component descriptions say so).

**Pairing note.** The « Vous » pastille and the Admin Highlighted card set `foreground/inverse` on
`background/tinted-inverse`, while `Button / Large` Primary and the Prominent pill set
`foreground/tinted-inverse` on the same background. Light: `#F1F1F1` vs `#F2FAE9` (barely different). Dark:
`#191919` vs `#344E41` on `#E7FFCE`. Two pairings for one surface.

---

## Typography

All ten Figma styles have **line height AUTO** and **letter spacing 0 %** (read from the local text styles).
Sizes are unscaled: Swift scales them with `UIFontMetrics(forTextStyle:)` (Dynamic Type); Figma cannot.

| Figma text style | Font | Size | Weight | Dynamic Type anchor | Swift (`DesignSystem.TextStyle`) | Used in this section for |
|---|---|---|---|---|---|---|
| `Title/title200` | Open Sans ExtraBold | 32 | 800 | `.largeTitle` | `.title200` | Nav large title « Réseau » (via `UINavigationBar` appearance) |
| `Title/title50` | Open Sans ExtraBold | 18 | 800 | `.title2` | `.title50` | Sheet title « Club de Belleville » (R2) |
| `Content/content400Bold` | Alegreya Bold | 19 | 700 | `.body` | `.content400Bold` | Row titles in R5/R6 (« Ariane », « Club de Belleville ») |
| `Content/content300` | Alegreya Medium | 17 | 500 | `.body` | `.content300` | Sheet body « Admin · 12 membres, dont 4 de vos amis : … »; row details in R5/R6 |
| `Footnote/footnote200Bold` | Alegreya Bold | 12 | 700 | `.footnote` | `.footnote200Bold` | Group name (`Graph / Group`, `Graph / Group · Compact`); friend name in `State=Highlighted` |
| `Footnote/footnote200` | Alegreya Regular | 12 | 400 | `.footnote` | `.footnote200` | Friend name in `State=Default`; « Invitation de Camille » line in R6 |
| `Action/action300` | Open Sans SemiBold | 17 | 600 | `.body` | `.action300` | Initials inside the 44 pt friend avatar; `Button / Large`; pills; row links |
| `Action/action200` | Open Sans SemiBold | 12 | 600 | `.body` | `.action200` | « Vous » pastille; segmented labels « Tout » « Amis » « Groupes »; counter « 42 amis · 7 groupes »; section headers; Admin tag |
| `Caption/caption200` | Open Sans Regular | 12 | 400 | `.caption1` | `.caption200` | `Graph / Group` detail line (« Admin · 12 membres », « 48 membres », « Invitation de Camille », « 9 membres · 6 amis ») |
| — (raw) | Open Sans Regular | **9** | 400 | — | **none** | `Graph / Friend · Dot` initials (« NO », « IN »…) — **no Swift token** |

Other raw sizes in the file are **scaled copies**, not values to implement: in R3 « Vous » is the 72 pt
`Graph / Me` at 0.7 (pastille text 8.4 pt); in the R4 minimap the whole R3 graph is shrunk to ≈ 0.244
(texts 2.05–2.93 pt).

Weights: Swift declares `.bold` for `action200` / `action300` and `.black` for `title50` / `title200` (D4)
while the files are SemiBold / ExtraBold. Only visible if the custom font fails to load.

---

## Spacing

| Value | Figma variable (where bound) | Swift (`DesignSystem.Spacing`) | Where |
|---|---|---|---|
| 2 | `spacing/xx-small` (bound) | `.xxSmall` | Segmented track inner padding |
| 4 | raw in graph components; `spacing/x-small` bound in R5/R6 | `.xSmall` | `Graph / Friend` avatar ↔ name gap; `Graph / Group · Compact` tile ↔ name gap; section header ↔ card (R5/R6); Tag padding |
| 8 | `spacing/small` (bound) | `.small` | `Graph / Group` padding top/bottom/left and gap; segment padding; segmented control vertical padding. **Raw 8:** sheet inset from screen edges and from the tab bar |
| 12 | `spacing/s-medium` (bound) | `.sMedium` | `Graph / Group` right padding; avatar ↔ text in cells. **Raw 12:** sheet item gap; counter horizontal padding; minimap top offset below the segmented control |
| 16 | `spacing/medium` (bound in chrome) | `.medium` | Segmented control horizontal padding; Button vertical padding. **Raw 16:** sheet padding (all sides); screen gutter of the counter (left), zoom controls and minimap (right); 16 pt between the counter / zoom controls bottom and the tab bar top |
| 24 | `spacing/large` (bound) | `.large` | R5/R6 section spacing; `Button / Large` horizontal padding |
| 3 / 10 | raw | **none** | « Vous » pastille padding (vertical / horizontal) |
| 6 | raw | **none** | Counter pill vertical padding |
| −10 | raw | **none** | `Graph / Me`: pastille overlaps the avatar's bottom by 10 |
| −8 | raw | **none** (= −`.small`) | Sheet « amis en commun » avatars overlap |

Layout anchors measured on the 393-wide frames: segmented control `y 155–195`, graph area `y 195–877`
(682 pt), tab bar from `y 877`. Zoom controls `x 331, y 725` (46 × 136); counter `x 16, y 831` (137 × 30);
minimap `x 281, y 207` (96 × 140); sheet `x 8, y 626` (377 × 243).

---

## Radii

| Value | Figma variable | Swift (`DesignSystem.CornerRadius`) | Where |
|---|---|---|---|
| 360 | `radius/full` — bound on track, Button, pills; **raw** 360 on selected segment, « Vous » pastille, counter | `.full` | Capsules |
| circle | raw 36 / 22 / 12 on 72 / 44 / 24 squares | `.full` or `Circle()` | « Vous » avatar, friend avatar, friend dot |
| 22 | raw | `.full` / `Capsule()` | `Graph / Zoom Controls` (46 wide: a capsule) |
| 24 | raw | `.roundedLarge` | Sheet (R2) |
| 12 | `radius/rounded` bound on `Graph / Group`; raw on minimap | `.rounded` | Group card, minimap |
| 8 | raw on `Graph / Group` tile (32 × 32); `radius/medium` bound on list cards and `Thumbnail` Medium/Medium | `.medium` | Group tile, list cards, group thumbnails |
| 4 | `radius/minimal` (bound) | `.minimal` | Tag (R6) |
| **14** | raw | **none** | `Graph / Group · Compact` tile |
| **3** | raw | **none** | Sheet grabber, minimap viewport |
| **1** | raw (= Figma `radius/hairline`) | **none** | Zoom-out minus bar |

---

## Strokes and dash patterns

None of these has a Swift token. Alignment: node borders are **inside**; edges and the « amis en commun »
ring are **centre** and **outside** respectively.

| Element | Colour | Width | Dash | Notes |
|---|---|---|---|---|
| « Vous » avatar ring | `background/tinted-inverse` | 3 | — | 2.1 in R3 (×0.7) |
| Friend avatar, Default | `border/default` | 1 | — | |
| Friend avatar, Highlighted | `foreground/tinted` | 2 | — | Fill becomes `background/tinted`, name goes Bold |
| Friend dot | `border/default` | 1 | — | |
| Group card Member / Admin | `border/tinted` | 1 | — | |
| Group card Admin Highlighted | `background/tinted-inverse` | 1 | — | Same colour as its fill |
| Group card **Invited** | `foreground/tinted` | **1.5** | **4, 3** | Card is 51 tall instead of 50 because of the 1.5 stroke |
| Group compact tile | `background/tinted-inverse` | 2 | — | |
| Zoom controls, counter, minimap | `border/default` | 1 | — | |
| Recentrer glyph | `foreground/default` | 2 (16 pt ring) + 6 pt filled dot | — | Drawn as two ellipses, not an `Icon` variant |
| Minimap viewport | `foreground/tinted` | 1.5 | — | Fill `foreground/tinted` at 12 % |
| Sheet « amis en commun » avatars | `background/default` | 2, outside | — | 32 pt circles |
| `Icon` glyph vectors (existing) | `foreground/default` | 1.8, round caps | — | Inherited from `Icon` `21:60` |

### Edges, per screen

Every edge is a straight line, centre-aligned. Colours are tokens; the percentage is the **node opacity**
of the vector (the token's own alpha is applied on top — `border/default` is already black 10 %).

| Screen | vous ↔ groupe | ami ↔ groupe | vous ↔ ami | Invitation (vous ↔ group invited to) |
|---|---|---|---|---|
| R1 · Constellation | `foreground/tinted` 1.5 pt, **60 %** | `foreground/tinted` 1.5 pt, **60 %** | `border/default` 1 pt, 100 % | `foreground/tinted` 1.5 pt, 100 %, dash **4, 4** |
| R2 · Groupe touché — lit (the tapped group's edges) | `foreground/tinted` **2.5 pt, 100 %** | `foreground/tinted` **2.5 pt, 100 %** | — | — |
| R2 — everything else | same as R1 at **12 %** | same as R1 at **12 %** | `border/default` 1 pt at **12 %** | dash 4, 4 at **12 %** |
| R3 · Dézoomé | `foreground/tinted` **2 pt, 80 %** | `foreground/tinted` **1 pt, 30 %** | **hidden** | `foreground/tinted` 2 pt, 80 %, dash **3, 3** |
| R4 · Zoomé (« Vous » off-screen, left) | `foreground/tinted` **2 pt, 100 %** | `foreground/tinted` 1.5 pt, 60 % | `border/default` **1.5 pt, 50 %** | none in view |
| R4 minimap | R3 at ≈ 0.244: 0.49 pt 80 % | 0.24 pt 30 % | hidden | 0.49 pt, dash 0.73, 0.73 |

The spec sentence « Arêtes : ami ↔ groupe (foreground/tinted, 60 %), vous ↔ groupe, vous ↔ ami
(border/default) » can be read as *vous ↔ groupe is `border/default`*. **The drawing says otherwise:** vous ↔
groupe is `foreground/tinted` in all four screens, and only vous ↔ ami is `border/default`.

---

## Sizes (component metrics)

| Component / element | Size | Swift equivalent |
|---|---|---|
| `Graph / Me` | 72 × 84 (avatar 72, pastille 49 × 22, overlap −10) | none |
| `Graph / Friend` | 100 × 64 (fixed width 100; avatar 44; gap 4; name 16 tall) | none |
| `Graph / Friend · Dot` | 24 × 24 | value equals `ThumbnailSize.xsmall` (24) |
| `Graph / Group` | hug × 50 (tile 32; 51 for `Invited`) | none |
| `Graph / Group · Compact` | hug × 72 (tile 52, gap 4, name 16) | none |
| `Graph / Zoom Controls` | 46 × 136 (three 44 × 44 buttons, two 28 × 1 separators) | none |
| Zoom-out minus | 14 × 2 | none |
| Counter pill | 137 × 30 (hug) | none |
| Minimap | 96 × 140 | none |
| Sheet | 377 × 243 (hug); grabber 36 × 5; avatars 32 | none |
| `Button / Large` | 345 × 55 | `LargeButtonStyle` |
| `Thumbnail` Medium (R5/R6) | 48 × 48 | `ThumbnailSize.medium` |
| Segmented control | 393 × 40 (track 361 × 36, segments 119 × 32) | native `Picker(...).pickerStyle(.segmented)` today |

Hit targets: nodes are drawn at their visual size only. The 24 pt dot of R3 is below the 44 pt minimum
touch target; nothing in the file says how large its tap area is.

---

## Elevation

| Figma effect style | Offset | Blur | Colour | Swift | Used on |
|---|---|---|---|---|---|
| `Shadow/Light` | 0, 2 | 3 | `shadow/light` (black 18 %) | `.shadow(.light)` (`DesignSystem.Shadow.light`) | « Vous » avatar, friend avatar (both states), group card (all variants), compact tile, zoom controls, counter, minimap, sheet, selected segment |
| `Shadow/Thumbnail` | 0, 0 | **4** | `shadow/soft` (black 10 %) | literal `.shadow(color: .black.opacity(0.1), radius: 2)` in `CellThumbnail.swift:71` | Avatars and group thumbnails in R5/R6 cells only |

`Graph / Group` and `Graph / Zoom Controls` export as a CSS `drop-shadow(0 2px 1.5px)` in the generated code
— that is the same `Shadow/Light` style translated as a filter, not another value.

---

## Opacities

None of these is a token in Swift or in Figma (all raw node opacities; no variable is bound to `opacity`).

| Value | What | Where |
|---|---|---|
| **60 %** | Resting tinted edges (ami ↔ groupe, vous ↔ groupe) | R1; ami ↔ groupe in R4 |
| **30 %** | Dimmed **nodes** when a node is touched (groups, invitation, friends not linked to the touched group). « Vous » stays 100 %. | R2 |
| **12 %** | Dimmed **edges** when a node is touched (all edges not belonging to the touched node, including vous ↔ ami and the invitation) | R2 |
| **80 %** | vous ↔ groupe and invitation edges, zoomed out | R3 (and minimap) |
| **30 %** | ami ↔ groupe edges, zoomed out | R3 (and minimap) |
| **50 %** | vous ↔ ami edges, zoomed in | R4 |
| **12 %** (paint) | Minimap viewport fill on `foreground/tinted` | R4 |
| 94 % (paint) | `#F9F9F9` chrome fill | Tab bar; R5/R6 nav bar |

**« Vous » à 70 % is a size, not an opacity.** In R3 the `Graph / Me` instance (`520:16067`) has opacity
1 and is **scaled to 0.7**: 50.4 × 58.6 instead of 72 × 84, ring 2.1, pastille text 8.4 pt.

**« le reste passe à 30 % » applies to nodes only.** The non-lit edges in R2 go to 12 %, not 30 %.

Token alphas, for reference (they are colours, not opacities): `border/default` 10 %, `foreground/secondary`
50 % (light) / 60 % (dark), `shadow/light` 18 %, `shadow/soft` 10 %.

---

## Divergences that matter here

From [figma-library.md](../../design-system/figma-library.md#divergences-relevées-dans-le-code), plus two
found in this pass.

| # | What | Why it matters for the graph |
|---|---|---|
| D9 (open) | Every shadow is pure black in both modes, so it vanishes on `background/default` in dark (pure black) | The graph sits on `background/default`. In dark mode every node, the zoom controls, the counter, the minimap and the sheet lose their `Shadow/Light` |
| D3 (open) | `DesignSystem.Color.uiColor` ignores `self` and returns black / white for every token | If the edges are drawn through UIKit or Core Graphics, `.uiColor` gives the wrong colour; `SwiftUI.Canvas` / `Path` with `.color` is safe |
| D4 (open) | `title50` declares weight `.black`, file is ExtraBold | Sheet title; only if the font fails |
| D49 (closed) | `border/default` is a veil (black / white 10 %), not a grey | vous ↔ ami edges are a 10 % veil: in R4 at 50 % node opacity they are 5 % black |
| shared case | `borderTinted` and `foregroundTinted` are one Swift `case` | The file strokes edges with `foreground/tinted` and group borders with `border/tinted`: same value, safe either way |
| **new** | `Shadow/Thumbnail` blur is **4** in the Figma effect style, while `CellThumbnail.swift:71` uses radius **2** and figma-library.md's table says 2 | Only R5/R6 cells; the code is the truth |
| **new** | Pastille / Admin Highlighted use `foreground/inverse` on `background/tinted-inverse`; buttons use `foreground/tinted-inverse` on the same fill | Choose one pairing for text on `backgroundTintedInverse` |
| unbound equals | Raw radii 360 / 24 / 12 / 8 and raw paddings 16 / 12 / 8 equal existing tokens but are not bound in Figma | Implement with the tokens (`.full`, `.roundedLarge`, `.rounded`, `.medium`, `.medium`/`.sMedium`/`.small`) |
| chrome | `Chrome / Segmented Control · 3` (`518:510`) is a Figma stand-in; `NetworkView.swift` uses a native `.pickerStyle(.segmented)` with two cases (`NetworkSegment.friends`, `.groups`) | The track / segment tokens above apply only if a custom control replaces the native one |
