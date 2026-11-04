# Réseau · Graphe — assets

Every icon, image and glyph the `Réseau · Graphe` screens (`512:15486`, file `S7IvC6GvlcUFe5IgbtvQq6`) need, and
where each one comes from. Documentation only; read on 2026-10-13.

**Short version: nothing to export.** Every glyph is an SF Symbol (or a shape simple enough to draw), and every
picture is user data served by inventaire.io. The two `assets · …` frames are mock-up illustrations, not assets.

Why Figma shows vectors instead of symbols: the file's `Icon` component set (`21:60`) is a set of hand-drawn
stand-ins — « SF Symbols cannot be redistributed into a Figma file, so these are hand-drawn approximations at the
same 24pt optical size — geometry is close, not identical. » Implement each with the named SF Symbol, never by
exporting the Figma vector.

---

## 1. Glyphs — SF Symbols

| What | Figma node(s) | Figma source | SF Symbol | Size / colour in Figma | Already in the code |
|---|---|---|---|---|---|
| Group without a picture (graph) | `512:16019`, `512:16030`, `512:16041`, `512:16052` in `Graph / Group`; `519:16403` in `Graph / Group · Compact` | `Icon / Glyph=person.2` (`498:378`) | `person.2` | 24 pt box, strokes 1.8 pt round caps, `foreground/default` (`#191919`) on a `background/tinted` (or `background/default` for Admin) tile | yes — tab icon (`MainTabView.swift:49`), `EmptyStateView(glyph: "person.2")` in `GroupsSegmentView`, `GroupHeaderView` |
| Zoom in | `521:15971` in `Graph / Zoom Controls` | `Icon / Glyph=plus` (`21:22`) | `plus` | 24 pt box, 14 × 14 cross, stroke 1.8, `foreground/default` | yes (`NetworkView` toolbar) |
| Zoom out | `521:15976` | a drawn rectangle 14 × 2, radius 1, `foreground/default` — not an `Icon` | `minus` | — | no |
| Recentrer sur « Vous » | `521:15978` (ring `521:15979` 16 × 16 stroke 2 inside, dot `521:15980` 6 × 6) | drawn shapes, not an `Icon` | closest shape: `smallcircle.filled.circle`. Semantic alternatives: `scope`, `location` (open point) | `foreground/default` | no |
| Navigation bar « + » | `I512:15535;26:116` (R1) and every `nav` instance | `Chrome / Nav Bar` property `Action glyph` = `21:22` (`plus`) | `plus` | 24 pt, top-right | yes — `Button("network.add_friends", systemImage: "plus")` / `Button("groups.create", systemImage: "plus")` in `NetworkView.swift`; on « Tout » its target is undecided (spec, « À trancher » 4) |
| « Demande envoyée » tag | `498:14362` in `Cell / Group / State=Sent` | `Icon / Glyph=clock` (`21:59`) | `clock` | 16 pt (`sizing/icon/tag`), `foreground/secondary` | yes — `GroupRoleTag.swift` |
| « Admin » tag | `I522:16680;498:14351` | `Tag` with `Show glyph` **off** (the default glyph would be `checkmark.circle` `21:55`) | none in Figma | — | the code shows `checkmark.seal` (`GroupRoleTag.swift`) — divergence |
| « Rejoindre » pill (not on these screens) | `498:14376` in `Cell / Group / State=Join` | `Icon / Glyph=plus` | `plus` | 20 pt per the `Action / Pill` description | — |
| Section header action (hidden here) | `206:253` in `Section Header` | `Icon / Glyph=plus`, 12 × 12 | `plus` | `foreground/tinted` | yes — `ShelfSectionHeader.swift` |
| Tab bar | `498:14240`, `498:14246`, `498:14258`, `498:14269` in `Chrome / Tab Bar · Réseau` (`498:14224`) | drawn approximations | `book`, `list.clipboard`, `person.2`, `person` | 26 pt glyph boxes; active tab `foreground/tinted`, others system grey | yes — `MainTabView.TabConfig.systemIcon` |

