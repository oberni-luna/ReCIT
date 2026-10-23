# R3 · Tout · Vue d'ensemble · Dézoomé

- **Figma node**: `520:15762`, https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=520-15762
- **Section**: `Réseau · Graphe` (`512:15486`), file `S7IvC6GvlcUFe5IgbtvQq6`
- **Screenshot**: [`../screenshots/r3-tout-vue-ensemble-dezoome.png`](../screenshots/r3-tout-vue-ensemble-dezoome.png) (393 × 960, 1×)
- **Frame**: 393 × 960, fill `background/default` (`#FFFFFF`, `DesignSystem.Color.backgroundDefault`). Light mode only.

## What the screen is

This is the **Tout** segment of the Réseau tab, opened on a large network: 42 friends and 7 groups, framed
to show the whole network at once. This is the "overview" end of the semantic zoom. Friends become 24-pt
dots with no name. Groups become 52-pt tiles that keep their name. The edges from you to each friend
disappear, and « Vous » is drawn at 70 %. Two overlays sit on the graph: the zoom controls (bottom right)
and a counter pill (bottom left). There is no minimap in this state: it appears only once the user zooms in
(see R4).

The spec panel (`515:16039`, frame `Spec · Réseau en graphe`) describes the semantic zoom this way (verbatim):

> dézoomé (R3) — les amis deviennent des pastilles de 24 pt sans nom (Graph / Friend · Dot), les groupes des
> tuiles de 52 pt avec leur nom (Graph / Group · Compact), les arêtes vous ↔ ami disparaissent, « Vous » à 70 %

## Screen layout (absolute, in screen points)

| Element | Node | x | y | w | h | Notes |
|---|---|---|---|---|---|---|
| Status bar | `520:15797` (instance of `Chrome / Status Bar`, `Theme=Light`) | 0 | 0 | 393 | 59 | "9:41", Inter SemiBold 17, literal black. System chrome. |
| Nav bar (large) | `520:15798` (instance of `Chrome / Nav Bar`, large style + action glyph) | 0 | 59 | 393 | 96 | fill `background/default` |
| ↳ large title « Réseau » | `I520:15798;26:115` | 20 | 103 | 353 (left 20 / right 20) | — | `Title/title200` |
| ↳ action glyph « + » | `I520:15798;26:116` | 351 | 71 | 24 | 24 | `Icon` glyph `plus`, `foreground/default` (right inset 18, top 12 inside the nav) |
| Segmented control | `520:15801` (instance of `Chrome / Segmented Control · 3`, `Selected=Left`) | 0 | 155 | 393 | 40 | « Tout » selected |
| **Graph area** | `520:15802` frame `graph` | 0 | 195 | 393 | 682 | clips its content; no fill of its own (white comes from the screen frame) |
| Zoom controls | `521:15981` (instance of `Graph / Zoom Controls`) | 331 | 725 | 46 | 136 | 16 from the right edge, bottom at 861, so 16 above the tab bar |
| Counter pill | `521:15993` frame `compteur` | 16 | 831 | 137 | 30 | 16 from the left edge, bottom at 861, so 16 above the tab bar. Its bottom lines up with the zoom controls'. |
| Tab bar | `520:15799` (instance of `Chrome / Tab Bar · Réseau`, `Active=Réseau`) | 0 | 877 | 393 | 83 | system chrome |
| Home indicator | `520:15800` (instance of `Chrome / Home Indicator`, `Theme=Light`) | 0 | 926 | 393 | 34 | overlaps the bottom of the tab bar |

Z-order (bottom → top): graph, status bar, nav, tab bar, home indicator, segmented control, zoom controls, counter.

## Layer hierarchy

