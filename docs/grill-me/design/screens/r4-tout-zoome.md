# R4 · Tout · Zoomé

- **Figma node**: `522:15982`, https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=522-15982
- **Section**: `Réseau · Graphe` (`512:15486`), file `S7IvC6GvlcUFe5IgbtvQq6`
- **Screenshot**: [`../screenshots/r4-tout-zoome.png`](../screenshots/r4-tout-zoome.png) (393 × 960, 1×)
- **Frame**: 393 × 960, fill `background/default` (`#FFFFFF`, `DesignSystem.Color.backgroundDefault`). Light mode only.

## What the screen is

This is the same large network as R3 (42 friends, 7 groups), **zoomed in** past the semantic-zoom threshold.
Nodes are drawn in full again: friends show an avatar and a name, and groups show a pill with a picture,
name and detail line. Edges that lead to nodes outside the view run straight off the edge of the screen.
A **minimap** appears top right to show where the view is. The zoom controls and the counter stay exactly as
they are in R3.

From the spec panel (`515:16039`), verbatim:

> zoomé (R4) — nœuds pleins, noms, arêtes qui sortent de l'écran vers les nœuds hors champ, et une minicarte
> en haut à droite qui situe la vue. […] La minicarte n'apparaît qu'une fois zoomé.

## Screen layout (absolute, in screen points)

| Element | Node | x | y | w | h | Notes |
|---|---|---|---|---|---|---|
| Status bar | `522:16089` (`Chrome / Status Bar`, `Theme=Light`) | 0 | 0 | 393 | 59 | system chrome, same as R3 |
| Nav bar (large) | `522:16090` (`Chrome / Nav Bar`, large + action glyph) | 0 | 59 | 393 | 96 | « Réseau » `Title/title200` at (20, 103); `Icon` `plus` 24 × 24 at (351, 71) |
| Segmented control | `522:16093` (`Chrome / Segmented Control · 3`, `Selected=Left`) | 0 | 155 | 393 | 40 | « Tout » selected; « Amis », « Groupes » |
| **Graph area** | `522:16203` frame `graph` | 0 | 195 | 393 | 682 | clips its content |
| **Minimap** | `522:16302` frame `minicarte` | 281 | 207 | 96 | 140 | 16 from the right edge, 12 below the top of the graph area |
| Zoom controls | `522:16094` (`Graph / Zoom Controls`) | 331 | 725 | 46 | 136 | identical to R3 |
| Counter pill | `522:16095` frame `compteur` | 16 | 831 | 137 | 30 | « 42 amis · 7 groupes », identical to R3 |
| Tab bar | `522:16091` (`Chrome / Tab Bar · Réseau`, `Active=Réseau`) | 0 | 877 | 393 | 83 | system chrome |
| Home indicator | `522:16092` (`Chrome / Home Indicator`, `Theme=Light`) | 0 | 926 | 393 | 34 | |

Z-order (bottom → top): graph, status bar, nav, tab bar, home indicator, segmented control, zoom controls,
counter, minimap.

The styling of the status bar, nav bar, segmented control, tab bar, home indicator, zoom controls and counter
pill is **unchanged from R3**. See [`r3-tout-vue-ensemble-dezoome.md`](r3-tout-vue-ensemble-dezoome.md),
section "Chrome components, exact styling". In short:

- Zoom controls: 46 × 136, `background/default`, border 1 `border/default`, radius 22, `Shadow/Light`. They
  hold « + », « − » and « recentrer », and the separators are flush left.
- Counter: `background/default`, border 1 `border/default`, radius 360, padding 12 / 6, `Shadow/Light`. Text
  in `Action/action200`, `foreground/secondary`.

## Layer hierarchy