## 2. Drawn shapes — not assets

Draw these in SwiftUI (`Shape` / `Path` / `Canvas`); there is nothing to export.

| What | Node(s) | Spec |
|---|---|---|
| Edges | `513:15827` (R1), `514:16003` (R2), `520:15870` (R3), `522:16237` (R4), `522:16098` (minimap) | straight lines; stroke, width, dash and opacity per kind in `components.md` § 9.4. The spec: « Arêtes calculées localement » |
| Avatar rings | inside `Graph / Me`, `Graph / Friend`, `Graph / Friend · Dot`, `Graph / Group · Compact`, sheet avatars | strokes on circles / rounded squares — see `components.md` |
| Zoom-controls separators | `521:15974`, `521:15977` | 28 × 1, `border/default` |
| Sheet grabber | `514:16114` | 36 × 5, radius 3, `border/default`. A system sheet would use `.presentationDragIndicator(.visible)` instead (open point: the sheet's shape) |
| Minimap viewport | `522:16303` | radius 3, `foreground/tinted` fill 12 %, stroke 1.5 inside |

## 3. Dynamic images — user data

No image in these screens ships with the app. All of them are pictures inventaire.io serves for a user or a
group. Every image fill in the file uses scale mode **FILL** (aspect-fill, centre crop).

### 3.1 User avatar

- **Source**: `User.avatarURLValue: String?` (`ReCIT_iOS/Model/UserData/User.swift:23`), built in
  `User.swift:136` as `"\(baseUrl)\(userDTO.picture)"` when the DTO has a `picture`, else `nil`.
- **Loader**: `CachedAsyncImage` (Nuke) — `ReCIT_iOS/Features/Components/CachedAsyncImage.swift`.

| Slot | Where | Size / shape | Border | Fallback |
|---|---|---|---|---|
| « Vous » | `Graph / Me` `519:16278` | 72 circle (50.4 at 70 % in R3) | 3 pt inside ring `background/tinted-inverse` | **not designed** — no initials, no `Show photo` property |
| Friend node | `Graph / Friend` `519:16259` / `519:16260` | 44 circle | 1 pt inside `border/default` (Default), 2 pt inside `foreground/tinted` (Highlighted) | initials (first two letters, uppercased, accents kept), `Action/action300` 17, `foreground/tinted`, on `background/default` / `background/tinted` |
| Friend dot | `Graph / Friend · Dot` `519:16392` | 24 circle | 1 pt inside `border/default` | initials, Open Sans Regular 9, `foreground/tinted`, on `background/tinted` |
| Minimap friend | `522:16153` … `522:16194` | ~5.86 circle (the dot, scaled) | as the dot | as the dot — at that size the image is decorative |
| Common friends in the group sheet | `522:16838` – `522:16841` | 32 circle, overlap −8 | 2 pt **outside** `background/default` | not designed |
| Friend row (R5) | `I522:16597;30:180` etc. — `Thumbnail / Size=Medium, Shape=Round` | 48 circle, `Shadow/Thumbnail` | none | `background/disable` circle (what `CellThumbnail` draws) |
| Invitation row (R5) | `I522:16591;405:375` | 48 circle | none | `background/disable` circle |

### 3.2 Group picture

- **Source**: `ReaderGroup.pictureURL: String?` (`ReCIT_iOS/Model/Groups/ReaderGroup.swift:27`), made absolute with
  `apiService.absoluteImageUrl(dto.picture)` (`ReCIT_iOS/AppModels/Group/GroupModel.swift:313`); search results:
  `GroupSearchResult.pictureURL` (`GroupModel.swift:176`). The spec: « picture des users et des groupes déjà dans
  les DTO ».

| Slot | Where | Size / shape | Border | Fallback |
|---|---|---|---|---|
| Group node | `Graph / Group` `519:16274` – `519:16277` | 32 square, radius 8 (clipped by the tile) | the node's own border, not the tile's | `person.2` glyph on the tile |
| Compact group | `Graph / Group · Compact` `519:16409` | 52 square, radius 14 | 2 pt inside `background/tinted-inverse`, drawn over the picture | `person.2` glyph on `background/tinted` |
| Minimap group | `522:16195` – `522:16201` | compact tile scaled to ~17.7 high | as compact | as compact |
| Group row (R6) | `I522:16680;498:14347`, `I522:16682;498:14342` — `Thumbnail / Size=Medium, Shape=Medium` | 48 square, radius 8, `Shadow/Thumbnail` | none | `background/disable` square, **no glyph** (Immeuble Ramponeau) |
| Group invitation row (R6) | `498:14386` in `522:16676` | 48 square, radius 8 | none | `background/disable` square (Lecteurs du 11e) |

The same group without a picture is a `person.2` tile in the graph and an empty grey square in the list (open
point; the spec says the lists stay « inchangées sauf photos »).

Mock data that exercises the fallbacks: friends without a photo — Nora, Paul (R1/R2), Chloé, Lucas, Sarah, Nathan,
Jade, Adam, Noé, Mila, Eva, Maya (R3), Jade (R4); groups without a picture — Lecteurs du 11e (R1, R2, R3, R6),
Classiques en VO (R3), Immeuble Ramponeau (R6).

## 4. Mock-up-only illustrations — do not ship

The spec: « Avatars et images de groupe : illustrations de maquette générées pour ce fichier, sous les écrans. »
They are the image fills the screens reuse (the R1 photo of Inès, `I513:15863;519:16259`, carries the same image
hash as `avatar/Inès` `519:16047`). They stand in for inventaire.io data: **do not export them, do not add them to
`Assets.xcassets`, do not use them as placeholders.**

Reference screenshots only: `screenshots/assets-avatars.png`, `screenshots/assets-group-images.png`.

### 4.1 `assets · avatars` — `519:16039`

1068 × 48 frame, 18 ellipses, each 48 × 48, image fill (FILL), no stroke.

| Node | Name | Node | Name |
|---|---|---|---|
| `519:16047` | `avatar/Inès` | `519:16143` | `avatar/Zoé` |
| `519:16055` | `avatar/Léa` | `519:16154` | `avatar/Yann` |
| `519:16066` | `avatar/Rémi` | `519:16162` | `avatar/Lina` |
| `519:16080` | `avatar/Camille` | `519:16173` | `avatar/Omar` |
| `519:16087` | `avatar/Hugo` | `519:16181` | `avatar/Élise` |
| `519:16094` | `avatar/Sami` | `519:16188` | `avatar/Bruno` |
| `519:16106` | `avatar/Julie` | `519:16202` | `avatar/Chloé` |
| `519:16113` | `avatar/Marc` | `519:16209` | `avatar/Karim` |
| `519:16121` | `avatar/Aïcha` | | |
| `519:16135` | `avatar/Tom` | | |

The R3 overview shows 42 friends; those beyond these 18 that have a photo reuse these illustrations.

### 4.2 `assets · images de groupe` — `519:16210`

288 × 48 frame, five rounded rectangles, each 48 × 48, **radius 10**, image fill (FILL), no stroke. (Radius 10 is
the mock-up's own; every slot that shows them uses its own radius — 8 or 14 — see 3.2.)

| Node | Name |
|---|---|
| `519:16220` | `group-image/Club de Belleville` |
| `519:16230` | `group-image/BD & romans graphiques` |
| `519:16241` | `group-image/Polar & noir` |
| `519:16251` | `group-image/SF & imaginaires` |
| `519:16258` | `group-image/Poésie du dimanche` |

## 5. System chrome — not assets

`Chrome / Status Bar` (`24:30`), `Chrome / Home Indicator` (`24:35`), `Chrome / Nav Bar` (`26:162`) and
`Chrome / Tab Bar · Réseau` (`498:14327`) are drawings of iOS chrome. The system draws them; their glyphs are
covered in § 1.