```
R3 · Tout · Vue d'ensemble · Dézoomé (FRAME 520:15762, 393×960, fill background/default)
├─ graph (FRAME 520:15802, 0,195, 393×682, clip)
│  ├─ edges (FRAME 520:15870, 16,35.30, 361×549.75) — 54 VECTOR lines (520:15816 … 520:15869)
│  ├─ friend/<Name> × 42 (INSTANCE of Graph / Friend · Dot 519:16390, 24×24)
│  │    props: Initials (text), Show photo (bool)
│  │    children: initials TEXT (519:16391), photo (519:16392, image fill, only when Show photo)
│  ├─ group/<Name> × 7 (INSTANCE of Graph / Group · Compact 519:16401, w×72)
│  │    props: Name (text), Show picture (bool)
│  │    children: tile (519:16402) › Icon person.2 (498:378) + picture (519:16409); name TEXT (519:16410)
│  └─ Graph / Me (INSTANCE of Graph / Me 512:16006, scaled to 70 %: 50.4×58.6)
│       children: avatar (519:16387) › photo (519:16278); label (519:16388) › « Vous » (519:16389)
├─ status bar (INSTANCE 520:15797 · Chrome / Status Bar · Theme=Light)
├─ nav (INSTANCE 520:15798 · Chrome / Nav Bar — large title « Réseau », action glyph plus)
├─ tab bar (INSTANCE 520:15799 · Chrome / Tab Bar · Réseau · Active=Réseau)
├─ home indicator (INSTANCE 520:15800 · Chrome / Home Indicator · Theme=Light)
├─ segmented control (INSTANCE 520:15801 · Chrome / Segmented Control · 3 · Selected=Left)
│    labels: « Tout » | « Amis » | « Groupes »
├─ Graph / Zoom Controls (INSTANCE 521:15981 of 521:15969)
│    zoom in (521:15970) › Icon plus · separator (521:15974) · zoom out (521:15975) › minus (521:15976)
│    · separator (521:15977) · recentrer (521:15978, vector)
└─ compteur (FRAME 521:15993, 16,831, 137×30)
     └─ « 42 amis · 7 groupes » (TEXT 521:15994, at 13,7, 111×16)
```

## Chrome components, exact styling

### Nav bar: `Chrome / Nav Bar` (`26:162`), large style

- Height 96, below the 59-pt status bar. Fill `background/default` (`#FFFFFF`). The spec says the graph sits on
  white, nav bar included.
- Title « Réseau »: `Title/title200`, which is Open Sans ExtraBold, `font/size/title-200` = 32, weight 800,
  line-height Auto (Figma reports `lineHeight: 100`, the export renders `normal`), letter-spacing 0. Colour
  `foreground/default` `#191919`. Swift: `DesignSystem.TextStyle.title200` on `.foregroundDefault`. This is
  already the app's `largeTitleTextAttributes`.
- Action glyph: `Icon` `plus`, 24 × 24, `foreground/default`. The spec has not decided what it does (see
  "Not drawn / ambiguous").

### Segmented control: `Chrome / Segmented Control · 3` (component set `518:510`, variant `518:486`)

Component description: « Trois segments : Tout | Amis | Groupes de l'onglet Réseau (proposition Réseau · Graphe). »

- Outer frame 393 × 40, padding horizontal `spacing/medium` 16 (`.medium`), vertical `spacing/small` 8 (`.small`),
  items centred.
- Track (`518:487`): fill `background/disable` `#E8ECE6` (`.backgroundDisable`), radius `radius/full` 360
  (`.full`), padding `spacing/xx-small` 2 (`.xxSmall`), clip. Rendered bounds are x 16–377, y ≈157–193, so
  361 × ≈36. The track is taller than the 40-pt frame minus its 8-pt padding: it overflows by about 6 pt and
  stays centred.
- Selected segment « Tout » (`518:488`): fill `background/default`, radius 360 (a literal, not bound),
  `Shadow/Light`, padding `spacing/small` 8. Rendered at about 119.7 × 32.3. Each segment takes 1/3 of
  (361 − 4).
- Labels: `Action/action200`, which is Open Sans SemiBold, `font/size/action-200` = 12, weight 600,
  line-height Auto, letter-spacing 0. « Tout » is in `foreground/default` `#191919`. « Amis » and « Groupes »
  are in `foreground/secondary` `#000000` at 50 % (`.foregroundSecondary`).
- Swift today: `NetworkView` uses a native `Picker(...).pickerStyle(.segmented)` with **two** cases
  (`NetworkSegment.friends`, `.groups`). The design adds a third segment, « Tout », and selects it in this
  screen. It also draws the control in tokens (`background/disable` track, white pill with `Shadow/Light`),
  which a native segmented picker does not render.

### Tab bar: `Chrome / Tab Bar · Réseau` (`498:14327`), `Active=Réseau`

- 393 × 83. Fill `rgba(249,249,249,0.94)` (literal system chrome) and a top hairline 0.5 `rgba(0,0,0,0.16)`.
  Items row 49 high at y 4.
- Four tabs: « Inventaire » (book), « Listes » (list.clipboard), « Réseau » (person.2), « Profil » (person).
  Glyphs are 26 × 26 with a gap of 2.