```
R4 · Tout · Zoomé (FRAME 522:15982, 393×960, fill background/default)
├─ graph (FRAME 522:16203, 0,195, 393×682, clip)
│  ├─ edges (FRAME 522:16237, -260,40, 605×560) — 21 VECTOR lines (522:16217…522:16236, 522:16584, 522:16585)
│  ├─ group/Polar & noir (INSTANCE 522:16238 of Graph / Group · Role=Member, State=Default, 172×50)
│  │    Name « Polar & noir », Detail « 9 membres · 6 amis », Show picture = true
│  ├─ group/SF & imaginaires (INSTANCE 522:16250 of Graph / Group · Role=Member, State=Default, 179×50)
│  │    Name « SF & imaginaires », Detail « 21 membres · 4 amis », Show picture = true
│  └─ friend/<Name> × 8 (INSTANCE of Graph / Friend · State=Default, 100×64)
│       Manon, Théo, Jade (Show photo = false, Initials « JA »), Louis, Alice, Victor, Anna, Eva
├─ status bar · nav · tab bar · home indicator · segmented control   (instances, as in R3)
├─ Graph / Zoom Controls (INSTANCE 522:16094)
├─ compteur (FRAME 522:16095) └─ « 42 amis · 7 groupes » (TEXT 522:16096)
└─ minicarte (FRAME 522:16302, 281,207, 96×140, clip)
   ├─ graph (FRAME 522:16097, 0,-13.30, 96×166.60) — the R3 graph scaled ×0.244275
   │  ├─ edges (FRAME 522:16098, 3.91,8.62, 88.18×134.29) — the 54 R3 edges, scaled
   │  ├─ friend/<Name> × 42 (Graph / Friend · Dot, 5.86×5.86)   522:16153…522:16194
   │  ├─ group/<Name> × 7 (Graph / Group · Compact, w×17.68)    522:16195…522:16201
   │  └─ Graph / Me (12.31×14.63)                                522:16202
   └─ viewport (RECTANGLE 522:16303, 48.85,52.17, 43.97×75.73)
```

Z-order inside `graph`: edges (bottom), then groups, then friends (top). **In R3 it is the other way
round**: there, friends sit under groups.

## Graph components, exact styling

### `Graph / Friend` (component set `512:16016`; variant `State=Default` `512:16008`)

Props: `State` (`Default` | `Highlighted`), `Name`, `Initials`, `Show photo`.

- Vertical stack, **fixed width 100**, gap **4** (a literal equal to `spacing/x-small` / `.xSmall`), centred.
  Height 64.
- Avatar (`512:16009`): 44 × 44 circle (radius 22, so a `Circle()`). Fill `background/default` `#FFFFFF`,
  border **1** `border/default` (`#000000` at 10 %, `.borderDefault`), shadow `Shadow/Light` (0, 2, blur 3,
  `shadow/light` `#000000` at 18 %, `.shadow(.light)`), clip.
- Initials (`512:16010`): `Action/action300`, which is Open Sans SemiBold, `font/size/action-300` = 17,
  weight 600, line-height Auto, letter-spacing 0. Colour `foreground/tinted` `#558154`. Swift: `.action300` on
  `.foregroundTinted`.
- Photo slot (`519:16259`): 44 × 44 at (−1, −1), image fill, clipped to the circle, with the stroke drawn
  over it. Real data is the inventaire.io user `picture`.
- **Fallback**: the initials on a **white** (`background/default`) circle, as on Jade here. The 24-pt dot of
  R3 puts its initials on `background/tinted` instead, so the two fallbacks use different backgrounds.
- Name (`512:16011`): `Footnote/footnote200`, which is Alegreya Regular, `font/size/footnote-200` = 12,
  weight 400, line-height Auto, letter-spacing 0. Colour `foreground/default` `#191919`. Swift: `.footnote200`.
  One line.
- `State=Highlighted` (`512:16012`) is not used on this screen. It is defined for R2: avatar fill
  `background/tinted`, border **2** `foreground/tinted`, photo at (−2, −2), and the name in
  `Footnote/footnote200Bold`.

### `Graph / Group` (component set `512:16061`; variant `Role=Member, State=Default` `512:16017`)

Props: `Role` (`Member` | `Admin` | `Invited`), `State` (`Default` | `Highlighted`), `Name`, `Detail`,
`Show picture`.