- Inactive labels: Inter Medium 10, `#8E8E93`. The active label « Réseau » is Inter SemiBold 10 in
  `foreground/tinted` `#558154`. These are literal iOS chrome values, not tokens; the code uses the native
  `TabView`.

### Status bar and home indicator

These are literal iOS chrome. The status bar shows "9:41", Inter SemiBold 17 in black, with the cellular,
wifi and battery icons. The home indicator's grabber is 140 × 5, radius 2.5, black, 21 pt from the top of
its 34-pt inset. Neither needs implementing; the system draws both.

### Zoom controls: `Graph / Zoom Controls` (`521:15969`)

Component description: « Zoom du graphe Réseau · Tout : +, −, recentrer sur « Vous ». Le pincement reste le
geste principal. »

- Vertical stack, 46 × 136, which is 3 × 44 + 2 × 1 + a 1-pt border on each side.
- Fill `background/default`, border 1 `border/default` (`#000000` at 10 %, `.borderDefault`), radius **22**
  (half of 44, so a capsule). There is **no `CornerRadius` case for 22**; use `Capsule()` / `.full`.
- Shadow `Shadow/Light`, which is (0, 2), blur 3, `shadow/light` `#000000` at 18 %. The export applies it as
  a `drop-shadow` filter. Swift: `.shadow(.light)`.
- Items, each 44 × 44 and centred:
  1. **zoom in** (`521:15970`): `Icon` `plus`, 24 × 24, `foreground/default`.
  2. separator (`521:15974`): 28 × 1, fill `border/default`.
  3. **zoom out** (`521:15975`): a 14 × 2 bar, radius 1, `foreground/default` `#191919`.
  4. separator (`521:15977`): 28 × 1, `border/default`.
  5. **recentrer** (`521:15978`): a vector 44 × 44 holding a ring (circle r = 7, stroke 2, `#191919`) and a
     dot (circle r = 3, fill `#191919`), both centred. The colour is `foreground/default`, flattened to a
     literal in the vector.
- The stack's cross-axis alignment is `start`, so the 28-pt **separators are flush left** (rendered at
  x 332–359), not centred under the 44-pt buttons. This is probably unintended; see "Not drawn / ambiguous".

### Counter pill: frame `compteur` (`521:15993`)

- 137 × 30 at (16, 831). Fill `background/default`, border 1 `border/default`, radius 360 (a literal equal to
  `radius/full`), clip. Shadow `Shadow/Light` (0, 2, 3, `shadow/light`).
- Padding: horizontal **12** (literal; equal to `spacing/s-medium` / `.sMedium`) and vertical **6** (literal).
  **There is no Spacing token for 6.**
- Text « 42 amis · 7 groupes » (`521:15994`): `Action/action200`, Open Sans SemiBold 12, weight 600,
  line-height Auto, letter-spacing 0, colour `foreground/secondary` (`#000000` at 50 %). Its box is 111 × 16.
- The counts match the drawing: 42 friend dots and 7 group tiles. The separator is « · » (a middle dot with a
  space either side).

## Graph components, exact styling

### `Graph / Friend · Dot` (`519:16390`)

- 24 × 24 circle (radius 12, so a `Circle()`). Fill `background/tinted` `#F2FAE9` (`.backgroundTinted`),
  border **1** `border/default` (`#000000` at 10 %), clip content. No shadow.
- Initials: Open Sans Regular **9**, colour `foreground/tinted` `#558154` (`.foregroundTinted`), centred, no
  wrap. **There is no TextStyle at 9 pt** (`caption200` is 12); flag it.
- Photo slot (`519:16392`): 24 × 24 at (−1, −1), image fill, clipped to the circle. The frame stroke is drawn
  over it. Real data is the inventaire.io user `picture`; the mock-ups are illustrations.
- Fallback, when `Show photo` is false: the two-letter initials on `background/tinted`. The initials are the
  first two letters of the first name, upper-cased, **with their diacritics** (« LÉ », « AÏ », « ÉL », « HÉ »,
  « NO » for Noé, « CH » for Chloé). There is no initials helper in the Swift code today.
- No name label, by design.

### `Graph / Group · Compact` (`519:16401`)

- Vertical stack, gap **4** (a literal equal to `spacing/x-small` / `.xSmall`), centred. Width = max(52, width
  of the label); height 72.
- Tile (`519:16402`): 52 × 52, fill `background/tinted` `#F2FAE9`, border **2** `background/tinted-inverse`
  `#3A5A40` (`.backgroundTintedInverse`), radius **14**, clip, shadow `Shadow/Light`. **There is no
  `CornerRadius` case for 14** (the scale is 4, 8, 12, 24).
- Placeholder: `Icon` `person.2`, 24 × 24, `foreground/default`, centred. It shows only when there is no
  picture.
- Picture slot (`519:16409`): 52 × 52 at (−2, −2), image fill `cover`, clipped by the tile's radius. Real data
  is the inventaire.io group `picture`.
- Name (`519:16410`): `Footnote/footnote200Bold`, which is Alegreya Bold, `font/size/footnote-200` = 12,
  weight 700, line-height Auto, letter-spacing 0. Colour `foreground/default`. Swift: `.footnote200Bold`. One
  line, no truncation drawn.
- This component has **no Role or State property**. Admin, member and invited groups look the same here;
  only the dashed edge marks the invitation.

### `Graph / Me` (`512:16006`), placed at **70 %**

Base component (100 %) → R3 instance (× 0.7):

| Part | Base | R3 (70 %) | Token |
|---|---|---|---|
| Overall | 72 × 84 | 50.4 × 58.6 at (171, 305) in the graph | — |
| Avatar | 72 circle (radius 36), fill `background/default`, clip | 50.4 | `.backgroundDefault` |
| Avatar ring | border **3** `background/tinted-inverse` `#3A5A40` | 2.1 | `.backgroundTintedInverse` |
| Avatar shadow | `Shadow/Light` (0, 2, 3) | (0, 1.4, 2.1) | `.shadow(.light)` scaled |
| Photo | 72 × 72 at (−3, −3) | 50.4 at (−2.1, −2.1) | user's inventaire.io picture |
| Label pill | overlaps the avatar by 10 (`margin-bottom −10`); fill `background/tinted-inverse`; radius 360; padding **10** horizontal / **3** vertical; clip | overlap 7, padding 7 / 2.1 | the 10 and 3 paddings have **no Spacing token** |
| « Vous » | `Action/action200` Open Sans SemiBold 12, `foreground/inverse` `#F1F1F1` | 8.4 pt | `.action200` on `.foregroundInverse` |

The 70 % is a uniform scale of the whole node, not a separate variant. In SwiftUI the natural port is
`.scaleEffect(0.7)` on the same view rather than new sizes. The edges meet at the avatar centre, which is
(196.2, 330.2) in graph coordinates and (196.2, 525.2) on screen.

## Coordinates

All node coordinates below are **in the `graph` frame** (origin at screen (0, 195), 393 × 682). Add 195 to
`y` for screen coordinates. The edge vectors are expressed in the same graph space, and every edge runs from
**centre to centre**, drawn under the nodes.

Z-order inside `graph`: edges (bottom), then the 42 friend dots, then the 7 group tiles, then « Vous » (top).

### « Vous »

| Node | Top-left | Size | Centre (edge anchor) |
|---|---|---|---|
| Graph / Me (`520:16067`) | (171, 305) | 50.4 × 58.6 | (196.2, 330.2), the avatar centre |

### Groups (7)

| Group | Node | Top-left | Size | Tile centre | Picture | Edge to « Vous » |
|---|---|---|---|---|---|---|
| « Club de Belleville » | `520:15997` | (153, 129) | 86 × 72 | (196, 155) | yes | solid |
| « BD & romans graphiques » | `520:16007` | (225, 195) | 126 × 72 | (288, 221) | yes | solid |
| « Polar & noir » | `520:16017` | (281, 343) | 61 × 72 | (311.5, 369) | yes | solid |
| « SF & imaginaires » | `520:16027` | (204, 462) | 86 × 72 | (247, 488) | yes | solid |
| « Lecteurs du 11e » | `520:16037` | (107, 462) | 75 × 72 | (144.5, 488) | **no**, `person.2` glyph | **dashed** (invitation) |
| « Poésie du dimanche » | `520:16047` | (31, 343) | 100 × 72 | (81, 369) | yes | solid |
| « Classiques en VO » | `520:16057` | (61, 195) | 85 × 72 | (103.5, 221) | **no**, `person.2` glyph | solid |