- Horizontal stack, items centred, gap `spacing/small` **8** (`.small`). Padding: left `spacing/small` 8,
  right `spacing/s-medium` **12** (`.sMedium`), top and bottom `spacing/small` 8.
- Radius `radius/rounded` **12** (`DesignSystem.CornerRadius.rounded`). Fill `background/default`. Border **1**
  `border/tinted` `#558154` (`.borderTinted`, which is the same case as `.foregroundTinted`). Shadow
  `Shadow/Light`, applied as a drop-shadow on the whole pill.
- Tile (`512:16018`): 32 × 32, radius **8** (a literal equal to `radius/medium` / `.medium`), fill
  `background/tinted` (for Member), clip. It holds `Icon` `person.2` 24 × 24 as the placeholder, and the
  picture slot (`519:16274`) at 32 × 32 (0, 0), image `cover`. Real data is the inventaire.io group `picture`.
- Text column (`512:16025`), clipped, no wrap:
  - Name (`512:16026`): `Footnote/footnote200Bold`, Alegreya Bold 12, weight 700, `foreground/default`.
  - Detail (`512:16027`): `Caption/caption200`, which is Open Sans Regular, `font/size/caption-200` = 12,
    weight 400. Colour `foreground/secondary` (`#000000` at 50 %). Swift: `.caption200` on
    `.foregroundSecondary`.
- Rendered size 172 × 50 (« Polar & noir ») and 179 × 50 (« SF & imaginaires »). The width hugs the text.
- The other variants are not used here:
  - `Admin/Default` (`512:16028`): fill `background/tinted`, tile fill `background/default`.
  - `Invited/Default` (`512:16039`): fill `background/default`, border **1.5 dashed** `foreground/tinted`, and
    the detail line in `foreground/tinted`.
  - `Admin/Highlighted` (`512:16050`): fill and border `background/tinted-inverse`, text `foreground/inverse`.

## Coordinates

All coordinates are **in the `graph` frame** (origin at screen (0, 195)). Add 195 to `y` for screen
coordinates. Edges run **from centre to centre**: the avatar centre for a friend, the pill centre for a group.

### Groups (2 visible)

| Group | Node | Top-left | Size | Centre (edge anchor) | Detail |
|---|---|---|---|---|---|
| « Polar & noir » | `522:16238` | (114, 265) | 172 × 50 | (200, 290) | « 9 membres · 6 amis » |
| « SF & imaginaires » | `522:16250` | (61, 545) | 179 × 50 | (150.5, 570); the edges use (150, 570) | « 21 membres · 4 amis » |

The detail format is « *N* membres · *M* amis ». *M* counts the friends linked to that group: 6 for Polar and
4 for SF, as the edges show. R1 uses a different detail line: « Admin · 12 membres », « 48 membres »,
« Invitation de Camille ».

### Friends (8 visible)

The avatar centre is the top-left plus (50, 22).

| Friend | Node | Top-left | Avatar centre | Shows | Edges |
|---|---|---|---|---|---|
| Manon | `522:16262` | (30, 138) | (80, 160) | photo | Polar, Vous |
| Théo | `522:16267` | (165, 98) | (215, 120) | photo | Polar, Vous |
| Jade | `522:16272` | (295, 278) | (345, 300) | « JA » (no photo) | Polar, Vous |
| Louis | `522:16277` | (270, 408) | (320, 430) | photo | Polar, Vous |
| Alice | `522:16282` | (20, 358) | (70, 380) | photo | Polar, SF, Vous |
| Victor | `522:16287` | (185, 408) | (235, 430) | photo | Polar, SF, Vous |
| Anna | `522:16292` | (−10, 478) | (40, 500) | photo | SF, Vous |
| Eva | `522:16297` | (250, 578) | (300, 600) | photo | SF, Vous |

Jade's 100-pt frame runs 2 pt past the right edge (x 295–395), and Anna's starts 10 pt before the left edge.
Both avatars are fully on screen. Nodes are allowed to be cut by the screen edge.