**Layout intent.** The seven tile centres sit **evenly on an ellipse centred on « Vous »**. Relative to Vous
the semi-axes are a ≈ 118.5 (horizontal) and b = 175 (vertical). The parametric angle starts at −90°, so
« Club de Belleville » is straight up, and each next group is 360°/7 ≈ 51.4° further on: BD −38.6°, Polar
12.9°, SF 64.3°, Lecteurs 115.7°, Poésie 167.1°, Classiques 218.6°. Going clockwise from the top, the order
is Club → BD → Polar → SF → Lecteurs → Poésie → Classiques, and the layout is mirror-symmetric about x = 196.
The ellipse is taller than it is wide, to fit the portrait graph area. The spec's own placement rule is
« graphe à forces à graine fixe, pour qu'il ne bouge pas d'une ouverture à l'autre ; fonction pure, testable »,
so this ring is what that layout should roughly produce. It is not a hard rule.

### Friends (42)

Dots are 24 × 24, and the centre is the top-left plus (12, 12). « Shows » is either the photo or the initials
fallback. Groups are named by short labels: Club = Club de Belleville, BD = BD & romans graphiques,
Polar = Polar & noir, SF = SF & imaginaires, L11 = Lecteurs du 11e, Poésie = Poésie du dimanche,
Classiques = Classiques en VO.

| # | Friend | Node | Top-left | Centre | Shows | Group edges |
|---|---|---|---|---|---|---|
| 1 | Inès | `520:15871` | (260, 148) | (272, 160) | photo | Classiques, Polar |
| 2 | Léa | `520:15874` | (4, 361) | (16, 373) | photo | Poésie |
| 3 | Rémi | `520:15877` | (4, 391) | (16, 403) | photo | Poésie |
| 4 | Camille | `520:15880` | (180, 23) | (192, 35) | photo | Club |
| 5 | Hugo | `520:15883` | (231, 62) | (243, 74) | photo | Club |
| 6 | Sami | `520:15886` | (82, 486) | (94, 498) | photo | L11 |
| 7 | Nora | `520:15889` | (34, 417) | (46, 429) | photo | Poésie |
| 8 | Paul | `520:15892` | (365, 401) | (377, 413) | photo | Polar |
| 9 | Julie | `520:15895` | (190, 52) | (202, 64) | photo | Club |
| 10 | Marc | `520:15898` | (293, 116) | (305, 128) | photo | BD |
| 11 | Aïcha | `520:15901` | (79, 546) | (91, 558) | photo | L11 |
| 12 | Tom | `520:15904` | (315, 150) | (327, 162) | photo | BD |
| 13 | Zoé | `520:15907` | (53, 530) | (65, 542) | photo | L11 |
| 14 | Yann | `520:15910` | (105, 568) | (117, 580) | photo | L11 |
| 15 | Lina | `520:15913` | (63, 142) | (75, 154) | photo | Classiques |
| 16 | Omar | `520:15916` | (365, 353) | (377, 365) | photo | Polar |
| 17 | Élise | `520:15919` | (146, 55) | (158, 67) | photo | Club |
| 18 | Bruno | `520:15922` | (133, 151) | (145, 163) | photo | Club, Classiques |
| 19 | Chloé | `520:15925` | (55, 564) | (67, 576) | « CH » | L11 |
| 20 | Karim | `520:15928` | (48, 181) | (60, 193) | photo | Classiques |
| 21 | Manon | `520:15931` | (307, 442) | (319, 454) | photo | BD, L11 |
| 22 | Lucas | `520:15934` | (233, 161) | (245, 173) | « LU » | Polar, Classiques |
| 23 | **Sarah** | `520:15937` | (330, 101) | (342, 113) | « SA » | **none** |
| 24 | Théo | `520:15940` | (134, 558) | (146, 570) | photo | L11 |
| 25 | Emma | `520:15943` | (108, 538) | (120, 550) | photo | L11 |
| 26 | **Nathan** | `520:15946` | (359, 156) | (371, 168) | « NA » | **none** |
| 27 | Jade | `520:15949` | (4, 421) | (16, 433) | « JA » | Poésie |
| 28 | Louis | `520:15952` | (346, 193) | (358, 205) | photo | BD |
| 29 | Alice | `520:15955` | (347, 377) | (359, 389) | photo | Polar |
| 30 | Adam | `520:15958` | (80, 516) | (92, 528) | « AD » | L11 |
| 31 | Rose | `520:15961` | (136, 528) | (148, 540) | photo | SF, Poésie |
| 32 | Jules | `520:15964` | (266, 573) | (278, 585) | photo | SF |
| 33 | Anna | `520:15967` | (277, 445) | (289, 457) | photo | Polar, SF |
| 34 | Noé | `520:15970` | (217, 35) | (229, 47) | « NO » | Club |
| 35 | **Mila** | `520:15973` | (207, 7) | (219, 19) | « MI » | **none** |
| 36 | Victor | `520:15976` | (143, 85) | (155, 97) | photo | Club |
| 37 | Eva | `520:15979` | (33, 206) | (45, 218) | « EV » | Classiques |
| 38 | Hélène | `520:15982` | (67, 434) | (79, 446) | photo | SF, Classiques |
| 39 | Samir | `520:15985` | (99, 143) | (111, 155) | photo | BD, Poésie |
| 40 | **Clara** | `520:15988` | (140, 588) | (152, 600) | photo | **none** |
| 41 | Arthur | `520:15991` | (173, 82) | (185, 94) | photo | Club |
| 42 | Maya | `520:15994` | (221, 106) | (233, 118) | « MA » | BD, Classiques |