### Off-screen nodes the edges point to

These coordinates are inferred from where the edges end; no node is drawn at them.

| Point (graph coords) | Screen | What it is |
|---|---|---|
| (−260, 40) and (−240, 120) | (−260, 235) and (−240, 315) | the two ends of the **you ↔ group** edges, Polar and SF. Each is about 41 pt from (−250, 80), roughly on the rim of « Vous »'s 72-pt avatar, so « Vous » sits **about 250 pt off the left edge, near the top**. |
| (−250, 80) | (−250, 275) | where all nine **you ↔ friend** edges converge: « Vous ». |
| (305, 150) | (305, 345) | the end of an edge (`522:16222`) to « Vous » from a node that is **not drawn**. That point is under the bottom edge of the minimap (which covers screen y 207–347), so it reads as a friend hidden behind the minimap. |

## Edges

The `edges` frame (`522:16237`) is at graph (−260, 40) and measures 605 × 560. It holds 21 straight lines,
with butt caps, clipped by the `graph` frame. Nothing marks where an edge leaves the screen (no fade, arrow
or badge).

| Kind | Count | Stroke | Width | Layer opacity | Dash |
|---|---|---|---|---|---|
| you ↔ group | 2 (`522:16217` Polar, `522:16218` SF) | `foreground/tinted` `#558154` | **2** | **100 %** | solid |
| friend ↔ group | 10 | `foreground/tinted` `#558154` | **1.5** | **60 %** | solid |
| you ↔ friend | 9 | `border/default` (`#000000`, stroke alpha **10 %**) | **1.5** | **50 %** (≈ 5 % black in effect) | solid |

- **friend ↔ group**: Polar has 6 (Manon `522:16219`, Jade `522:16223`, Louis `522:16225`, Alice `522:16227`,
  Victor `522:16230`, Théo `522:16584`). SF has 4 (Alice `522:16228`, Victor `522:16231`, Anna `522:16233`,
  Eva `522:16235`).
- **you ↔ friend**: Manon `522:16220`, the hidden node `522:16222`, Jade `522:16224`, Louis `522:16226`,
  Alice `522:16229`, Victor `522:16232`, Anna `522:16234`, Eva `522:16236`, Théo `522:16585`. All of them run
  off-screen to the left, toward (−250, 80).
- Where the you ↔ group edges cross the left edge: Polar ↔ Vous crosses x = 0 at graph y ≈ 181 (screen 376),
  and SF ↔ Vous at graph y ≈ 397 (screen 592).
- None of the widths (1.5, 2), opacities (50 %, 60 %) or the 10 % stroke alpha has an Opacity token. The
  10 % is the `border/default` colour itself (`.borderDefault`); the 50 % is a layer opacity on top of it.

## Minimap: frame `minicarte` (`522:16302`)

### Container

- **96 × 140** at screen (281, 207). That is 16 from the right edge (393 − 377) and 12 below the top of the
  graph area (207 − 195; 12 equals `spacing/s-medium`, but here it is a literal).
- Fill `background/default` `#FFFFFF`. Border **1** `border/default` (`#000000` at 10 %), solid; it renders as
  `#E5E5E5` on white.
- Radius **12**, an unbound literal equal to `radius/rounded` (`.rounded`).
- Shadow `Shadow/Light`: (0, 2), blur 3, `shadow/light` `#000000` at 18% (`.shadow(.light)`).
- Clip content: yes.

### Content: the whole network, drawn the R3 way

- Inner frame `graph` (`522:16097`) is **R3's 393 × 682 graph area scaled uniformly by 96 / 393 = 0.244275**,
  giving 96 × 166.60. It is placed at (0, −13.30), so it is **vertically centred**:
  (140 − 166.60) / 2 = −13.30.
  - The minimap fits the **width** and crops 13.3 pt at the top and bottom, which is 54.4 pt of graph space at
    each end. As a result, **Mila and Camille fall entirely above the visible area, and Noé is mostly
    clipped**. Clara, the lowest node, is still visible.
- Every node is the **same component as in R3, scaled by 0.244275**, with the same positions. For example,
  Inès is at (260, 148) in R3 and at (63.51, 36.15) here. Nothing is simplified for the small scale:
  - Friend dot: 5.86 × 5.86, border 0.244 `border/default`, fill `background/tinted`. Initials at 2.2 pt
    (illegible). The photo is kept.
  - Group compact: tile 12.70 × 12.70, border 0.489 `background/tinted-inverse`, shadow (0, 0.49, 0.73)
    `shadow/light`, glyph 5.86. The picture is kept. The name label is at 2.93 pt (illegible). Instance boxes
    are 21, 31, 15, 21, 19, 25 and 21 × 17.68.
  - « Vous »: avatar 12.31, ring 0.513, label « Vous » at 2.05 pt.
  - The export gives the scaled nodes their **unscaled radius values**: `rounded-[12px]` on 5.86-pt dots,
    `rounded-[14px]` on 12.7-pt tiles, `rounded-[36px]` on the 12.3-pt Me. For the circles this makes no
    difference; for the group tiles it is unclear whether they should be scaled squircles (14 × 0.244 ≈ 3.4)
    or circles.
- Edges (`522:16098`, at (3.91, 8.62), 88.18 × 134.29) are R3's 54 edges scaled by the same factor:
  - you ↔ group: `#558154`, width **0.489**, opacity 80 %.
  - invitation (« Lecteurs du 11e »): the same, dashed **0.73 / 0.73**.
  - friend ↔ group: `#558154`, width **0.244**, opacity 30 %.
  - **No you ↔ friend edges.** The minimap shows the overview (R3) mode, not the zoomed one.

### Viewport rectangle: `viewport` (`522:16303`)

- Position inside `minicarte`: (48.85, 52.17), size **43.97 × 75.73**. On screen that is x 329.85–373.82 and
  y 259.17–334.90. It sits 3.2 pt from the minimap's right edge and 12.1 pt from its bottom.
- **Fill `foreground/tinted` `#558154` at ≈ 12 %.** The export drops the paint opacity; the value comes from
  the render, which is `#EAEFEA` over white, giving α ≈ 0.12. **There is no Opacity token for 12 %.**
- **Stroke 1.5, inside, `foreground/tinted` `#558154`, 100 %**, solid.
- Radius **3**. **There is no `CornerRadius` case for 3** (`.minimal` is 4).
- It is drawn **above** the minimap content, so its tinted fill veils the nodes under it.
- **What it frames, in R3 graph coordinates**: (48.85 / s, (52.17 + 13.30) / s) with s = 0.244275, which is
  **x 200–380, y 268–578, a 180 × 310 region**. Its aspect ratio (0.581) matches the screen's graph area
  (393 / 682 = 0.576). That gives a **zoom factor of ≈ 2.18×** (393 / 180) between R3 and R4.

## Visual states shown

- **Semantic zoom = zoomed.** All visible nodes are full components, and every node is in its `Default`
  state: no highlight, nothing dimmed.
- **Photo vs fallback.** Seven friends have a photo. Jade shows « JA » on white. Both groups have a picture.
- **Group role.** Both visible groups are `Role=Member`. No admin or invited group is in view.
- **Edges leaving the view.** All you ↔ friend and you ↔ group edges run off the left edge toward the
  off-screen « Vous ».
- **Minimap visible**, with the viewport rectangle in the lower-right part of the network.
- **Segmented control**: « Tout ». **Tab bar**: « Réseau » active. **Counter**: « 42 amis · 7 groupes »,
  unchanged because it counts the whole network, not what is on screen.

## Interactions the design implies