Ten friends use the initials fallback: Chloé, Lucas, Sarah, Nathan, Jade, Adam, Noé, Mila, Eva and Maya.
Noé keeps the component's default text « NO », which happens to be right.

**Friends attached to nobody but « Vous »: Sarah, Nathan, Mila, Clara.** These four have no edge at all,
because the you ↔ friend edges are hidden at this zoom. They float at the edge of the network: Sarah and
Nathan top right, Mila at the very top, Clara at the very bottom. The spec leaves open whether to show them:
« 2. Montrer les amis sans groupe commun (R3 : Sarah, Nathan, Mila, Clara, rattachés à vous seul). »

**Friend placement intent.** Single-group friends fan out on the side of their group **away from « Vous »**,
about 60–120 pt from the tile centre. For example, Club's friends sit 62–120 pt above it, and Lecteurs du
11e's friends sit below-left of it. Friends in two groups sit somewhere between or around them (Bruno,
Samir, Maya, Lucas). Some of those placements make long crossing edges, for instance Manon to BD and L11,
and Inès to Classiques and Polar, so the mock is illustrative and not the output of a real layout pass.

**Fit to content.** All nodes fit inside x 4–389 and y 7–612 of the 393 × 682 graph area, which leaves a
4-pt margin left, right and top. The bottom ~70 pt (graph y 612–682) is left free for the counter pill
(graph y 636–666) and the lower part of the zoom controls (graph y 530–666, x 331–377). No node sits under
an overlay.

## Edges

The `edges` frame (`520:15870`) sits at graph (16, 35.30) and measures 361 × 549.75. It holds 54 straight
`VECTOR` lines, from centre to centre, with butt caps. All stroke colours are `#558154`, which is
`foreground/tinted` (`.foregroundTinted`), flattened to a literal in the export.

| Kind | Count | Stroke | Width | Layer opacity | Dash |
|---|---|---|---|---|---|
| you ↔ group (member or admin) | 6 | `foreground/tinted` `#558154` | **2** | **80 %** | solid |
| you ↔ group (**invitation**, « Lecteurs du 11e ») | 1 (`520:15820`) | `foreground/tinted` | **2** | **80 %** | **3 on / 3 off** |
| friend ↔ group | 47 | `foreground/tinted` | **1** | **30 %** | solid |
| you ↔ friend | **0** | not drawn at this zoom | — | — | — |

The you ↔ group edges are `520:15816`–`520:15822`: Club, BD, Polar, SF, L11 (dashed), Poésie, Classiques.
Friend ↔ group edges per group (47 in total):

- **Club de Belleville** (8): Camille, Julie, Hugo, Élise, Victor, Arthur, Noé, Bruno
- **BD & romans graphiques** (6): Marc, Tom, Louis, Manon, Samir, Maya
- **Polar & noir** (6): Inès, Paul, Omar, Lucas, Alice, Anna
- **SF & imaginaires** (4): Rose, Jules, Anna, Hélène
- **Lecteurs du 11e** (9): Sami, Aïcha, Zoé, Yann, Chloé, Adam, Théo, Emma, Manon
- **Poésie du dimanche** (6): Léa, Rémi, Nora, Jade, Rose, Samir
- **Classiques en VO** (8): Inès, Lina, Bruno, Karim, Lucas, Eva, Hélène, Maya

Nine friends have two group edges (Inès, Bruno, Manon, Lucas, Rose, Anna, Hélène, Samir, Maya), 29 have one,
and 4 have none. « Lecteurs du 11e » is a group you are **invited to** (dashed edge, and it appears as
`invitation/Lecteurs du 11e` in R6), yet it still shows nine friend ↔ group edges: the friends who are
already members.

None of the stroke widths (1, 2), opacities (30 %, 80 %) or the 3/3 dash has a Swift token. The `Opacity`
collection only holds `opacity/surface/plank` 92 and `opacity/surface/backdrop` 20. The spec says
« Aucun token nouveau », so these stay literals.

## Visual states shown

- **Semantic zoom = overview (dézoomé).** All nodes are compact, and there are no names on friends.
- **Nothing selected.** No node is highlighted and nothing is dimmed; that state is R2.
- **Photo vs fallback.** Friend dots show both: 32 with a photo and 10 with initials on `background/tinted`.
  Groups also show both: 5 with a picture and 2 with the `person.2` glyph on `background/tinted`
  (« Lecteurs du 11e », « Classiques en VO »).
- **Invitation received.** The dashed you ↔ group edge to « Lecteurs du 11e ». The tile itself is not
  styled differently.
- **Segmented control.** « Tout » selected. **Tab bar**: « Réseau » active.
- **Minimap absent.** It only appears when zoomed in (R4).

## Interactions the design implies

| Gesture / control | Effect (from the spec and the screen) |
|---|---|
| Pinch | Zoom the graph; pinching is the primary gesture (« Pincer et glisser, toujours »). Crossing the semantic-zoom threshold swaps compact nodes (R3) for full nodes (R4) and back. |
| Drag (pan) | Move the graph. |
| Zoom controls « + » | One zoom step in. For people who do not pinch. |
| Zoom controls « − » | One zoom step out. |
| Zoom controls « recentrer » | Re-centre on « Vous ». |
| Tap a node (dot or tile) | R2 behaviour: « Ses arêtes s'allument, le reste passe à 30 %, une feuille résume — nom, rôle, membres, avatars des amis en commun — et ouvre la fiche. » For a friend the sheet action is « Voir le profil ». |
| Tap empty space | Closes the sheet (« Toucher le vide referme »). |
| Segmented control | « Tout » shows the graph. « Amis » and « Groupes » show the R5 and R6 lists (feature 0028). |
| « + » in the nav | **Undecided** (spec, À trancher #4): add a friend, create a group, or a menu with both. |
| Counter pill | Informational only; nothing suggests it is tappable. |
| Opening the tab | « Le graphe s'ouvre cadré sur tout le réseau. » Overview mode is proposed above 20 nodes (« Seuil proposé : vue d'ensemble au-delà de 20 nœuds »); this screen has 50 nodes (42 + 7 + you). |

## What changes compared with the sibling screens

| | R1 · Constellation (`512:15513`) | R2 · Groupe touché (`512:15657`) | **R3 · Dézoomé** | R4 · Zoomé (`522:15982`) |
|---|---|---|---|---|
| Network size | 8 friends, 3 groups | same as R1 | **42 friends, 7 groups** | same network as R3 |
| Friend node | `Graph / Friend` (44-pt avatar + name) | same | **`Graph / Friend · Dot`, 24 pt, no name** | `Graph / Friend` |
| Group node | `Graph / Group` pill (tile + name + detail) | same | **`Graph / Group · Compact`, 52-pt tile + name** | `Graph / Group` pill |
| « Vous » | 100 % (72 × 84) | 100 % | **70 %** | off-screen |
| you ↔ group edge | `foreground/tinted`, 1.5, 60 % | same | **2, 80 %** | 2, 100 % |
| invitation edge | dashed **4/4**, 1.5, 100 % | same | dashed **3/3**, 2, 80 % | none visible |
| friend ↔ group edge | `foreground/tinted`, 1.5, 60 % | lit / dimmed | **1, 30 %** | 1.5, 60 % |
| you ↔ friend edge | black at 10 % (`border/default`), 1, 100 % | same | **hidden** | `border/default`, 1.5, layer 50 % |
| Zoom controls / counter | absent | absent | **present** | present |
| Minimap | absent | absent | absent | **present** |
| Sheet | — | « sheet · groupe » | — | — |

R5 (`522:16586`) and R6 (`522:16671`) are the « Amis » and « Groupes » lists, on `background/secondary`.

## Token map used on this screen