| Gesture / control | Effect |
|---|---|
| Pinch out / in | Zoom. Zooming back out below the threshold returns to the R3 rendering, and the minimap disappears (« La minicarte n'apparaît qu'une fois zoomé »). |
| Drag (pan) | Move the view. The minimap's viewport rectangle should follow. Nodes may be cut by the screen edges (Jade, Anna). |
| Zoom controls « + » / « − » | One zoom step in or out. |
| Zoom controls « recentrer » | Centre the view on « Vous », which is off-screen here; this is the way back to it. |
| Tap a friend or group | R2 behaviour: its edges light up, everything else drops to 30 %, and a sheet summarises it (« Voir le profil » for a friend). The 44-pt avatars and 50-pt pills are proper touch targets. |
| Tap empty space | Closes the sheet. |
| Minimap | **Not specified.** Nothing says whether tapping or dragging on it moves the view. |
| Off-screen edges | **Not specified.** Nothing says whether an edge or its end can be followed (for example, tapping a line to jump to the other node). |
| Segmented control, « + » in the nav, counter | As in R3. The « + » is undecided (À trancher #4), and the counter is informational. |

## What changes compared with the sibling screens

| | R1 · Constellation (`512:15513`) | R3 · Dézoomé (`520:15762`) | **R4 · Zoomé** |
|---|---|---|---|
| Network | 8 friends, 3 groups, all on screen | 42 + 7, all on screen | **42 + 7, a ≈ 2.18× crop of it** |
| Friend node | `Graph / Friend` | `Graph / Friend · Dot` 24 pt | **`Graph / Friend`** (44-pt avatar + name) |
| Group node | `Graph / Group` (details « Admin · 12 membres », « 48 membres », « Invitation de Camille ») | `Graph / Group · Compact` | **`Graph / Group`, detail « N membres · M amis »** |
| « Vous » | on screen, 100 % | on screen, 70 % | **off-screen (left)** |
| you ↔ group edge | 1.5, 60 % | 2, 80 % | **2, 100 %** |
| friend ↔ group edge | 1.5, 60 % | 1, 30 % | **1.5, 60 %** |
| you ↔ friend edge | `border/default` 1 pt, 100 % | hidden | **`border/default`, 1.5, layer 50 %** |
| Node z-order | — | friends under groups | **friends above groups** |
| Zoom controls / counter | absent | present | present, unchanged |
| Minimap | absent | absent | **present** (96 × 140, top right) |

R2 adds a group sheet to R1. R5 and R6 are the « Amis » and « Groupes » lists.

## Token map used on this screen

| Figma | Value | Swift |
|---|---|---|
| `background/default` | `#FFFFFF` | `DesignSystem.Color.backgroundDefault` |
| `background/tinted` | `#F2FAE9` | `.backgroundTinted` |
| `background/tinted-inverse` | `#3A5A40` | `.backgroundTintedInverse` (the minimap's « Vous » and tiles) |
| `background/disable` | `#E8ECE6` | `.backgroundDisable` (segmented track) |
| `foreground/default` | `#191919` | `.foregroundDefault` |
| `foreground/secondary` | `#000000` at 50 % | `.foregroundSecondary` |
| `foreground/tinted` | `#558154` | `.foregroundTinted` |
| `foreground/inverse` | `#F1F1F1` | `.foregroundInverse` |
| `border/default` | `#000000` at 10 % | `.borderDefault` |
| `border/tinted` | `#558154` | `.borderTinted` |
| `shadow/light` / `Shadow/Light` | `#000000` at 18 %, (0, 2), blur 3 | `DesignSystem.Shadow.light` → `.shadow(.light)` |
| `Title/title200` | Open Sans ExtraBold 32 | `DesignSystem.TextStyle.title200` |
| `Action/action300` | Open Sans SemiBold 17 | `.action300` |
| `Action/action200` | Open Sans SemiBold 12 | `.action200` |
| `Footnote/footnote200` | Alegreya Regular 12 | `.footnote200` |
| `Footnote/footnote200Bold` | Alegreya Bold 12 | `.footnote200Bold` |
| `Caption/caption200` | Open Sans Regular 12 | `.caption200` |
| `spacing/xx-small` / `small` / `s-medium` / `medium` | 2 / 8 / 12 / 16 | `DesignSystem.Spacing.xxSmall` / `.small` / `.sMedium` / `.medium` |
| `radius/rounded` / `radius/full` | 12 / 360 | `DesignSystem.CornerRadius.rounded` / `.full` |

**Values with no Swift token**:

- the minimap viewport: fill at ≈ 12 %, stroke 1.5, radius 3;
- the edges: widths 1.5 and 2, opacities 50 % and 60 %;
- the minimap's scale factor 0.244275 and the ≈ 2.18× zoom;
- the R3-derived literals inside the minimap: 9-pt initials, tile radius 14, ring 3, compact border 2;
- the zoom-controls radius 22 and the counter's 6-pt vertical padding (as in R3).

These values are unbound literals equal to existing tokens: the minimap radius 12 (`.rounded`), the minimap
inset 12 (`.sMedium`), the group-tile radius 8 (`.medium`), and the friend stack gap 4 (`.xSmall`).

## Not drawn / ambiguous

1. **R4 does not match its own minimap.** The viewport frames R3's region x 200–380, y 268–578. With R3's
   data that region contains Polar & noir, SF & imaginaires, Paul, Omar, Alice, Manon and Anna, with
   « Vous » about 9 pt off the left edge after zooming. R4 instead shows Manon, Théo, Jade, Louis, Alice,
   Victor, Anna and Eva, and puts « Vous » about 250 pt off-screen. The counts match R3 (Polar 6 friends,
   SF 4) but the names do not. Eva even has a photo here and only the initials « EV » in R3. Treat the
   placement as illustrative.
2. **The two you ↔ group edges end at different points** ((−260, 40) and (−240, 120)), while the friend edges
   converge on (−250, 80). Edges are meant to end at the « Vous » centre.
3. **A node hidden under the minimap.** Edge `522:16222` ends at (305, 150), under the minimap, where no node
   is drawn. The design does not say whether the minimap may cover nodes, whether nodes avoid it, or whether
   it should get out of the way during a pan.
4. **The minimap crops the top and bottom of the network**, because it fits the width of a 393 × 682 frame
   into 96 × 140: Mila and Camille are outside it. The design does not say whether it should fit the network's
   bounding box instead (in both dimensions).
5. **Minimap interactions are unspecified**: tap to jump, drag the viewport, or display only. Its accessibility
   is not specified either (it may be decorative).
6. **The minimap's level of detail.** It reuses the full R3 nodes (photos, 2-pt labels) at 0.244×. For an
   implementation, simple dots and tiles may be enough; the design does not say. The tile radius at minimap
   scale is ambiguous (see above).
7. **The viewport fill opacity (≈ 12 %) is measured from the render.** The Figma export omits the paint
   opacity, so this needs confirming in the file.
8. **Edge styling differs between R1, R3 and R4** (60/80/100 % for you ↔ group; 60/30/60 % for friend ↔ group;
   you ↔ friend at 100 % in R1 and 50 % in R4). It is unclear whether there are two discrete styles (overview
   and zoomed) or whether they interpolate with zoom.
9. **Nothing marks where an edge leaves the screen.** There is no indication of where an edge leads, and no
   count of off-screen neighbours.
10. **Z-order flips** between R3 (friends under groups) and R4 (friends above groups).
11. **Two fallback backgrounds for initials**: `background/default` on `Graph / Friend` and
    `background/tinted` on `Graph / Friend · Dot`. This may be intentional, since the dot needs to read
    without a shadow, but it is unconfirmed.
12. **The zoom range and steps are not given**: the minimum and maximum zoom, the step of « + » and « − »,
    the threshold scale (« 20 nœuds ? », À trancher #1), and the animation between modes.
13. **The semantic switch.** No intermediate frame shows the swap between dots and full nodes (a cross-fade,
    or positions held during the swap).
14. **Not drawn** (À trancher #5): dark mode, the empty state, loading, VoiceOver, and the sent-requests
    question (#3).
15. **Mock imagery.** Avatars and group pictures are illustrations. The real data is the inventaire.io user
    `picture` and group `picture`, and they are not assets to ship.