| Figma | Value | Swift |
|---|---|---|
| `background/default` | `#FFFFFF` | `DesignSystem.Color.backgroundDefault` |
| `background/tinted` | `#F2FAE9` | `.backgroundTinted` |
| `background/tinted-inverse` | `#3A5A40` | `.backgroundTintedInverse` |
| `background/disable` | `#E8ECE6` | `.backgroundDisable` |
| `foreground/default` | `#191919` | `.foregroundDefault` |
| `foreground/secondary` | `#000000` at 50 % | `.foregroundSecondary` |
| `foreground/tinted` | `#558154` | `.foregroundTinted` |
| `foreground/inverse` | `#F1F1F1` | `.foregroundInverse` |
| `border/default` | `#000000` at 10 % | `.borderDefault` |
| `shadow/light` / `Shadow/Light` | `#000000` at 18 %, (0, 2), blur 3 | `DesignSystem.Shadow.light` → `.shadow(.light)` |
| `Title/title200` | Open Sans ExtraBold 32 | `DesignSystem.TextStyle.title200` |
| `Action/action200` | Open Sans SemiBold 12 | `.action200` |
| `Footnote/footnote200Bold` | Alegreya Bold 12 | `.footnote200Bold` |
| `spacing/xx-small` / `small` / `medium` | 2 / 8 / 16 | `DesignSystem.Spacing.xxSmall` / `.small` / `.medium` |
| `radius/full` | 360 | `DesignSystem.CornerRadius.full` |

**Values with no Swift token** (all literals in Figma too, since the spec says « Aucun token nouveau »):

- friend-dot initials at 9 pt (Open Sans Regular);
- compact tile radius 14 and zoom-controls radius 22 (22 is a capsule, so use `Capsule()`);
- compact tile border 2, Me ring 3, edge widths 1 and 2, dash 3/3;
- the edge opacities 30 % and 80 %;
- the Me label padding 10 / 3 and its overlap of −10;
- the counter's vertical padding 6;
- the zoom-out bar 14 × 2 with radius 1, and the separators 28 × 1;
- the 70 % scale of « Vous »;
- the tab-bar and status-bar literals, which are system chrome.

Two values are unbound literals that equal existing tokens: the counter's horizontal padding 12 is
`.sMedium`, and the gap 4 in the compact tile is `.xSmall`.

## Not drawn / ambiguous

1. **Zoom-controls separators are flush left** (x 332–359), because the stack aligns to `start`. They are
   probably meant to be centred, with an 8-pt inset either side.
2. **The segmented control overflows its frame.** The 40-pt frame with 8-pt vertical padding leaves 24 pt,
   but the track renders at about 36 pt. The real height of the control is ambiguous. Also, the existing app
   uses a native two-case `.segmented` `Picker`; the design needs a third segment, « Tout », as the default,
   with token colours.
3. **Edge styling is not consistent across R1, R3 and R4.** The spec text says friend ↔ group is 60 % and
   you ↔ friend is `border/default`. R3 uses 30 %/1 pt and 80 %/2 pt; R1 uses a 4/4 dash and R3 a 3/3 dash.
   The design does not say whether the widths and opacities should vary continuously with zoom or snap per
   mode.
4. **Friends with no common group** (Sarah, Nathan, Mila, Clara) float with no edge. Whether to show them is
   open (À trancher #2), and if shown, where the layout should put them.
5. **Touch targets.** The 24-pt dots are well under the 44-pt minimum. The design does not say how a dot is
   tapped in overview mode: a larger hit area, or zooming first.
6. **The compact tile loses the role.** Admin, member and invited groups are drawn the same; only the dashed
   edge marks an invitation. No sent requests are drawn (À trancher #3).
7. **The threshold** between overview and zoomed is « 20 nœuds ? » (À trancher #1). The design does not say
   whether it counts nodes or uses a zoom scale, or how the switch animates.
8. **Fit-to-content padding.** The mock uses a 4-pt side margin and keeps the bottom ~70 pt clear for
   overlays. The design does not say whether the fit should reserve space for the overlays or let nodes pass
   under them.
9. **Group label collisions.** Long names (« BD & romans graphiques », 126 pt wide) are not truncated. The
   design does not show what happens when labels overlap each other or dots.
10. **Not drawn** (À trancher #5): dark mode, the empty state, loading, and VoiceOver. The proposed
    VoiceOver reading: « Tout lu comme la liste des groupes, chacun suivi de ses amis ».
11. **Dynamic Type.** Figma sizes are unscaled. With `footnote200Bold` scaled up, the tile labels will widen
    and the layout should take that into account; the design does not cover it.
12. **Mock imagery.** All avatars and group pictures are illustrations (frames `assets · avatars` `519:16039`
    and `assets · images de groupe` `519:16210`). The real data is the inventaire.io user `picture` and group
    `picture`. Nothing here is a shipped asset.
