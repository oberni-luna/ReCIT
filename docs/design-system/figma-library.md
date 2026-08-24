# Bibliothèque Figma — design system RECITs

Miroir Figma du design system iOS. **Le code Swift est la source de vérité** ; Figma en est le reflet.

- **fileKey** : `S7IvC6GvlcUFe5IgbtvQq6`
- **Lien** : https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits
- **Dernière passe** : 2026-08-20 (issue 0036) — les cinq états jamais dessinés de la surface de tri : 9 frames dans
  `Ranger mes livres`, 2 variantes d'`Icon` (`circle`, `exclamationmark.circle`), la propriété `Mark glyph#133:0` sur
  `AutoSort / Shelf Header`.
- **Passes précédentes** : 2026-08-20 — onboarding, « Ranger mes livres · Résultat », puis le tri manuel.
  2026-08-19 — le label papier de l'étagère (issue 0012) : style d'effet `Shadow/Light`, variables `shadow/light`,
  `shelf/label/paper`, `shelf/label/ink`, appliquées aux deux variantes de `Shelf Card`.
  2026-08-18 — tokens, styles de texte, styles d'ombre, page `Tokens`, puis les 26 composants et les 16 frames
  d'écran.
- **Éditeur** : fichier `/design/` (les nœuds de design sont autorisés).

## Règle de source de vérité

Toute divergence code ↔ Figma se tranche **en faveur du code**, et se **documente** — dans la description du token
concerné, et dans la table [Divergences](#divergences-relevées-dans-le-code) ci-dessous. On ne corrige jamais le code
en douce depuis Figma.

Corollaire : les valeurs « bizarres » de ce fichier sont volontaires. Avant de « réparer » un token, lire sa
description : elle dit pourquoi.

## Conventions du fichier

| Convention | Détail |
|---|---|
| Nommage des couleurs primitives | Le **chemin exact de l'asset catalog** : `color/gray/900`, y compris les noms à espace et `%` (`color/gray/700 75%`). Greppable depuis le Swift. |
| Nommage des sémantiques | `famille/rôle` : `foreground/default`, `background/tinted-inverse`, `border/error`. |
| Portées | **Explicites partout**, jamais `ALL_SCOPES`. Primitives = `[]` (invisibles dans les pickers). |
| Code syntax | **iOS uniquement**, et c'est le **vrai symbole Swift** (`DesignSystem.Color.foregroundDefault`). Pas de WEB ni d'ANDROID : il n'y a pas de codebase web ni Android dans ce dépôt. |
| Alias | Les sémantiques sont des **alias** vers les primitives. Jamais de valeur recopiée. |
| Alpha | Un token qui porte une alpha (`shadow/*`, `clear`) **ne peut pas** être un alias : valeur brute par mode. |
| Opacités | **Stockées en pourcentage** (`92`, pas `0.92`). Figma lit une variable bindée à `opacity` comme un %. Stocker `0.92` donnerait 0,92 % — invisible, et le bug ne se voit qu'à la capture. |
| Ombres | Couleur **bindée** à une variable mode-aware, jamais littérale. |
| Modes épinglés | Les planches de couleurs et d'ombres épinglent leur mode via `setExplicitVariableModeForCollection`, pour que clair et sombre se lisent côte à côte. |
| Chrome de documentation | Les libellés des planches sont en **Inter** avec un fill littéral, pour ne pas se confondre avec les spécimens de l'app. Ce sont les seuls fills non bindés du fichier, et ils sont hors composant, donc invisibles pour l'audit. |

### Polices — pas de substitution

Contrairement au cas courant, **les deux familles réelles se résolvent dans Figma** : `Alegreya`
(Regular / Medium / Bold) et `Open Sans` (Regular / SemiBold / ExtraBold). Sondées avant construction :
`hasMissingFont === false` et `width > 0` pour chacune. Aucun substitut (Inter, Nunito, Lora) n'a été nécessaire.

La famille est malgré tout **pilotée par une variable** (`font/family/serif`, `font/family/sans`) : un changement de
famille reste une seule édition.

Attention à `Open Sans` : Figma accepte **`SemiBold`** *et* `Semi Bold`, `ExtraBold` *et* `Extra Bold`. Le fichier
utilise la forme sans espace, pour coller aux noms de fichiers `.ttf` du dépôt.

## Carte des pages

| Page | id |
|---|---|
| `Tokens` | `0:1` |

### Sections de `Tokens`

| Section | id | Planches (id) |
|---|---|---|
| `1 · Couleurs` | `10:2` | `Sémantiques — Clair` `11:2` · `Sémantiques — Sombre` `11:141` · `Primitives` `12:2` |
| `2 · Typographie` | `10:3` | `Échelle typographique` `13:2` |
| `3 · Espacements` | `10:4` | `Échelle d'espacement` `14:2` |
| `4 · Rayons` | `10:5` | `Rayons de coin` `15:2` |
| `5 · Ombres` | `10:6` | `Ombres — Clair` `16:2` · `Ombres — Sombre` `16:36` |
| `6 · Opacités` | `10:7` | `Opacités` `17:2` |

Les sections sont empilées verticalement, sans chevauchement, chacune ajustée à ses planches (marge 48, gap 160).
**Les coordonnées d'un enfant de `SECTION` sont relatives à la section** — un `enfant.y = section.y + marge` sort du
cadre sans qu'aucun contrôle ne le voie.

## Collections de variables

| Collection | id | Modes (id) | Variables |
|---|---|---|---|
| `Primitives` | `VariableCollectionId:4:2` | `Value` (`4:0`) | 30 |
| `Color` | `VariableCollectionId:4:3` | `Light` (`4:1`), `Dark` (`4:2`) | 30 |
| `Spacing` | `VariableCollectionId:4:4` | `Value` (`4:3`) | 11 |
| `Radius` | `VariableCollectionId:4:5` | `Value` (`4:4`) | 8 |
| `Sizing` | `VariableCollectionId:4:6` | `Value` (`4:5`) | 4 |
| `Typography` | `VariableCollectionId:4:7` | `Value` (`4:6`) | 10 |
| `Opacity` | `VariableCollectionId:4:8` | `Value` (`4:7`) | 2 |

**Total : 95 variables, 10 styles de texte, 7 styles d'effet.**

Les trois dernières variables (`shadow/light`, `shelf/label/paper`, `shelf/label/ink`) et le septième style d'effet
(`Shadow/Light`) datent de la passe du 2026-08-19 ; les résultats d'audit datés du 2026-08-18 plus bas comptent donc
92 et 6, et n'ont pas été rejoués.

Les modes clair/sombre ne vivent **pas** dans l'asset catalog : chaque `.colorset` porte une seule valeur, et la
paire light/dark est assemblée en Swift par `Color(light:dark:)` dans `DesignSystem/Tokens/Color.swift`. C'est là
qu'il faut lire les deux modes.

## Tables de tokens

### Primitives — `color/*` (source : `Assets.xcassets/color/`)

| Token | Hex | α | Consommé par |
|---|---|---|---|
| `color/gray/0` | `#FFFFFF` | 1 | `background/default` L · `shelf/label/paper` **L et D** |
| `color/gray/50` | `#F1F1F1` | 1 | `foreground/inverse` L · `foreground/default` D · `background/secondary` L |
| `color/gray/200` | `#E8ECE6` | 1 | `background/inverse` D · `background/disable` L · `background/tinted-inverse` D — **plus `border/default`, voir D49** |
| `color/gray/400` | `#AFAFAF` | 1 | `foreground/disable` L · `foreground/secondary` D · `foreground/placeholder` L |
| `color/gray/500` | `#959A92` | 1 | — inutilisé |
| `color/gray/600` | `#7E837C` | 1 | `foreground/secondary` L · `foreground/disable` D · `background/disable` D |
| `color/gray/700` | `#2D2D2D` | 1 | `background/error` D — **plus `border/default`, voir D49** |
| `color/gray/700 75%` | `#2D2D2D` | **0.50** | — inutilisé · **le nom ment** (voir D1) |
| `color/gray/800` | `#2A2A2A` | 1 | `background/secondary` D |
| `color/gray/900` | `#191919` | 1 | `foreground/default` L · `foreground/inverse` D · `background/inverse` L · `shelf/label/ink` **L et D** |
| `color/gray/1000` | `#000000` | 1 | `background/default` D |
| `color/gray/1000 10%` | `#000000` | 0.10 | — inutilisé |
| `color/green/100` | `#F2FAE9` | 1 | `foreground/tinted-inverse` L · `background/tinted` L |
| `color/green/200` | `#E7FFCE` | 1 | `foreground/tinted` D · `border/tinted` D · `background/tinted-inverse` D |
| `color/green/300` | `#D8FFB1` | 1 | — inutilisé |
| `color/green/400` | `#B6DA9F` | 1 | — inutilisé |
| `color/green/500` | `#90CF8E` | 1 | — inutilisé |
| `color/green/600` | `#579F66` | 1 | — inutilisé |
| `color/green/700` | `#558154` | 1 | `foreground/tinted` L · `border/tinted` L — le vert de marque |
| `color/green/800` | `#3A5A40` | 1 | `background/tinted-inverse` L — le fond du bouton primaire |
| `color/green/900` | `#344E41` | 1 | `foreground/tinted-inverse` D · `background/tinted` D |
| `color/red/100` | `#F1E4DB` | 1 | `background/error` L |
| `color/red/400` | `#E14D4D` | 1 | `foreground/error` D · `border/error` D |
| `color/red/800` | `#821F1F` | 1 | `foreground/error` L · `border/error` L |
| `color/yellow/300` | `#FDF1A8` | 1 | — inutilisé |
| `color/yellow/400` | `#F5D36E` | 1 | — inutilisé |

`color/gray/200` est **légèrement vert**, pas neutre — c'est volontaire, il porte la teinte de marque dans les gris.
`color/red/100` est le seul `.colorset` stocké en composantes hexadécimales et non en flottants.

### Primitives — `shelf/*` (source : `Features/Shelves/ShelfPalette.swift`)

Teintes **hors thème** : elles dépeignent un objet physique (papier, encre), pas du chrome d'interface. Même valeur
en clair et en sombre, **volontairement**.

| Token | Hex | Symbole Swift |
|---|---|---|
| `shelf/parchment` | `#E4DAC4` | `ShelfPalette.parchment` |
| `shelf/ink-dark` | `#3A2E24` | `ShelfPalette.ink(onHex:)` — luminance > 0.58 |
| `shelf/ink-cream` | `#F4EEE1` | `ShelfPalette.ink(onHex:)` — luminance ≤ 0.58 |
| `shelf/ink-fallback` | `#4A3B2C` | `ShelfPalette.ink(onHex:)` — aucun hex de couverture |

`ShelfPalette` porte aussi le papier et l'encre du label (`labelPaper`, `labelInk`) : eux ne sont pas des primitives —
ils aliasent des gris existants — et vivent donc dans la table des sémantiques, plus bas.

La couleur du dos peint elle-même n'est **pas** un token : `ShelfPalette.spineColor(_:)` la calcule depuis l'hex
persisté de la couverture (saturation ×1.45 plafonnée à 0.92, luminosité bornée à [0.42, 0.82]). Elle n'a pas de
valeur fixe, donc pas de variable.

### Sémantiques — `Color` (source : `DesignSystem/Tokens/Color.swift`)

| Token | Light | Dark | Symbole Swift |
|---|---|---|---|
| `foreground/default` | `gray/900` | `gray/50` | `DesignSystem.Color.foregroundDefault` |
| `foreground/inverse` | `gray/50` | `gray/900` | `.foregroundInverse` |
| `foreground/disable` | `gray/400` | `gray/600` | `.foregroundDisable` |
| `foreground/secondary` | `gray/600` | `gray/400` | `.foregroundSecondary` |
| `foreground/tinted` | `green/700` | `green/200` | `.foregroundTinted` |
| `foreground/tinted-inverse` | `green/100` | `green/900` | `.foregroundTintedInverse` |
| `foreground/error` | `red/800` | `red/400` | `.foregroundError` |
| `foreground/placeholder` | `gray/400` | `gray/600` | `.foregroundPlaceholder` |
| `background/default` | `gray/0` | `gray/1000` | `.backgroundDefault` |
| `background/inverse` | `gray/900` | `gray/200` | `.backgroundInverse` |
| `background/disable` | `gray/200` | `gray/600` | `.backgroundDisable` |
| `background/secondary` | `gray/50` | `gray/800` | `.backgroundSecondary` |
| `background/tinted` | `green/100` | `green/900` | `.backgroundTinted` |
| `background/tinted-inverse` | `green/800` | `green/200` | `.backgroundTintedInverse` |
| `background/error` | `red/100` | **`gray/700`** | `.backgroundError` — voir D7 |
| `border/default` | **noir α 0.10** | **blanc α 0.10** | `.borderDefault` — seul alias sans primitive, voir D49 |
| `border/tinted` | `green/700` | `green/200` | `.borderTinted` |
| `border/error` | `red/800` | `red/400` | `.borderError` |
| `clear` | transparent | transparent | `.clear` |

`borderTinted` partage **le même `case` Swift** que `foregroundTinted`, et `borderError` celui de `foregroundError` :
les deux paires sont égales par construction, pas par coïncidence. Si l'une doit bouger, il faut d'abord scinder le
`case` dans `Color.swift`.

`foreground/placeholder` est identique à `foreground/disable` dans les deux modes, mais reste un rôle distinct.

### Sémantiques — `shadow/*` et `shelf/*`

| Token | Valeur (les deux modes) | Symbole Swift |
|---|---|---|
| `shadow/soft` | noir 10 % | `Color.black.opacity(0.1)` |
| `shadow/book` | noir 16 % | `Color.black.opacity(0.16)` |
| `shadow/light` | noir 18 % | `DesignSystem.Shadow.light` |
| `shadow/lying-book` | noir 22 % | `Color.black.opacity(0.22)` |
| `shadow/spine` | noir 45 % | `Color.black.opacity(0.45)` |
| `shelf/parchment` | → `shelf/parchment` | `ShelfPalette.parchment` |
| `shelf/ink/dark` | → `shelf/ink-dark` | `ShelfPalette.ink(onHex:)` |
| `shelf/ink/cream` | → `shelf/ink-cream` | `ShelfPalette.ink(onHex:)` |
| `shelf/ink/fallback` | → `shelf/ink-fallback` | `ShelfPalette.ink(onHex:)` |
| `shelf/label/paper` | → `color/gray/0` | `ShelfPalette.labelPaper` |
| `shelf/label/ink` | → `color/gray/900` | `ShelfPalette.labelInk` |

`shadow/light` est la **seule** ombre à porter un vrai symbole Swift : `DesignSystem.Shadow.light`, consommée par le
modificateur `View.shadow(_:)` (`DesignSystem/Tokens/Shadow.swift`). Les cinq autres restent des littéraux
`Color.black.opacity(…)` écrits dans le code des features ; leur reprise dans l'enum est suivie par l'**issue 0014**.
Tant qu'elle n'est pas faite, la colonne « Symbole Swift » de ce tableau est la valeur littérale, pas un token.

Comme les autres `shadow/*`, `shadow/light` porte sa propre alpha et **n'est donc pas un alias** : valeur brute,
identique en clair et en sombre.

`shelf/label/paper` et `shelf/label/ink` aliasent des primitives de gris (`color/gray/0`, `color/gray/900`) — mais
elles **ne suivent pas** `background/default` / `foreground/default`, et c'est **volontaire, pas un oubli**. Ces deux
rôles s'inversent en sombre, alors que l'illustration de l'étagère (`ShelfWash`, `ShelfPlank`) est un asset unique et
universel, sans variante sombre : un label qui s'inverserait collerait du papier quasi noir sur un lavis crème. Les
deux variables portent donc la **même valeur dans les deux modes**, dans une collection qui, elle, est mode-aware —
c'est ce qu'il faut lire avant de « réparer » leur binding. Même raisonnement que `shadow/spine`, maintenu à 45 % au
lieu d'être normalisé vers `shadow/soft`. Côté Swift, la règle est portée par `ShelfPalette`, pas par
`DesignSystem.Color`, exactement pour la même raison : ces teintes dépeignent un objet physique, pas du chrome.

`shadow/soft` consolide **trois** littéraux `0.1` séparés (`ScaleButtonStyle`, `CellThumbnail`, `EntityImageView`) —
une valeur en dur qui revient trois fois est un token qui manque.

Les alphas d'ombre vivent ici, dans des variables **couleur**, et non dans la collection `Opacity` : une couleur
bindée porte son alpha elle-même, et `setBoundVariableForEffect(effect, 'color', v)` ne binde que la couleur.

### `Spacing` (source : `DesignSystem/Tokens/Spacing.swift`)

| Token | pt | Symbole Swift |
|---|---|---|
| `spacing/zero` | 0 | `DesignSystem.Spacing.zero` |
| `spacing/xx-small` | 2 | `.xxSmall` |
| `spacing/x-small` | 4 | `.xSmall` |
| `spacing/small` | 8 | `.small` |
| `spacing/s-medium` | 12 | `.sMedium` |
| `spacing/medium` | 16 | `.medium` |
| `spacing/large` | 24 | `.large` |
| `spacing/x-large` | 32 | `.xLarge` |
| `spacing/xx-large` | 64 | `.xxLarge` |
| `line-height/small` | 0.7 | `DesignSystem.LineHeight.small` — **code mort** (D5) |
| `line-height/medium` | 0.86 | `DesignSystem.LineHeight.medium` — **code mort** (D5) |

L'échelle saute de 32 à 64 : il n'y a rien entre les deux.

### `Radius` (source : `DesignSystem/Tokens/CornerRadius.swift`)

| Token | pt | Symbole Swift |
|---|---|---|
| `radius/none` | 0 | `DesignSystem.CornerRadius.none` |
| `radius/minimal` | 4 | `.minimal` |
| `radius/medium` | 8 | `.medium` |
| `radius/rounded` | 12 | `.rounded` |
| `radius/rounded-large` | 24 | `.roundedLarge` |
| `radius/full` | 360 | `.full` |
| `radius/hairline` | 1 | **hors échelle** — `.rect(cornerRadius: 1)`, `PaintedBookView.swift:56` |
| `radius/book` | 2 | **hors échelle** — `.rect(cornerRadius: 2)`, `ShelfBooksView.swift:100` et `:109` |

`radius/full` vaut 360 et non une demi-hauteur calculée, pour saturer sur n'importe quelle taille de contrôle.

### `Sizing`

| Token | pt | Symbole Swift | Note |
|---|---|---|---|
| `sizing/icon/tag` | 16 | `TagLabelStyle.iconSize` | `@ScaledMetric(relativeTo: .body)` — **grandit** avec Dynamic Type, ce n'est pas un plafond |
| `sizing/icon/circular-button` | 24 | `CircularIconButtonStyle` | boîte du glyphe ; + `spacing/medium` de padding → bouton de 56 pt, au-dessus des 44 pt minimum |
| `sizing/shelf/horizontal-margin` | 24 | `ShelfCardMetrics.horizontalMargin` | ADR 0006 |
| `sizing/border/hairline` | 1 | `Constant.borderWidth` | **code mort** (D5) |

Les proportions de l'étagère ne sont **pas** des tokens : `plankHeight = width × 129/820`, `zoneHeight = width × 9/16`,
`topRoom = zoneHeight × 0.25` sont dérivées de la largeur de carte que décide le carrousel (`ShelfCardMetrics`).
Un ratio n'a pas de valeur absolue à mettre dans une variable.

### `Typography` (source : `DesignSystem/Tokens/TextStyle.swift`)

| Token | Valeur | Note |
|---|---|---|
| `font/family/serif` | `Alegreya` | face de lecture — corps, notes de bas de page |
| `font/family/sans` | `Open Sans` | face d'interface — titres, actions, légendes |
| `font/size/title-200` | 32 | `.largeTitle` |
| `font/size/content-400` | 19 | `.body` |
| `font/size/title-50` | 18 | `.title2` |
| `font/size/content-300` | 17 | `.body` |
| `font/size/action-300` | 17 | `.body` |
| `font/size/footnote-200` | 12 | `.footnote` |
| `font/size/action-200` | 12 | `.body` |
| `font/size/caption-200` | 12 | `.caption1` |

Trois tailles valent 12 pt mais s'ancrent sur **trois courbes Dynamic Type différentes** (`.footnote`, `.body`,
`.caption1`) : elles divergent dès que l'utilisateur change la taille du texte. C'est pour ça qu'elles restent trois
tokens et non un seul.

**Figma ne sait pas exprimer Dynamic Type.** Toutes les tailles du fichier sont les valeurs **non mises à l'échelle**.

### `Opacity` — en pourcentage

| Token | % | Source |
|---|---|---|
| `opacity/surface/plank` | 92 | `ShelfRowView.swift:97`, `ShelfEmptyStateView.swift:68` |
| `opacity/surface/backdrop` | 20 | `EntityImageView.swift:32` — voir D2 |

## Styles de texte — 10

Nommés `Famille/symboleSwift`, pour que la feuille Figma et le `case` Swift se retrouvent d'un coup d'œil. Taille et
famille **bindées** aux variables `Typography`.

| Style | Police | pt | Ancre Dynamic Type | Symbole Swift |
|---|---|---|---|---|
| `Title/title200` | OpenSans ExtraBold | 32 | `.largeTitle` | `DesignSystem.TextStyle.title200` |
| `Title/title50` | OpenSans ExtraBold | 18 | `.title2` | `.title50` |
| `Content/content400Bold` | Alegreya Bold | 19 | `.body` | `.content400Bold` |
| `Content/content400` | Alegreya Medium | 19 | `.body` | `.content400` |
| `Content/content300` | Alegreya Medium | 17 | `.body` | `.content300` |
| `Footnote/footnote200Bold` | Alegreya Bold | 12 | `.footnote` | `.footnote200Bold` |
| `Footnote/footnote200` | Alegreya Regular | 12 | `.footnote` | `.footnote200` |
| `Action/action300` | OpenSans SemiBold | 17 | `.body` | `.action300` |
| `Action/action200` | OpenSans SemiBold | 12 | `.body` | `.action200` |
| `Caption/caption200` | OpenSans Regular | 12 | `.caption1` | `.caption200` |

`title200` sert aussi de `largeTitleTextAttributes` et `title50` de `titleTextAttributes` sur `UINavigationBar`
(`DesignSystem.swift`). Les modifier change la barre de navigation.

## Styles d'effet — 7 ombres

Couleur **bindée** à `shadow/*`, donc mode-aware. Le rayon SwiftUI est repris **tel quel** comme flou Figma.

| Style | x, y | Flou | Couleur | Source |
|---|---|---|---|---|
| `Shadow/Pressed` | 0, 2 | 8 | `shadow/soft` | `ScaleButtonStyle.swift:20` — **uniquement pendant l'appui** ; au repos rayon et offset valent 0 |
| `Shadow/Thumbnail` | 0, 0 | 2 | `shadow/soft` | `CellThumbnail.swift:49` |
| `Shadow/Entity Glow` | 0, 0 | 10 | `shadow/soft` | `EntityImageView.swift:22` |
| `Shadow/Painted Book` | 0, 1.5 | 1.5 | `shadow/book` | `PaintedBookView.swift:57` |
| `Shadow/Book Spine` | 0, 0.5 | 1 | `shadow/spine` | `ShelfSpineView.swift:24`, `ShelfBooksView.swift:80` |
| `Shadow/Lying Book` | 1, 2 | 3 | `shadow/lying-book` | `ShelfBooksView.swift:110` |
| `Shadow/Light` | 0, 2 | 3 | `shadow/light` | `.shadow(.light)` — `ShelfLabelView.swift:52`, `ShelfFocusBookCell.swift:66` |

`Shadow/Light` est arrivée avec le label papier (issue 0012), et c'est la seule dont la source ne soit pas un
littéral : les deux points d'appel passent par `DesignSystem.Shadow.light`, donc la valeur ne peut plus diverger entre
le label et la couverture de la cellule de focus.

**Le design a bougé, pas le code.** La feuille Figma portait jusque-là une ombre **brute** en (0, 1), flou 4, sur le
label ; le code partage (0, 2), flou 3. Le code faisant foi, le style a été créé aux valeurs du code puis appliqué aux
deux variantes de `Shelf Card` en remplacement de l'ombre littérale. Sa couleur est bindée à `shadow/light`, comme
celle des six autres.

`Shadow/Light` hérite de D9 — noir pur dans les deux modes, donc invisible sur un fond sombre. Acceptable ici et
seulement ici : elle ne tombe jamais que sur l'illustration de l'étagère, claire dans les deux modes.

`Shadow/Book Spine` est à 45 % — bien plus lourd que toute ombre d'interface, parce qu'il lit comme un **contact**
et non comme une élévation. Ne pas le normaliser vers `shadow/soft`.

`Shadow/Lying Book` est la seule ombre du système avec un décalage en `x` non nul : c'est ce qui vend la lumière
latérale sur une pile.

## Inventaire des composants

**Aucun.** Cette passe n'a produit que des fondations (variables + styles + page `Tokens`).

Ce qui est prêt à devenir un composant, avec sa source :

| Candidat | Source Swift | Variantes attendues |
|---|---|---|
| `Button / Large` | `DesignSystem/ButtonStyles/LargeButtonStyle.swift` | `primary`, `secondary`, `destructive` × `enabled`, `disabled`, `pressed` |
| `Button / Circular Icon` | `DesignSystem/ButtonStyles/CircularIconButtonStyle.swift` | `enabled`, `disabled`, `pressed` + `INSTANCE_SWAP` pour le glyphe |
| `Tag` | `DesignSystem/LabelStyles/TagLabelStyle.swift` | `tinted`, `secondary` |
| `TagView` | `DesignSystem/TagView.swift` | aucune — mais voir D8 avant de le répliquer |

Pour les créer, charger `figma-generate-library` et suivre sa phase 3 (une page par composant).

## Ce qui n'existe pas, et quoi faire à la place

| Absent | Pourquoi | À la place |
|---|---|---|
| Dynamic Type | Figma n'a pas de notion d'échelle de texte système | Les tailles du fichier sont les valeurs de base. Pour vérifier un cas accessibilité, tester dans le simulateur, pas dans Figma |
| Une variable pour la couleur d'un dos de livre | `ShelfPalette.spineColor(_:)` la **calcule** depuis l'hex de la couverture | Utiliser `shelf/parchment` comme état de repli, et accepter que la couleur réelle soit dynamique |
| Des tokens pour les ratios de l'étagère | Ce sont des proportions dérivées de la largeur de carte, pas des longueurs | Lire `ShelfCardMetrics` ; documenté dans ADR 0006 |
| Code syntax WEB / ANDROID | Il n'y a ni codebase web ni Android dans ce dépôt | iOS seulement. Ne pas ajouter de `var(--…)` fantaisiste |
| Une bibliothèque Figma souscrite | `get_libraries` ne renvoie que des UI kits communautaires (Material 3, iOS 26/27, SDS) | Tout est construit depuis le code. Ne pas importer un kit « pour aller plus vite » : son modèle de tokens ne correspond pas |
| Styles de peinture (`PaintStyle`) | Les variables couvrent le besoin et portent les modes | Utiliser les variables `Color`, pas des styles de couleur |

## Snippet de préambule

À coller en tête de tout `use_figma` qui crée des nœuds dans ce fichier. Encode les pièges déjà payés.

```js
const colls = await figma.variables.getLocalVariableCollectionsAsync();
const COLOR_COLL = colls.find(c => c.name === 'Color');
const MODES = {
  Light: COLOR_COLL.modes.find(m => m.name === 'Light').modeId,
  Dark: COLOR_COLL.modes.find(m => m.name === 'Dark').modeId,
};

const allVars = await figma.variables.getLocalVariablesAsync();
const V = {}, byId = {};
for (const v of allVars) { byId[v.id] = v; V[v.name] = v; }
const TS = {}; for (const s of await figma.getLocalTextStylesAsync()) TS[s.name] = s;
const ES = {}; for (const e of await figma.getLocalEffectStylesAsync()) ES[e.name] = e;

// Les faces réelles se résolvent : pas de substitut. Charger avant tout write de texte.
for (const [family, style] of [
  ['Inter', 'Regular'], ['Inter', 'Semi Bold'], ['Inter', 'Bold'],
  ['Alegreya', 'Regular'], ['Alegreya', 'Medium'], ['Alegreya', 'Bold'],
  ['Open Sans', 'Regular'], ['Open Sans', 'SemiBold'], ['Open Sans', 'ExtraBold'],
]) await figma.loadFontAsync({ family, style });

// Résout un alias jusqu'à sa valeur concrète, pour un mode donné.
function resolve(v, modeId) {
  let val = v.valuesByMode[modeId], guard = 0;
  while (val && val.type === 'VARIABLE_ALIAS' && guard++ < 8) {
    const next = byId[val.id], keys = Object.keys(next.valuesByMode);
    val = next.valuesByMode[next.valuesByMode[modeId] !== undefined ? modeId : keys[0]];
  }
  return val;
}

// Peinture bindée dont la couleur de BASE porte la valeur résolue : sur une instance,
// le littéral gagne sur la variable, donc une base noire s'affiche NOIRE.
function paint(tokenName, modeId, opacity) {
  const v = V[tokenName];
  const b = resolve(v, modeId);
  const p = figma.variables.setBoundVariableForPaint(
    { type: 'SOLID', color: { r: b.r, g: b.g, b: b.b } }, 'color', v);
  return opacity === undefined ? p : { ...p, opacity };
}

// Conteneur de structure : jamais de fond blanc, toujours hug vertical.
function AL(dir, props) { const f = figma.createAutoLayout(dir, props); f.fills = []; return f; }

// Largeur fixe + hauteur qui hugge, dans le bon ordre (resize fige les DEUX axes).
function fixWidth(node, w) {
  node.resize(w, node.height);
  node.layoutSizingHorizontal = 'FIXED';
  node.layoutSizingVertical = 'HUG';
}
```

Rappels d'API qui ont chacun coûté un aller-retour :

- `use_figma` est **atomique** : un script qui échoue ne modifie rien. Retenter après correction est sûr.
- Le contexte de page retombe sur la **première page** à chaque appel ; `setCurrentPageAsync` **une fois par script**.
- Une opacité sur une peinture bindée demande une **passe séparée** (`node.fills = node.fills.map(p => ({...p, opacity}))`),
  et `clone()` / `createComponentFromNode()` la perdent.
- `INSTANCE_SWAP` veut un **node id**, pas une `key`.
- `query()` n'accepte pas de `/` : utiliser `findOne(n => n.name === 'Icon / xmark')`.
- Les coordonnées d'un enfant de `SECTION` sont **relatives** à la section.

## Checklist d'audit

Avant de livrer une passe :

- [ ] Zéro fill / stroke en dur dans un composant
- [ ] Zéro texte sans style dans un composant
- [ ] Zéro variable en `ALL_SCOPES`
- [ ] Zéro variable sans code syntax iOS ni description
- [ ] Chaque style de texte a `fontFamily` **et** `fontSize` bindés
- [ ] Chaque style d'effet a sa couleur bindée
- [ ] Aucun enfant ne déborde de sa section, aucune section n'en chevauche une autre
- [ ] **Capturer et regarder** chaque section — un script qui retourne `success` peut avoir produit une planche vide

Le script : `~/.claude/skills/extract-design-system/scripts/audit.js`. Il ne contrôle les fills et les textes
**qu'à l'intérieur des composants** — tant qu'il n'y a pas de composant dans ce fichier, ces deux compteurs restent
vides par construction, ce n'est pas une preuve de propreté. Les contrôles étendus (code syntax, descriptions,
bindings de styles) ont été ajoutés en ligne lors de la passe du 2026-08-18 ; les reprendre.

Dernier résultat (2026-08-18) : tout à zéro. 1 page, 92 variables, 10 styles de texte, 6 styles d'effet, 0 composant.

## Divergences relevées dans le code

Produites par la réplication. **Statut « ouverte » = rien n'a été changé côté code.**

| # | Où | Constat | Statut |
|---|---|---|---|
| D1 | `Assets.xcassets/color/gray/700 75%.colorset` | Le nom annonce 75 %, l'alpha vaut **0.50** | ouverte — valeur répliquée fidèlement, nom conservé |
| D2 | `Features/EntityBrowser/EntityImageView.swift:32` | `.opacity(colorScheme == .dark ? 0.2 : 0.2)` — ternaire mort, les deux branches sont identiques | ouverte |
| D3 | `DesignSystem/Tokens/Color.swift:76-86` | `uiColor` **ignore `self`** : il renvoie noir/blanc pour *tous* les tokens sauf `.clear`. C'est un bouchon qui se présente comme une correspondance | ouverte |
| D4 | `DesignSystem/Tokens/TextStyle.swift:56` | `weight` contredit `customFont` : `title200` / `title50` déclarent `.black` alors que la police est OpenSans **ExtraBold**. Visible seulement si la police custom ne charge pas — ce que D6 rend probable | ouverte |
| D5 | `Spacing.swift` (`LineHeight` 0.7 / 0.86), `TagView.swift` (`Constant.borderWidth`) | Déclarés, référencés nulle part | ouverte — répliqués et marqués « code mort » |
| D6 | `DesignSystem/Tokens/TextStyle.swift`, `DesignSystem/DesignSystem.swift` | **Bug réel, plus large que décrit ici.** Les trois faces OpenSans retombaient sur la police système, pour trois raisons distinctes : `UIFont(name:)` résout un nom **PostScript**, qui n'est pas le nom de fichier. Les faces livrées s'appellent `OpenSans-Extrabold` et `OpenSans-Semibold` (b minuscule), et la régulière s'appelle simplement `OpenSans` — le code demandait `OpenSans-ExtraBold`, `OpenSans-SemiBold` et `OpenSans-Regular`. Donc `title200`, `title50`, `action200`, `action300` et `caption200` étaient en San Francisco **partout dans l'app**. S'y ajoutait la casse du fichier `OpenSans-Semibold.ttf`, que `Bundle.url(forResource:)` ne trouvait pas, et le `break` de `setupFonts` — au lieu de `continue` — qui faisait avorter la boucle et privait d'enregistrement toutes les faces déclarées après elle | **résolue** — les trois noms PostScript corrigés, `break` → `continue`. Verrouillée par `Tests/DesignSystemFontTests.swift` : chaque face doit se résoudre, et aucun style de texte ne doit retomber sur la police système. C'est la seule façon d'attraper ce bug — le compilateur ne le voit pas, et à l'écran il ressemble à un choix de design |
| D7 | `Color.swift` — `backgroundError` | En sombre, la valeur est un **gris** (`gray/700`), là où tous les autres tokens d'erreur restent rouges dans les deux modes | ouverte — probable oubli |
| D8 | `DesignSystem/TagView.swift:26` | `RoundedRectangle(cornerRadius: .medium)` sans `.fill` → se peint dans la couleur de premier plan héritée | ouverte |
| D9 | Les six ombres | Toutes en noir pur dans les deux modes. En mode sombre, sur `background/default` (noir pur), elles sont **invisibles** — visible sur la planche `Ombres — Sombre` (`16:36`) | ouverte — la variable `shadow/*` est mode-aware, il suffit d'y mettre une teinte claire en sombre |
| D10 | `CLAUDE.md` (racine) | Affirme que `ReCIT_iOS/CLAUDE.md` est un « **duplicate** of this file ». C'en est un fichier **différent** : un guide Swift/SwiftUI pour agents, pas un miroir | ouverte — commentaire périmé |

D6 mérite une correction indépendamment de ce travail Figma : deux polices ne se chargent pas sur l'appareil.

## Le réflexe de reprise

Au démarrage de toute session qui touche au fichier Figma :

```bash
find . -name "figma-library.md" -o -name "*figma*.md" | head
```

Lire ce fichier **avant** d'appeler le moindre outil Figma. Il donne le `fileKey`, les conventions et les node ids —
donc de quoi continuer au lieu de recommencer. Ne demander le lien Figma que s'il n'y a pas de doc.

Si le fichier Figma a changé sans cette doc (variables ou composants ajoutés à la main), **réconcilier** :
inventorier Figma, mettre la doc à jour, signaler les écarts. Une doc en retard est pire qu'une absence de doc :
elle est crue.

Toute passe qui ajoute un composant, une variable ou un écran met cette doc à jour **dans la même session** —
en particulier les compteurs, les node ids, et le statut des divergences.

---

# Écrans (passe du 2026-08-18, `extract-screens`)

Huit écrans, chacun en clair et en sombre : **16 frames de 393 × 852**, safe areas 59 / 34. Mode épinglé sur chaque
frame via `setExplicitVariableModeForCollection`, ce qui est ce qui fait basculer les 27 tokens sémantiques sans
retoucher un seul nœud.

## Carte des pages (mise à jour)

| Page | id | Contenu |
|---|---|---|
| `Tokens` | `0:1` | 6 sections, 9 planches de tokens |
| `Components` | `20:2` | Les 3 composants qui **miroitent le package** design system |
| `Screens · Components` | `20:3` | Les 23 composites de feature et de chrome |
| `Screens` | `20:4` | 16 frames d'écran + 8 panneaux de spécification, puis les sections `Onboarding` (`73:2829`) et `Ranger mes livres` (`97:3755`) |

La séparation entre `Components` et `Screens · Components` est intentionnelle : `Components` ne contient que ce qui
existe dans `DesignSystem/` côté Swift (les deux `ButtonStyle`, le `LabelStyle` de tag). Tout le reste — le chrome iOS
et les vues de feature — vit sur `Screens · Components` et le dit dans sa description. La bibliothèque du design
system reste le miroir du package ; les composites ne s'y invitent pas.

## Composants — `Components` (miroir du package)

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `Button / Large` | `22:14` | Style ∈ {Primary, Secondary, Destructive} × State ∈ {Default, Disabled} | `Label#22:1` | `ButtonStyles/LargeButtonStyle.swift` |
| `Button / Circular Icon` | `23:10` | State ∈ {Default, Disabled} | `Glyph#23:1` (INSTANCE_SWAP) | `ButtonStyles/CircularIconButtonStyle.swift` |
| `Tag` | `23:23` | Color ∈ {Tinted, Secondary} | `Label#23:5`, `Glyph#23:6`, `Show glyph#23:7` | `LabelStyles/TagLabelStyle.swift` |

**Aucun des deux boutons n'a de variante `Pressed`** : l'état pressé est un `scaleEffect(0.9)` avec un `easeOut(0.2)`,
c'est-à-dire une transformation, pas une apparence. En faire une variante inventerait un état visuel qui n'existe pas.

## Composants — `Screens · Components`

### Chrome système

Couleurs **littérales** et axe `Theme` explicite, sauf mention contraire : une barre de statut ne se recolore pas avec
la palette de l'app, elle se recolore avec l'OS.

| Composant | node id | Variantes | Propriétés | Note |
|---|---|---|---|---|
| `Chrome / Status Bar` | `24:30` | Theme | — | 393 × 59, sans fond |
| `Chrome / Home Indicator` | `24:35` | Theme | — | 393 × 34, grabber 140 × 5 |
| `Chrome / Tab Bar` | `25:234` | Active ∈ {Inventaire, Listes, Réglages, Recherche} × Theme | — | 393 × 83. Teinte active **bindée** à `foreground/tinted` (`ReCIT.swift:31`) |
| `Chrome / Nav Bar` | `26:162` | Style ∈ {Large, Inline, Inline + Back} × Theme | `Title#26:18`, `Action glyph#26:19`, `Show action#26:20` | Large 96, Inline 44. Titres **bindés** — l'app configure `UINavigationBarAppearance` |
| `Chrome / Search Field` | `27:172` | State ∈ {Idle, Active} × Theme | `Placeholder#27:4` | 393 × 52. `Active` signifie aussi que le carrousel d'étagères a disparu |
| `Icon` | `21:60` | Glyph ∈ 18 valeurs | — | À consommer par `INSTANCE_SWAP`, jamais une variante par icône |

### Composites de feature

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `Thumbnail` | `28:163` | Size ∈ {Small 36, Medium 48, Large 64} × Shape ∈ {Minimal 4, Medium 8, Round} | — | `Components/CellThumbnail.swift` |
| `Section Header` | `28:164` | — | `Label#28:0` | `Shelves/ShelfSectionHeader.swift` depuis l'issue 0010 ; ailleurs, des en-têtes de `Section` littéraux identiques. **Aucune variante avec action** — voir D35 |
| `Separator` | `47:193` | — | — | Le filet entre rangs d'un groupe encarté |
| `Cell / Book` | `29:154` | — | `Title#29:0`, `Subtitle#29:1`, `Show subtitle#29:2`, `Authors#29:3`, `Owner#29:4`, `Show owner#29:5`, `Show divider#29:6` | `Inventory/InventoryCell.swift` |
| `Cell / Entity` | `31:188` | Type ∈ {Work, Author, Item} | `Title#31:15`, `Subtitle#31:16`, `Show subtitle#31:17`, `Owner#31:18`, `Show owner#31:19` | `Search/SearchResultCell.swift` **et** `Book/OtherEditionsCell.swift` |
| `Cell / Transaction` | `30:162` | — | `Title#30:0`, `Description#30:1`, `Unread#30:2` | `Transactions/TransactionCellView.swift` |
| `Cell / User` | `30:179` | — | `Username#30:3`, `Item count#30:4` | `Community/UserCellView.swift` |
| `Cell / List` | `38:193` | — | `Name#38:0`, `Explanation#38:1` | `Lists/EntityListView.swift` |
| `Row / Link` | `38:200` | Tone ∈ {Tinted, Destructive} | `Label` (fusionnée) | `Profile/ProfileView.swift` |
| `Row / Summary` | `38:201` | — | `Body#38:5` | `EntityBrowser/EntitySummaryView.swift` + `WithLabel.swift` |
| `User Header` | `32:170` | — | `Username#32:0`, `Item count#32:1`, `Show avatar#32:2` | `Community/UserHeaderView.swift` |
| `Entity Header` | `32:179` | — | `Title#32:4`, `Subtitle#32:5`, `Show subtitle#32:6` | `EntityBrowser/EntityHeaderView.swift` + `EntityImageView.swift` |
| `Syncing Placeholder` | `32:174` | — | `Message#32:3` | `Components/SyncingPlaceholderView.swift` |
| `Shelf Card` | `34:210` | Paint ∈ {Placeholder, Illustrative} | `Name#34:2` | `Shelves/ShelfRowView.swift` — la ligne de nom porte `shelf/label/paper` + `shelf/label/ink` et le style `Shadow/Light` depuis l'issue 0012, sur les **deux** variantes. `Paint=Placeholder` reste périmée par ailleurs : voir D34 |
| `Shelf Create Card` | `34:211` | — | `Name#34:3` | `Shelves/ShelfEmptyStateView.swift` — le composant Figma porte encore l'ancien nom (renommage Swift à l'issue 0011). Vérifier aussi son glyphe « + » : le code l'a perdu à la même issue |
| `Transaction Actions Bar` | `37:178` | — | `Show overflow#37:0` | `Transactions/TransactionActionsBar.swift` |
| `Transaction Message` | `37:213` | Type ∈ {Action, User} | `Body`, `Timestamp`, `Author` (par variante) | `TransactionDetailView.messageView` |

⚠️ **Les clés de propriété sont réattribuées par `combineAsVariants`.** Ne jamais réutiliser la clé renvoyée à la
création d'un composant avant sa combinaison — elle change. Le préambule ci-dessous contient un `setByName` qui
résout la clé par son nom au moment de s'en servir : c'est la seule façon robuste.

## Table des écrans

| Écran | Clair | Sombre | Panneau | Source Swift |
|---|---|---|---|---|
| **Étagères** | `39:2` | `39:179` | `45:1678` | `Shelves/ShelvesView.swift` + `ShelvesContent.swift` |
| **Listes** | `40:309` | `40:404` | `45:1690` | `Lists/EntityListView.swift` |
| **Détail étagère** | `40:499` | `40:646` | `45:1702` | `Shelves/ShelfDetailView.swift` |
| **Recherche** | `41:723` | `41:841` | `45:1714` | `Search/MainSearchView.swift` → `SearchView.swift` |
| **Profil** | `41:959` | `41:1094` | `45:1726` | `Profile/ProfileView.swift` |
| **Fiche livre** | `42:1125` | `42:1219` | `45:1738` | `Book/BookDetailView.swift` |
| **Toutes les transactions** | `42:1313` | `42:1435` | `45:1750` | `Transactions/AllTransactionsView.swift` |
| **Détail transaction** | `42:1557` | `42:1688` | `45:1762` | `Transactions/TransactionDetailView.swift` |

Chaque frame ne contient que des **instances** et des conteneurs de layout nommés (`list group`). Audit de
factorisation : **0 dessin brut** sur les 16 frames.

## Recettes de composition

- **Un onglet racine** = Status Bar + Nav Bar (Large) + [Search Field] + contenu + Tab Bar + Home Indicator. Le chrome
  s'ajoute **en dernier** pour qu'il peigne par-dessus le contenu qui défile.
- **Un écran poussé** = Status Bar + Nav Bar (Inline + Back) + contenu + Tab Bar + Home Indicator. La barre d'onglets
  reste : une destination poussée vit dans sa pile, donc dans son onglet.
- **Une List encartée** = un conteneur `list group` (auto-layout vertical, `background/default`, `radius/medium`,
  clip) contenant des instances de cellule séparées par des instances de `Separator`.
- **Une List `.plain`** = les cellules directement sur `background/default`, `Show divider` allumé sur `Cell / Book`.

## Ce qui n'existe pas dans ce fichier, et pourquoi

| Absent | Raison | À la place |
|---|---|---|
| Les couvertures de livres | Le plugin API ne peut pas récupérer une image distante | `Thumbnail` reste sur `background/disable`, qui est l'état réel avant chargement |
| `ShelfWash` | 1 Mo, trop lourd pour le payload du plugin | Une ellipse floutée à la teinte dominante `#F5E4C1`. `ShelfPlank` **est** le vrai PNG (réduit) |
| Les dos de livres peints | `SpineStripLoader` les peint depuis un ruban de la couverture | `Paint=Placeholder` (fidèle : parchemin) ou `Paint=Illustrative` (teintes inventées, à ne pas prendre pour des données) |
| Les SF Symbols | Non redistribuables dans un fichier Figma | 15 approximations vectorielles à la même taille optique |
| La tab bar Liquid Glass d'iOS 26 | Non reproductible sans le UI kit Apple | La barre classique, état actif par la couleur seule |
| Les variantes `.fill` des symboles actifs | Même raison | La couleur suffit à marquer l'onglet actif |
| Les spinners et états transitoires | `ProgressView` est un contrôle vivant | Non maquettés, listés dans chaque panneau |
| L'appui maintenu sur une étagère | Hors périmètre de cette passe | ADR 0006 décrit le geste ; rien dans Figma |
| Les feuilles et formulaires | Hors périmètre de cette passe | Les 4 coques restent à faire |

## Préambule pour toute passe sur les écrans

À coller en tête de tout `use_figma` qui compose un écran. Complète le préambule des tokens.

```js
const page = figma.root.children.find(p => p.name === 'Screens');
await figma.setCurrentPageAsync(page);
// Charger TOUTES les faces avant d'instancier : un style de texte bindé les résout à la pose.
for (const [family, style] of [
  ['Inter', 'Regular'], ['Inter', 'Medium'], ['Inter', 'Semi Bold'], ['Inter', 'Bold'],
  ['Alegreya', 'Regular'], ['Alegreya', 'Medium'], ['Alegreya', 'Bold'],
  ['Open Sans', 'Regular'], ['Open Sans', 'SemiBold'], ['Open Sans', 'ExtraBold'],
]) await figma.loadFontAsync({ family, style });

const COLOR_COLL = (await figma.variables.getLocalVariableCollectionsAsync()).find(c => c.name === 'Color');
const MODE = {
  Light: COLOR_COLL.modes.find(m => m.name === 'Light').modeId,
  Dark: COLOR_COLL.modes.find(m => m.name === 'Dark').modeId,
};

/** Résout une propriété par son NOM : `combineAsVariants` réattribue les clés. */
function setByName(inst, name, value) {
  const key = Object.keys(inst.componentProperties || {}).find(k => k.split('#')[0] === name);
  if (!key) throw new Error('no property "' + name + '" on ' + inst.name);
  inst.setProperties({ [key]: value });
}

/** Le gras markdown que `Text(.init(...))` rend, appliqué à la main sur l'instance. */
function applyBold(textNode) {
  const chars = textNode.characters;
  const ranges = []; let out = '', i = 0;
  while (i < chars.length) {
    if (chars[i] === '*' && chars[i + 1] === '*') {
      const end = chars.indexOf('**', i + 2);
      if (end > -1) {
        const inner = chars.slice(i + 2, end);
        ranges.push([out.length, out.length + inner.length]);
        out += inner; i = end + 2; continue;
      }
    }
    out += chars[i]; i++;
  }
  if (!ranges.length) return false;
  textNode.characters = out;
  for (const [a, b] of ranges) textNode.setRangeFontName(a, b, { family: 'Alegreya', style: 'Bold' });
  return true;
}

/** Un frame d'écran, mode épinglé. Le chrome s'ajoute EN DERNIER. */
function screenShell(name, theme, groundPaint) {
  const f = figma.createFrame();
  f.name = name; f.resize(393, 852); f.clipsContent = true;
  f.fills = [groundPaint];
  page.appendChild(f);
  f.setExplicitVariableModeForCollection(COLOR_COLL, MODE[theme]);
  return f;
}
```

Pièges spécifiques aux écrans, en plus des sept de l'API :

- **`resize()` refige les deux axes.** Sur un composant censé huguer en hauteur, il faut remettre
  `layoutSizingVertical = 'HUG'` **après** le `resize`. Symptôme : un composant de 393 × 10.
- **`combineAsVariants` réattribue les clés de propriété.** Utiliser `setByName`.
- **Une instance d'icône ne se redimensionne que si le glyphe a des contraintes `SCALE`.** Les 15 variantes d'`Icon`
  les portent ; un nouveau glyphe doit les recevoir aussi.
- **La rotation Figma est antihoraire positive.** Le livre penché de l'étagère est à `+10`, pas à `-10` : il doit
  tomber **sur** la pile, pas s'en écarter.
- **Le texte enrichi n'est pas une propriété.** Poser le gras à la main sur l'instance, après avoir posé le texte.

## Checklist d'audit — écrans

- [ ] Chaque frame ne contient que des instances et des conteneurs de layout **nommés**
- [ ] Zéro `VECTOR` / `RECTANGLE` / `ELLIPSE` / `TEXT` hors instance dans un frame d'écran
- [ ] Chaque composant porte une description avec son type Swift, ses métriques et ses pièges
- [ ] Chaque paire clair / sombre a son mode épinglé sur le frame
- [ ] Les panneaux de spécification sont exclus de l'audit de factorisation (ils sont de la doc, pas des écrans)
- [ ] **Capturer et regarder** chaque frame

Dernier résultat (2026-08-18) : 0 dessin brut, 0 fill en dur, 0 texte sans style, 0 nom dupliqué, 0 composant sans
description, 0 variable en `ALL_SCOPES`. 4 pages, 92 variables, 10 styles de texte, 6 styles d'effet,
**26 composants**, **16 frames d'écran**, 8 panneaux.

Mise à jour du 2026-08-20 (passes « Résultat » puis « Tri manuel ») : **29 composants** sur `Screens · Components`
(+`Bottom Action Bar`, et `Icon` passe à 16 variantes avec `line.3.horizontal`). Avant le tri manuel : **28 composants**
(+3 : `AutoSort / Shelf Header`, `AutoSort / Book Row`, `AutoSort / Note` ; `Chrome / Nav Bar` gagne une variante,
pas un composant), 3 sur `Components`. Écrans : les 16 frames répliqués, plus les frames d'exploration de la section
`Onboarding` et les 2 frames de la section `Ranger mes livres`. La passe onboarding du même jour n'avait pas rejoué
les compteurs.

Mise à jour du 2026-08-20 (soir, issue 0036) : toujours **29 composants** — aucun composant nouveau, mais `Icon`
(`21:60`) passe à **18 variantes** (`circle`, `exclamationmark.circle`) et `AutoSort / Shelf Header` (`100:228`)
gagne la propriété `Mark glyph#133:0`. Écrans : **9 frames** de plus dans `Ranger mes livres`.

## Écrans morts relevés dans le code

Aucune transition n'y mène ; seule leur propre `#Preview` les référence. **Candidats à la suppression.**

| Écran | Constat |
|---|---|
| `Features/Inventory/MyInventoryView.swift` | Remplacé par `ShelvesView` (ADR 0003), jamais supprimé |
| `Features/Works/WorkListView.swift` | Zéro référence |
| `Features/EntityBrowser/EntityBrowserView.swift` | Zéro référence |

Deux onglets sont par ailleurs déclarés mais **jamais rendus** (`TabConfig.isHidden == true`) : `community`
(`CommunityView`) et `transactions`, ce dernier n'étant qu'un `Text("nav.transactions_placeholder")`.

## Divergences relevées dans le code — passe écrans

Suite de la table des tokens. **Statut « ouverte » = rien n'a été changé côté code.**

| # | Où | Constat | Statut |
|---|---|---|---|
| D11 | `MainTabView.swift:85` | `selectedTab` vaut `.community` par défaut — un onglet dont `isHidden == true`, donc absent du `TabView`. L'app démarre sur une sélection qui n'existe pas | ouverte |
| D12 | `MainTabView.swift:130-140` | `.navigationTitle` / `.navigationBarTitleDisplayMode` appliqués à `ProfileView`, `EntityListView` et `AddInventoryItemSearchView`, qui possèdent **chacune leur propre `NavigationStack`**. Les modificateurs sont hors pile : morts. Trois occurrences | ouverte |
| D13 | `tab.profile` vs `nav.profile` | L'onglet s'appelle « Réglages », son titre de navigation « Profil ». Deux noms pour un écran | ouverte |
| D14 | `Search/MainSearchView.swift` | Le fichier porte un nom (`MainSearchView`) qu'aucun type n'utilise — il contient `AddInventoryItemSearchView` — et son en-tête annonce un troisième nom (`AddInventoryItemView.swift`) | ouverte |
| D15 | `Book/BookDetailView.swift:8`, `Book/BookViewModel.swift:16` | Les deux renvoient à `EditionDetailView`, qui n'existe plus | ouverte |
| D16 | `Lists/EntityListView.swift:2`, `Works/WorkListView.swift:2` | En-têtes annonçant `MyInventoryView.swift` ; `#Preview` au corps commenté | ouverte |
| D17 | `EntityListView.swift:27`, `WorkListView.swift:22`, `CommunityView.swift:23` | `range(of:options:.caseInsensitive)` sur du texte saisi, là où `CLAUDE.md` impose `localizedStandardContains()`. `InventoryListContent` le fait correctement — trois points d'entrée, deux méthodes | ouverte |
| D18 | `SearchView.swift:41` et `:118`, `EntityListView.swift:50`, `InventoryListContent.swift:81`, `SyncingPlaceholderView.swift:26`, `SyncingInlineRow.swift:25` | `.red` / `.secondary` **système** là où `.foregroundError` / `.foregroundSecondary` existent. Six occurrences | ouverte |
| D19 | `SearchView.swift:71` | `"loading more results..."` en dur, non localisé, dans une app entièrement en `Localizable.xcstrings` — et un `HStack(spacing: 12)` littéral | ouverte |
| D20 | `Localizable.xcstrings` | 9 littéraux français de la feature Étagères sont entrés dans le catalogue **comme clés**, sans traduction `fr` : « Cette étagère est vide », « Créer », « Description (optionnel) », « Enregistrer », « Fermer », « Modifier l'étagère », « Nom de l'étagère », « Nouvelle étagère », « Visibilité ». La langue source étant l'anglais, un utilisateur anglophone voit du français. Une clé vide `""` traîne aussi | ouverte |
| D21 | `search.friends_inventory` | « Dans l'inventaire de **tes** amis » — le SEUL tutoiement du catalogue. Les 21 autres chaînes à la deuxième personne vouvoient | ouverte |
| D22 | `SearchResultCell.workCell` vs `OtherEditionsCell` | Même layout, dupliqué. Les deux écrivent `HStack(spacing: 12)` et `VStack(spacing: 4)` en **littéraux** alors que les nombres valent exactement `.sMedium` / `.xSmall`. Le commentaire d'`OtherEditionsCell` dit qu'il « mirrors the book-list cover cell » — il le miroite par copie | ouverte |
| D23 | `CellThumbnail` — points d'appel | La même couverture reçoit un rayon et une taille différents selon l'entrée : `.minimal` / 48 dans `InventoryCell` et `TransactionCellView`, les **défauts** `.medium` / 36 dans `SearchResultCell` et `OtherEditionsCell` | ouverte |
| D24 | `TransactionCellView.swift:47-51` | `TransactionStateLabel` est enveloppé dans `.textStyle(.content300).foregroundStyle(.foregroundSecondary)` : les deux sont morts, `TagLabelStyle` repose son propre style et ses fills en aval. Le `HStack(spacing: .xSmall)` qui l'entoure n'a qu'un enfant | ouverte |
| D25 | `TransactionCellView.isRead` | La propriété s'appelle `isRead` mais renvoie `true` quand la transaction n'a **pas** été lue (elle nie `readStatus`). La pastille non-lu s'affiche donc quand `isRead` est vrai | ouverte |
| D26 | `TransactionDetailView.messageView` | Les messages entrants et sortants rendent **à l'identique** : `getUIMessages` distingue soigneusement `.incoming` de `.outgoing`, mais la branche `default:` les traite d'un seul layout — ni côté, ni couleur, ni alignement | ouverte |
| D27 | `TransactionDetailView` — horodatage | `.formatted(date: .abbreviated, time: .standard)` : `.standard` inclut les **secondes**, dans un fil de discussion | ouverte |
| D28 | `UserCellView` vs `UserHeaderView` | `UserCellView` ne pose **aucun** `foregroundStyle` et hérite de la couleur de label de la `List` ; `UserHeaderView` pose `foreground/default` explicitement sur les deux mêmes lignes | ouverte |
| D29 | `ShelfEmptyStateView` (ex-`ShelfCreateCardView`) | Redéclarait `plankHeight`, `zoneHeight` et `topRoom` en propriétés calculées privées au lieu d'utiliser `ShelfCardMetrics` | résolue — issue 0011, la vue utilise `ShelfCardMetrics` |
| D30 | `EntitySummaryView` | `.onTapGesture` là où un `Button` est requis par la convention du projet : il n'a besoin ni de la position ni du nombre de taps. Conséquence réelle : pas d'état pressé, pas d'action d'accessibilité. (`ShelfCreateCardView` avait le même défaut ; corrigé par l'issue 0011) | ouverte |
| D31 | `Features/Shelves/ShelfSectionHeader.swift` (ex-`ShelvesContent.sectionTitle`) | Le constat tient toujours, à l'adresse près : l'issue 0010 a remplacé la fonction par un type de vue, sans toucher aux deux points relevés. Le titre utilise `foregroundDefault` là où les autres en-têtes de section retombent sur le secondaire du système, et ses libellés restent des littéraux français passés en `String` — donc **non localisés** : `"Étagères"`, `"Tous les livres · N"` et `"Ajouter"`, ce dernier alors qu'une clé `action.add` traduite (« Add » / « Ajouter ») existe déjà au catalogue | ouverte — reformulée pour l'issue 0010 |
| D32 | `ReCIT_iOS.xcodeproj` | `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` alors qu'**aucun asset `AccentColor` n'existe**. Le `.tint(.foregroundTinted)` de `ReCIT.swift:31` sauve le rendu, mais le réglage pointe dans le vide | ouverte |
| D33 | `AllTransactionsView` | Ne fixe pas `navigationBarTitleDisplayMode`, donc iOS lui donne un grand titre. « Toutes les transactions » en `title200` (32 pt ExtraBold) passe à la ligne dans une barre de 96 pt | ouverte |
| D34 | `Shelf Card`, variante `Paint=Placeholder` (`34:210`) | **Divergence côté Figma.** La passe 0012 n'a corrigé que ce qu'elle touchait : la variante reste périmée face au code livré. Sa `name row` n'a **aucun fill**, donc la pastille de papier ne s'y dessine pas, et elle affiche encore un **crayon** là où le code n'a plus qu'un chevron — le crayon a quitté la carte pour la barre de navigation du détail (issue 0008) | ouverte — demande une passe de design, pas une correction de code |
| D35 | `Section Header` (`28:164`) vs `ShelfSectionHeader.swift` | Le composant Figma n'a ni action de fin de ligne ni variante pour en porter une, alors que l'en-tête « Étagères » a gagné un bouton **Ajouter** teinté (issue 0010). Le composant décrit donc un en-tête que l'écran Étagères n'utilise plus tel quel | ouverte — passe de design |
| D36 | `Features/Shelves/ShelfLabelView.swift:43` | Le chevron du label est peint en `.foregroundSecondary` — un rôle qui **s'inverse** en sombre — et dimensionné par `.font(.footnote)` système, sur un papier délibérément mode-indépendant (`shelf/label/ink` / `shelf/label/paper`). En sombre, le chevron passe donc de `gray/600` à `gray/400` sur un papier resté blanc : le contraste baisse au lieu d'être stable, et c'est le seul élément du label à ne pas suivre la règle du reste | ouverte — relevée en documentant l'issue 0013 |
| D37 | `Features/AutoSort/*` | Toute la feature était en **littéraux français** : « Ranger mes livres », « Créer ces étagères », « Terminer », « Relancer le rangement »… entraient dans `Localizable.xcstrings` comme **clés**, sans aucune localisation — la langue source étant l'anglais, un anglophone lisait du français. Même défaut que D20 pour Étagères | **en grande partie résolue par suppression** — l'issue 0043 a supprimé `AutoSortPlanView`, `AutoSortApplyReport` et `AutoSortShelfMark`, qui portaient la quasi-totalité de ces littéraux, et déplacé `AutoSortBookRow` en `Features/Sorting/SortBookRow.swift` (il n'en portait aucun). **Reste ouverte pour le seul survivant**, `AutoSortUnavailableView`, dont les trois messages d'indisponibilité sont toujours des littéraux ; `action.open_settings` y est la seule vraie clé traduite. La surface de tri qui remplace l'écran écrit tout au catalogue |
| D38 | `Features/AutoSort/AutoSortApplyReport.swift` | Les pluriels étaient concaténés dans l'interpolation (`"étagère\(n > 1 ? "s ont" : " a")"`). Ces phrases ne pouvaient pas entrer au catalogue du tout, et la règle de pluriel devenait du code au lieu d'être une donnée de traduction | **résolue par suppression** — le fichier a été supprimé par l'issue 0043. Son remplaçant, `Features/Sorting/ManualSortApplyReport.swift`, pluralise par substitution au catalogue (`manual_sort.report.*`) et documente explicitement qu'il ne reproduit pas ce défaut |
| D39 | `C3 · Rangement proposé` (`80:2708`) | **Divergence côté Figma.** Le frame d'onboarding était déjà périmé face au code livré : résumé « 5 étagères pour 24 livres » que le code n'avait pas, CTA « Créer les 5 étagères » là où le code disait « Créer ces étagères », aucun bouton **Annuler**, rangs `Cell / List` au lieu des livres de chaque étagère | **aggravée** — l'issue 0043 a supprimé `AutoSortPlanView` : le frame ne décrit plus un écran périmé, il décrit un écran qui n'existe pas. Le CTA de C2 mène désormais à la surface de tri (`ManualSortView`), maquettée plus bas sous « Tri manuel ». Frame **conservé**, à remaquetter lors d'une passe de design — ne pas le supprimer |
| D40 | `Icon` (`21:60`), variante `Glyph=line.3.horizontal` | **Divergence côté Figma.** La variante avait été posée à (0, 0), superposée à `Glyph=book` : les deux se chevauchaient dans le jeu, invisible tant qu'on n'ouvre pas le composant | résolue — passe 0036, la variante a reçu sa case (0, 192) et le jeu a été redimensionné |
| D41 | `Features/AutoSort/AutoSortApplyReport.swift` — branche `.allLanded` | Le registre déclarait explicitement qu'un registre **vide** vaut `.allLanded` (« there was nothing to create and nothing failed, which is a finished run »), mais le rapport rendait alors « **0 étagère a été créée et remplie.** » | **résolue par suppression** — le fichier a été supprimé par l'issue 0043. Le cas qu'elle anticipait — appliquer une pile qui se coalesce à rien — est un cas normal sur la surface de tri, et `ManualSortApplyReport` le traite : `landedCount == 0` rend `manual_sort.report.nothing_to_save`. Le registre lui-même a été déplacé et renommé `SortApplyLedger` (`Model/Sorting/`) |
| D42 | `AutoSort / Book Row` (`100:229`) vs `Features/Sorting/SortBookRow.swift` | **Divergence assumée côté code.** Le composant porte une ligne de genre sous l'auteur, et le code la rendait (`primaryGenre`). La donnée réelle vient des claims Wikidata `wdt:P136`, qui remontent des libellés comme « **Figure d'autorité** » : une ligne qui ne dit rien du livre et se lit comme un bug. Ligne supprimée du rang ; le pipeline continue d'utiliser le genre pour *décider* où va un livre | ouverte côté Figma — le composant décrit un rang que l'écran ne dessine plus. À trancher en passe de design : soit retirer la ligne du composant, soit attendre une source de genre digne de confiance |
| D43 | `AutoSort / Book Row`, propriété `Show handle` | **Divergence assumée côté code.** La poignée du composant n'est plus dessinée par l'app : la liste est tenue en mode édition et c'est **la poignée système** qui la remplace, avec son lever, son animation et sa zone de saisie. Une poignée maison à côté aurait fait deux prises pour un seul geste | ouverte côté Figma — la propriété décrit un élément que l'app ne dessine plus, mais le rendu à l'écran est équivalent |
| D44 | `Tri manuel · Glissement` (`135:3934` / `136:4110`), `Tri manuel · Dépôt sur étagère vide` (`137:4286`) | **Frames périmés, conservés.** Ils maquettaient le drag maison — rang soulevé en `Shadow/Pressed`, emplacement libéré en `background/disable`, bande teintée en cible. Ce drag ne prenait pas sur appareil et a été remplacé par le reorder natif de `List` : le lever, le trou et la surbrillance sont ceux du système et ne sont pas stylables. Le point ouvert sur `background/disable` = `gray/600` en sombre tombe avec eux | périmés — renommés `Superseded (PRD 0009) · …` dans le fichier, **à ne pas supprimer** : ils documentent une intention. Le geste est redevenu un drag applicatif (`draggable` / `dropDestination`, PRD 0009), mais le lever, l'aperçu et le dépôt restent ceux du système et ne sont pas stylables — donc toujours pas à remaquetter tel quel |
| D45 | `Ranger mes livres · Light` (`160:6659`) vs `SortGridMetrics` | **Divergence assumée côté code.** La maquette pose les cartes d'étagère à 112,33 avec une gouttière de **12** ; le code applique la formule de l'owner — `3W + 4 × 16 = largeur`, soit **109,67 et une gouttière de 16**. Les cartes livre, elles, suivent la maquette : 100,33, gouttière 12, plus un peek de 40 qui annonce le défilement du carrousel | ouverte côté Figma — arbitrée en faveur du code par l'owner (PRD 0009). À reprendre en passe de design : soit la maquette passe à 16, soit le code revient à 12 |
| D46 | `Ranger mes livres · Light`, `+` de la barre de navigation | **Divergence assumée côté code.** La maquette met la création d'étagère dans la nav bar ; le code l'a déplacée en **dernière tuile de la grille** — à l'endroit où le geste s'utilise, et elle sert en même temps d'état vide et de cible de dépôt (déposer un livre dessus crée l'étagère et le range). Une action, un contrôle | ouverte côté Figma — les frames ajoutés en 0045 montrent la tuile ; le frame nominal garde le `+` |
| D47 | `Ranger mes livres · Light`, titre de carte vs `TextStyle` | **Diagnostic erroné, refermé.** J'avais écrit qu'aucun token serif n'existait à la taille du titre de carte : `Footnote/footnote200Bold` **est** une Alegreya Bold 12, et c'est exactement ce que la maquette applique. Aucun écart. Le titre des cartes « livre à ranger », lui, est `Content/content300` (Alegreya Medium 17) sur deux lignes, et le code le rendait en 12 — corrigé côté code | résolue — rien à changer côté Figma |
| D48 | `Ranger mes livres`, frames d'états | **Écart de production, résolu.** Les 12 frames d'états manquants ont été générés depuis les décisions du PRD 0009 en clonant le frame nominal, donc à partir des mêmes composants et des mêmes variables. Les pastilles instancient bien `Tag` sans glyphe (`Show glyph = false`), comme le code | résolue — frames à relire par l'owner ; le détail d'étagère (`Détail étagère · Light`) est le seul écran de la feature qui n'avait aucune maquette |
| D49 | `border/default` (variable Figma) vs `DesignSystem.Color.borderDefault` | **Divergence assumée côté code.** La variable Figma résout `gray/200` en clair et `gray/700` en sombre — deux gris opaques. Le code rend désormais **noir à 10 %** et **blanc à 10 %**, donc un voile et non une couleur. La raison : un gris opaque ne se lit comme un bord que sur un seul fond. `gray/200` est légèrement vert (il porte la teinte de marque dans les gris, cf. la note sous les primitives), et sur le lavis d'une étagère ou sur le blanc semi-opaque du panneau de tri il se lisait comme un **trait dessiné** au lieu d'une arête. C'est ce qui avait poussé le filet du panneau de tri à être écrit en `Color.black.opacity(0.2)` en dur, hors token — un contournement maintenant supprimé, le token faisant le travail. Conséquence : `border/default` est le seul alias de la bibliothèque qui ne pointe pas sur une primitive `color/*`, et il n'a pas de hex fixe | ouverte côté Figma — la variable doit passer à une couleur avec alpha (noir 10 % / blanc 10 %) ; aucune primitive existante ne convient, donc soit deux primitives `color/black 10%` / `color/white 10%`, soit une valeur brute sur l'alias |

Rappel historique de la passe tokens : **D6 était la priorité** — `OpenSans-SemiBold` et `OpenSans-Regular` ne s'enregistraient
pas au lancement, donc `action200`, `action300` et `caption200` retombent sur la police système sur l'appareil.

---

# Onboarding — propositions (passe du 2026-08-20)

Section `Onboarding` (`73:2829`) sur la page `Screens`. Trois propositions pour la mise en route « inventaire vide →
scanner par lot → rangement automatique ». **Exploration, pas une passe de réplication** : ces frames ne miroitent
aucun écran Swift existant, sauf l'écran de rangement, qui approximait `Features/AutoSort/AutoSortPlanView.swift`
— supprimé depuis (issue 0043), ce qui périme `C3` sans le rendre inutile : voir D39.

**La proposition C est retenue** (2026-08-20). A et B restent dans la section, marquées « écartée », comme trace des
arbitrages — ne pas les supprimer sans supprimer aussi les panneaux qui les expliquent.

## C · Deux plein-écrans — retenue

| Frame | id | Rôle |
|---|---|---|
| `C1 · Bienvenue` | `80:2852` | Premier lancement, inventaire vide. CTA « Scanner mes livres », échappatoire « Plus tard » |
| `C1 · Bienvenue · Sombre` | `87:3011` | Mode épinglé `Dark`, chrome en `Theme=Dark` |
| `C1b · Après « Plus tard »` | `87:2880` | Où l'invitation retombe : le mot sur la planche, une seule ligne à cocher |
| `C2 · Bilan du scan` | `80:2895` | À la fermeture du scanner. Titre = compte de la session, CTA « Ranger mes livres » |
| `C2 · Bilan du scan · Sombre` | `87:3064` | idem, mode `Dark` |
| `C2b · Rangement indisponible` | `87:2960` | Apple Intelligence désactivée : la raison est dite, CTA vers les Réglages |
| `C3 · Rangement proposé` | `80:2708` | **Périmé (2026-08-21, issue 0043)** : miroitait `AutoSortPlanView`, écran supprimé. La cible du CTA de C2 est désormais la surface de tri (`ManualSortView`), maquettée sous « Tri manuel ». Frame conservé — voir D39 |
| `Commun · Scanner par lot (existant)` | `81:2847` | Clone de `57:2401`, non modifié |
| `Spec · C` | `81:2891` | Déclencheurs, flags, cas d'indisponibilité, ce qui reste à trancher |

`C1b` et `C2b` n'ont pas de variante sombre : ce sont des états dérivés, à décliner au moment de l'implémentation.

Les panneaux des propositions écartées : A `81:2863`, B `81:2877`. Frames de A `76:2241` `76:2253` `80:2596`,
frames de B `76:2265` `76:2277` `80:2690`.

## Ce que la construction a appris

- **On ne peut pas déplacer un enfant d'instance** : `set_y` sur un sous-nœud d'instance renvoie
  `This property cannot be overridden in an instance: relative-transform`. Le mot papier de `Shelf Empty Card` est
  donc **masqué** (`visible = false`, override autorisé) et la liste à cocher est redessinée dans la frame, tokens
  bindés (`shelf/label/paper`, `shelf/label/ink`, style `Shadow/Light`).
- Les frames d'écran de ce fichier n'ont **pas d'auto-layout** : leurs enfants sont posés en absolu. Insérer un
  encart veut dire décaler à la main tout ce qui est sous lui, chrome exclu.
- `Shelf Card` (`Paint=Illustrative`) sert d'illustration d'accueil, **label masqué** : sans ça elle annonce
  « Classiques français » sur un écran de bienvenue.
- Une variante sombre s'obtient en clonant, en épinglant le mode `Dark` sur la frame, puis en passant les instances
  de chrome en `Theme=Dark`. Tout le reste suit, parce que tout est bindé.
- Le glyphe `xmark` n'existe pas dans `Icon` (`21:60`). Sans objet pour C, mais c'est ce qui a privé le bandeau de B
  d'une croix de fermeture.


---

# Ranger mes livres — résultat (passe du 2026-08-20, `extract-screens`)

Section `Ranger mes livres` (`97:3755`) sur la page `Screens`. **Une réplication**, pas une exploration : ces deux
frames miroitent `Features/AutoSort/AutoSortPlanView.swift` dans sa phase `.applied`, résultat `allLanded` — la même
liste que la revue, marques cochées, rapport au pied. Le code n'a pas d'écran de progression séparé : c'est ce qui
fait qu'un échec partiel s'explique tout seul.

> **Frames périmés depuis le 2026-08-21 (issue 0043) — conservés, pas supprimés.** L'écran qu'ils miroitent a été
> retiré : la revue, son application et son registre ont disparu, et le rangement se fait désormais sur la surface de
> tri (`Features/Sorting/ManualSortView.swift`, PRD 0008), seul écran de l'app à créer des étagères et à les remplir.
> Ce qui suit décrit donc un écran mort. Il reste ici pour deux raisons : c'est la trace d'une passe de réplication
> conforme au code de son jour, et la surface de tri lui **reprend** l'essentiel — la marque par étagère, le rang de
> livre et le rapport de fin, tous trois maquettés à partir d'ici. La section « Tri manuel » plus bas décrit l'écran
> vivant ; c'est elle qui fait foi. Ne pas remaquetter ces deux frames à l'identique.

## Table des écrans

| Écran | Clair | Sombre | Panneau | Source Swift |
|---|---|---|---|---|
| **Ranger mes livres · Résultat** — **périmé, écran supprimé** | `103:3008` | `105:3107` | `108:3181` | à l'époque `AutoSort/AutoSortPlanView.swift` + `AutoSortBookRow.swift` + `AutoSortShelfMark.swift` + `AutoSortApplyReport.swift` ; **plus aucune source Swift** depuis l'issue 0043. Équivalents vivants : `Sorting/ManualSortListView.swift` + `SortBookRow.swift` + `ManualSortShelfMark.swift` + `ManualSortApplyReport.swift` |

Audit de factorisation : **0 dessin brut**, 0 texte sans style, 25 instances par frame, mode épinglé sur chacun.
Les quatre `▢` de tête sont des conteneurs assumés (`list group / …`), un par `Section` encartée.

## Composants ajoutés — `Screens · Components`

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `AutoSort / Shelf Header` | `100:228` | — | `Name#100:0`, `Count#100:1` | à l'époque le `header:` du `Section` par étagère de `AutoSortPlanView.planList` ; désormais `Sorting/ManualSortSectionHeader.swift` — le composant survit à l'écran, c'est le tri manuel qui le porte |
| `AutoSort / Book Row` | `100:235` | — | `Title#100:2`, `Authors#100:3`, `Show authors#100:4`, `Genre#100:5`, `Show genre#100:6` | `Sorting/SortBookRow.swift` (ex-`AutoSort/AutoSortBookRow.swift`, déplacé par l'issue 0043 : la surface de tri en est le seul lecteur) |
| `AutoSort / Note` | `101:236` | Style ∈ {Content, Footnote} × Tone ∈ {Default, Secondary} | `Body#101:0` | les `Section { Text }` isolées : rapport, reste sans étagère, propositions écartées |

`AutoSort / Book Row` est délibérément **distinct de `Cell / Book`** : rien n'est encore rangé, donc ni état de
transaction, ni disponibilité, ni navigation. Le genre y est en `foreground/tinted` parce qu'il est la **raison** du
classement — c'est ce qui permet de dire si c'est le genre ou la correspondance qui a fauté.

`AutoSort / Shelf Header` ne portait à cette passe **que la marque `landed`** : `applying` est un spinner (non
maquetté, convention du fichier) et `pending` / `failed` demandaient deux glyphes absents d'`Icon` (`21:60`). La
passe 0036 les a ajoutés et a ouvert la marque par une propriété `Mark glyph#133:0` (`INSTANCE_SWAP`) plutôt que par
un axe de variantes — voir plus bas. Les trois marques approximent les symboles `.fill` du code par leur version au
trait, seule forme que le jeu porte.

## Variante ajoutée à un composant existant

`Chrome / Nav Bar` (`26:162`) gagne **`Style = Inline + Back + Text action`** (`102:224` clair, `102:235` sombre) et
la propriété **`Action label#102:6`**. C'est la forme d'un `ToolbarItem(placement: .primaryAction) { Button("Terminer") }` :
une action de fin de ligne en **texte** teinté, pas un glyphe. Le titre y est réduit à 197 pt (x = 98, centré sur le
frame) pour ne pas passer sous le libellé. Les trois anciens `Style` et leurs clés de propriété sont inchangés — les
instances déjà posées sur les 16 frames n'ont pas bougé.

## Recette de composition

Fond `background/secondary` (`.applyListBackground()`), puis, en absolu : en-tête d'étagère (31) · `list group` de 361
à `radius/medium` contenant les `AutoSort / Book Row` (87) séparés par `Separator` · gap de 12 entre l'encart et
l'en-tête suivant, de 20 entre deux encarts · notes encartées (47 sur une ligne, 70 sur deux) · chrome posé **en
dernier**. Barre d'onglets sur `Inventaire` — l'entrée par la carte d'étagère vide ; l'écran est aussi atteignable
depuis Réglages.

Une `Section` de List encartée est un **encart** : la note du rapport est donc dans un `list group`, pas posée nue.
Un `footer:` de section, lui, se dessine nu — c'est le cas du « Rien n'a encore été créé… » de l'état proposition.

## Ce qui n'est pas maquetté

| Absent | Pourquoi |
|---|---|
| `.applying` | Spinners et états transitoires, non maquettés par convention du fichier |
| Le rapport partiel (`stopped`) | Demande les marques `pending` et `failed`, donc deux glyphes à ajouter à `Icon` d'abord |
| `.failed` (« Le rangement n'a pas pu être proposé ») et le mur d'indisponibilité | Hors du périmètre demandé ; `AutoSortUnavailableView` a trois messages, un par raison. **Le mur n'existe plus** (issue 0043) : l'indisponibilité est devenue une phrase à côté du bouton de proposition du tri manuel, `ManualSortProposalButton` |
| La section « propositions écartées » | N'apparaît que si le validateur a rejeté une correspondance |
| L'état `plan.isEmpty` | Une seule phrase, portée par `AutoSort / Note` Content/Secondary — à poser le jour où il est utile |

Les couvertures des huit vignettes sont **la même image** que les écrans voisins, posée en override d'instance : un
seul visuel pour tous les livres, ce n'est pas une donnée.

## Ce que la construction a appris

- **Les glyphes d'`Icon` sont dessinés au trait, pas au remplissage.** Leurs vecteurs portent un `stroke` bindé à
  `foreground/default` et **aucun fill**. Teinter une icône veut donc dire remplacer le `stroke` ; poser un `fill`
  bouche le cercle et fait disparaître la coche — ce qui ne se voit qu'à la capture.
- **`clone()` d'une variante perd ses `componentPropertyReferences`** en entrant dans le `COMPONENT_SET`. La
  propriété existait, l'instance la portait à la bonne valeur, et le texte affichait quand même l'ancien libellé. Il
  faut réattribuer `{ characters: 'Title#26:18' }` à la main après le `appendChild`.
- En revanche, `set.addComponentProperty` **ne renomme pas** les clés existantes : ajouter une variante et une
  propriété à un composant déjà consommé par 16 frames est sûr. C'est `combineAsVariants` qui réattribue, pas
  `appendChild`.
- Une peinture bindée **suit bien le mode épinglé à travers une instance**, y compris sur un `stroke` d'icône : le
  clone sombre a résolu `foreground/tinted` en `green/200` sans retouche. Le piège 4 ne concerne que les overrides
  posés avec une base littérale incohérente.


## Tri manuel — proposition (2026-08-20)

Dérivé de l'écran de résultat, dans la même section. **Rien de tout ceci n'existe dans le code** : c'est une
proposition de design, pas une réplication. La liste cesse d'être une revue et devient une surface de travail —
on range à la main, sans modèle.

| Frame | id |
|---|---|
| `Tri manuel · Light` | `115:3276` |
| `Tri manuel · Dark` | `120:3636` |
| `Tri manuel · Appliqué · Light` | `126:3672` |
| `Spec · Tri manuel` | `117:3526` |

Neuf frames de plus ont rejoint la section le soir même — le glissement, la cible de dépôt, la synchronisation
d'ouverture, « À ranger » vide et l'échec partiel : voir [Les cinq états jamais dessinés](#passe-du-2026-08-20-issue-0036--les-cinq-états-jamais-dessinés).

**Spec fonctionnelle : [docs/prd/0008-manual-shelf-sorting.md](../prd/0008-manual-shelf-sorting.md)** — le modèle de
diff, les états, les cas limites et les questions ouvertes vivent là, pas ici.

Ce que la proposition ajoute à l'écran de résultat :

- une section **« À ranger »** qui se comporte comme une étagère mais n'en est pas une — en dernier, sans marque,
  et le tas se vide vers le haut au fil du rangement ;
- une **poignée de déplacement** à droite de chaque rang, « À ranger » compris : le glissement est symétrique, on
  sort un livre d'une étagère aussi bien qu'on l'y met ;
- un **« + »** dans la barre de navigation pour créer une étagère à la volée ;
- **« Terminer »** en **barre épinglée** au bas de l'écran, à la place qu'il occupait dans la barre de navigation.

Le genre est masqué dans « À ranger » : ces livres sont sans étagère faute de genre connu, l'afficher vide dirait
deux fois la même chose.

### Ajouts au système

| Ajout | node id | Défaut | Pourquoi ce défaut |
|---|---|---|---|
| Glyphe `line.3.horizontal` dans `Icon` | `112:232` | — | La poignée de déplacement. 16e variante du jeu |
| `Show handle` sur `AutoSort / Book Row` | `Show handle#113:0` | **false** | Les frames de résultat miroitaient le code livré, qui n'avait pas de glisser-déposer. Le défaut reste ce qu'il est, les frames de résultat étant conservés — mais le seul écran vivant qui pose ce composant, le tri manuel, le met à `true` partout |
| `Show mark` sur `AutoSort / Shelf Header` | `Show mark#113:1` | **true** | L'écran de résultat portait la marque ; le tri manuel l'éteint partout |
| `Bottom Action Bar` | `114:231` | — | Barre d'action épinglée : `background/default`, filet `border/default` en haut, `Button / Large` Primary en pleine largeur. 393 × 83, se pose à y = 686 |

Les deux booléens sont **défaut-neutres par construction** : ajoutés avec le défaut qui laisse les six instances
déjà posées sur `Résultat · Light` / `· Dark` exactement comme elles étaient. Vérifié à la capture, pas seulement au
raisonnement.

### Décisions de design, et leur revers

- **« Terminer » quitte la List.** `AutoSortPlanView` gardait délibérément son action *dans* la liste pour que les
  marques restent le récit principal (écran supprimé depuis, issue 0043 — l'argument, lui, tient toujours, et c'est
  celui que le code du tri manuel a finalement retenu : voir `ManualSortListView`). Ici il n'y a plus de marques, la liste se réordonne à chaque geste, et une
  action posée au pied s'éloigne à mesure qu'on travaille. D'où la barre épinglée — et le revers assumé : deux
  barres empilées au bas de l'écran, 166 pt de chrome.
- **Le « + » prend la place de « Terminer »** dans la barre de navigation. Les deux ne coexistent jamais : c'est ce
  qui rend le déplacement nécessaire plutôt que cosmétique.
- **Le contenu défile sous la barre d'action, jamais sous la barre de navigation.** Le composant de nav est
  translucide : la première composition faisait passer une carte dessous et le rang fantômait derrière le titre.

### À trancher avant de coder

- **`onMove` ne traverse pas les sections d'une `List`.** Un glisser-déposer d'une étagère à une autre impose
  `.draggable` / `.dropDestination` avec un transfert typé, pas un mode édition. C'est la contrainte qui décide de
  la faisabilité, et elle n'est pas visible dans la maquette.
- Même écran que le résultat d'auto-sort une fois le rangement appliqué (les marques s'éteignent, les poignées
  s'allument), ou écran distinct atteignable sans avoir rien lancé ? Et dans le premier cas, que devient le rapport
  « 2 étagères ont été créées et remplies » ?
- Une écriture par dépôt, ou une seule à « Terminer » ? La première suit l'optimisme de l'ADR 0001 ; la seconde fait
  de « Terminer » une vraie validation, et impose de savoir ce qu'un abandon annule.

### Non maquetté

*(état à la passe du 2026-08-20 matin ; cinq de ces états ont été dessinés le soir même — voir « Les cinq états
jamais dessinés » plus bas. Reste non maquetté : la feuille de création derrière le « + », la proposition en cours de
génération, et l'état `.applying` d'une étagère.)*

Le rang en cours de glissement (soulevé, ombre, emplacement d'accueil) · la section survolée comme cible de dépôt ·
la feuille de création derrière le « + » · « À ranger » vide, où la section devrait disparaître · l'inventaire
entièrement rangé.


### Passe du 2026-08-20 (soir) — étagères existantes et indicateur d'état

Deux changements de fond après relecture, dont un venu de l'utilisateur directement dans le fichier.

**Ce que l'utilisateur a changé dans la maquette** — repris tel quel, c'est son arbitrage :

- le frame devient un **canevas de défilement** de 393 × 1540 (et non un viewport de 852) : tout le contenu est
  visible d'un coup, la tab bar est calée en bas du canevas ;
- le contenu passe dans un conteneur **auto-layout vertical, gap 14, enfants centrés** — d'où les encarts à 361 sans
  `x` explicite. Une section s'insère maintenant par `insertChild`, sans recalculer un seul `y` ;
- `Bottom Action Bar` (`114:231`) porte **deux** `Button / Large` — Primary « Créer ces étagères » puis Secondary
  « Annuler » — et redescend **dans le flux** de la liste, au pied. La barre épinglée est abandonnée.

**Ce que cette passe ajoute :**

| Ajout | id / clé | Défaut |
|---|---|---|
| `Show tag` sur `AutoSort / Shelf Header` | `Show tag#119:0` | **false** |

La pastille est une instance du `Tag` du design system (`23:23`), pas un badge nouveau. Trois états, posés en
override sur l'instance :

| État | Pastille |
|---|---|
| Étagère déjà sur le serveur, intacte | *aucune* |
| Étagère à créer | « Nouvelle », `Color=Tinted` |
| Étagère existante dont le contenu a bougé | « Modifiée », `Color=Secondary` |

**C'est l'absence qui porte l'état normal** : le diff se lit sans rien compter. Les deux pastilles sont dérivées du
diff au rendu — jamais stockées — donc une pastille ne peut pas mentir sur ce que fera le bouton, et sortir un livre
puis le remettre l'éteint.

La maquette montre désormais cinq sections : deux étagères `Nouvelle` issues d'un auto-sort, une existante marquée
`Modifiée`, une existante sans pastille, puis « À ranger ». La note encartée n'est plus le rapport d'un rangement
passé mais le **récapitulatif du diff à enregistrer**, en toutes lettres, juste au-dessus des boutons.

Le frame sombre a été **reconstruit** depuis le clair (l'ancien `116:3430` est supprimé) : il avait divergé pendant
les retouches. Reconstruire un jumeau sombre coûte un clone, un mode épinglé et quatre `Theme=Dark` — moins cher que
de rejouer les modifications des deux côtés.


### Passe du 2026-08-20 (fin) — trois boutons et l'état « appliqué »

Après une session de grilling, l'écran change de nature : il n'y a plus un écran de revue et un écran de tri, mais
**un seul écran** dont l'entrée est « état initial + changements IA optionnels » et dont l'état de travail est une
**pile de changements**. L'IA devient un générateur de changements comme le doigt de l'utilisateur. L'architecture
complète est dans [docs/prd/0008-manual-shelf-sorting.md](../prd/0008-manual-shelf-sorting.md) ; seules ses
conséquences visuelles sont ici.

`Bottom Action Bar` (`114:231`) porte maintenant **trois** `Button / Large` :

| Bouton | Style | Rôle |
|---|---|---|
| « Proposer un rangement » | Secondary | Empile les changements de l'IA. **N'écrit rien** |
| « Appliquer le rangement » | Primary | Exécute la pile |
| « Annuler » / « Terminer » | Secondary | Voir la règle ci-dessous |

**Le libellé du troisième bouton est dérivé de `changes.isEmpty`**, pas d'un drapeau collant :

- pile non vide → primaire actif, troisième bouton **« Annuler »** (jette la pile) ;
- pile vide → primaire **désactivé**, troisième bouton **« Terminer »** (ferme l'écran).

Un apply réussi vide la pile, donc « Terminer » apparaît tout seul — et si l'utilisateur reprend le tri, il redevient
« Annuler », ce qui est vrai. C'est ce que montre `Tri manuel · Appliqué · Light` (`126:3672`) : plus aucune pastille
(rien n'est en attente), la note encartée passe du récapitulatif au rapport, le primaire est en `State=Disabled`, le
troisième dit « Terminer ».

Le mur d'indisponibilité d'Apple Intelligence disparaît de la maquette : il n'y a plus qu'un bouton, qui peut être
absent ou inerte. Sur un appareil qui ne peut pas faire tourner le modèle, l'écran reste entièrement utilisable.


### Passe du 2026-08-20 (issue 0036) — les cinq états jamais dessinés

Cinq états de la surface de tri n'existaient dans aucune maquette, dont deux qui **sont** la sensation de la
fonctionnalité : le rang pendant qu'on le glisse, et la section sous le doigt. Ils sont dessinés à côté des trois
frames existants, dans la même section `Ranger mes livres` (`97:3755`).

**Rien de tout ceci n'existe dans le code** — comme le reste du tri manuel, c'est une proposition de design. La spec
fonctionnelle reste [docs/prd/0008-manual-shelf-sorting.md](../prd/0008-manual-shelf-sorting.md).

#### Les frames

| Frame | id | Mode | Ce qu'il tranche |
|---|---|---|---|
| `Tri manuel · Synchronisation · Light` | `134:3832` | Clair | L'aller-retour serveur d'ouverture **bloque tout l'écran**. Viewport 393 × 852 (et non un canevas : il n'y a rien à faire défiler), `Syncing Placeholder` sur toute la zone de contenu, et **le « + » de la barre de navigation est absent** tant que l'instantané n'existe pas |
| `Tri manuel · Synchronisation · Dark` | `134:3899` | Sombre | idem |
| `Tri manuel · Glissement · Light` | `135:3934` | Clair | Le rang soulevé, le trou qu'il laisse, et la section remplie survolée comme cible |
| `Tri manuel · Glissement · Dark` | `136:4110` | Sombre | idem |
| `Tri manuel · Dépôt sur étagère vide · Light` | `137:4286` | Clair | Le même geste au-dessus d'une étagère créée à la volée, **encore vide** : son encart porte une note, donc une hauteur à viser |
| `Tri manuel · Tout rangé · Light` | `139:4469` | Clair | « À ranger » vide : **la section reste**, une note à la place des rangs, compte à « 0 livre » |
| `Tri manuel · Tout rangé · Dark` | `140:4652` | Sombre | idem |
| `Tri manuel · Échec partiel · Light` | `142:4835` | Clair | Le rapport en **trois** parties, plus une marque par étagère : posée, échec, en attente, rien |
| `Tri manuel · Échec partiel · Dark` | `143:5022` | Sombre | idem |

`Dépôt sur étagère vide` n'a **pas** de jumeau sombre, et c'est délibéré : la teinte de survol et l'ombre du rang
soulevé sont déjà prouvées par le couple `Glissement`, ce frame n'ajoute qu'une variante de cible. Même raisonnement
que `C1b` / `C2b` de la passe onboarding.

Le panneau `Spec · Tri manuel` (`117:3526`) est étendu de six blocs — les cinq états, la décision sur « À ranger »
vide, le vocabulaire des marques, les trois parties du rapport, et trois points à trancher. Sa liste « états non
maquettés » a été réécrite au lieu d'être laissée périmée.

#### Le rang soulevé, et le trou

Le rang quitte le flux de la liste et se pose **en absolu sur le frame**, entre le contenu et le chrome : il prend
`background/default`, `radius/medium`, l'ombre `Shadow/Pressed`, et se décale de 10 pt vers la droite. Sa place
devient un conteneur nommé `emplacement libéré / <titre>`, à la hauteur exacte du rang, rempli en
`background/disable`.

**Le compte de l'en-tête ne bouge pas.** Rien n'est déposé tant que le doigt n'a pas lâché ; un compte qui changerait
en vol mentirait sur ce qui est acquis.

L'ombre **réutilise `Shadow/Pressed`** (0, 2, flou 8) faute d'ombre de lévitation dans le système. Le raccourci se
défend — un glissement commence par un appui — et surtout : aucun symbole Swift ne porte d'élévation de ce genre, donc
inventer un style d'effet ici aurait été inventer un token que le code ne réclame pas. À revoir le jour où il le
réclamera.

#### La cible de dépôt

La section survolée passe **entière** en `background/tinted`, filets haut et bas en `border/tinted`, en-tête compris :
c'est la **section** qui reçoit, pas une ligne. Le dépôt entre dans une étagère, jamais entre deux rangs — l'ordre à
l'intérieur d'une étagère n'existe pas dans le modèle, donc un emplacement d'insertion inter-rangs promettrait quelque
chose que l'écriture ne sait pas tenir.

Sur une **étagère vide**, l'encart n'est jamais réduit à rien : il porte une note « Cette étagère est encore vide.
Déposez un livre ici pour la remplir. » Sans elle, une étagère neuve serait une cible de dépôt de 0 pt de haut.

#### « À ranger » vide — la décision

La PRD laissait le choix ouvert. **La section reste**, avec une note à la place des rangs et un compte à « 0 livre ».
Trois raisons :

1. c'est la seule cible qui **sort** un livre d'une étagère — la faire disparaître supprimerait la moitié de la
   symétrie que la poignée promet sur tous les rangs ;
2. le dernier dépôt ferait s'évanouir une section entière sous le doigt, exactement le saut que le retour de survol
   existe pour éviter ;
3. un compte à zéro est la seule **preuve** que le travail est fini ; une section absente ne prouve rien, elle
   ressemble à un bug.

Le prix, assumé : une section qui ne contient rien reste à l'écran.

Détail du même frame : les livres rangés à la main gardent leur **genre masqué** une fois sur l'étagère. Ils étaient
sans étagère faute de genre connu, et c'est le doigt qui les a classés — la colonne de genres se lit donc comme la
trace de ce que le modèle a su faire.

#### Le rapport d'échec partiel

Trois parties, jamais deux, exactement comme `SortApplyLedger.Result.stopped` (ex-`AutoSortApplyProgress`,
déplacé en `Model/Sorting/` par l'issue 0043) :

| Sortie | Copie de la maquette |
|---|---|
| Créée **et remplie** | « Créée et remplie : Romans classiques. » |
| Créée **sans ses livres** | « Échec sur Science-fiction et fantasy : l'étagère a été créée, mais ses livres n'y sont pas encore. » |
| **Jamais créée** | « Non traitée : Bandes dessinées. » |

La deuxième ne se replie pas sur « non créée » : rien n'est annulé, donc l'étagère est peut-être là, vide, et
l'utilisateur irait la chercher. Le sens venait de `AutoSortApplyReport.swift`, supprimé depuis (issue 0043) ;
**la forme, non** — les phrases sont
écrites pour se lire au singulier comme au pluriel, la règle de pluriel devant venir du catalogue et non d'une
ternaire dans l'interpolation (D38, délibérément non reproduite).

Après l'arrêt, **les pastilles redisent la vérité toutes seules**, sans cas particulier : `Romans classiques` a atterri
→ plus de pastille ; `Science-fiction et fantasy` existe désormais mais son contenu diffère encore → `Modifiée` ;
`Bandes dessinées` n'a pas été touchée → `Modifiée`. La pile n'est pas vide, donc le primaire reste actif et le
troisième bouton dit toujours « Annuler ». Rien à ajouter au règlement des boutons.

#### Ajouts au système

| Ajout | id / clé | Défaut | Pourquoi ce défaut |
|---|---|---|---|
| Glyphe `circle` dans `Icon` | `132:235` | — | La marque `pending`. Le cercle de `checkmark.circle`, sans la coche : géométrie et bindings identiques par construction |
| Glyphe `exclamationmark.circle` dans `Icon` | `132:239` | — | La marque `failed`. Le même cercle + barre et point importés en SVG, `stroke` bindé à `foreground/default` comme les 17 autres |
| `Mark glyph` sur `AutoSort / Shelf Header` | `Mark glyph#133:0` (`INSTANCE_SWAP`) | **`21:55` = `checkmark.circle`** | Le défaut est la marque que l'écran de résultat porte déjà : les six instances posées sur `Résultat · Light` / `· Dark` n'ont pas bougé |

`Icon` (`21:60`) passe donc à **18 variantes**, et le nombre de composants reste à **29** — aucun composant nouveau,
seulement deux variantes et une propriété.

**Pourquoi une propriété `INSTANCE_SWAP` et pas un axe de variantes `Mark`.** Passer `AutoSort / Shelf Header` en
`COMPONENT_SET` demande `combineAsVariants`, qui **réattribue les clés de propriété** — et le composant est déjà
consommé par une dizaine d'instances sur quatre frames livrés. `addComponentProperty`, lui, ne renomme rien. La
teinte de la marque se pose ensuite en override sur le `stroke` du vecteur (`foreground/tinted`, `foreground/disable`,
`foreground/error`) : les glyphes du jeu sont dessinés **au trait**, poser un `fill` boucherait le cercle.

Une étagère sur laquelle il n'y a **rien** à faire ne porte aucune marque — c'est `Poésie` sur le frame d'échec.
Une coche veut dire que la création **et** l'écriture d'appartenance ont abouti : créée sans ses livres est un échec,
pas un demi-succès.

#### Audit de factorisation — les 9 frames

**0 dessin brut** (aucun `VECTOR` / `RECTANGLE` / `ELLIPSE` / `LINE` / `TEXT` hors instance) · **0 fill ou stroke en
dur** (toutes les peintures sont bindées, y compris les overrides) · **0 texte sans style** · **0 conteneur au nom par
défaut** · **mode épinglé sur 9 frames sur 9**.

| Frame | Instances | Conteneurs nommés |
|---|---|---|
| `Synchronisation · Light` / `· Dark` | 5 | 0 |
| `Glissement · Light` / `· Dark` | 24 | 10 |
| `Dépôt sur étagère vide · Light` | 26 | 11 |
| `Tout rangé · Light` / `· Dark` | 26 | 9 |
| `Échec partiel · Light` / `· Dark` | 28 | 8 |

Les conteneurs `Frame 1` / `Frame 2` hérités du clone ont été renommés `contenu défilant` et `pied de liste` sur les
neuf frames — un conteneur au nom par défaut n'est pas un conteneur nommé. Les frames sources (`115:3276`,
`120:3636`, `126:3672`) portent encore les anciens noms ; ils n'ont pas été touchés, cette passe ajoute **à côté**.

La section `Ranger mes livres` passe à 8754 × 3247 pour les contenir. Aucun chevauchement avec `Onboarding`
(`73:2829`) ni avec les frames de premier niveau de la page.

#### Ce que la construction a appris

- **`setProperties` sur une propriété `INSTANCE_SWAP` renomme le nœud échangé.** Le `mark` devient `Icon`, et un
  `findOne(n => n.name === 'mark')` posé juste après renvoie `null`. Retrouver le sous-nœud par sa **position**
  (`header.children[0]`), pas par son nom, puis le renommer si on tient au nom.
- **Un frame cloné ne se réajuste pas.** Ajouter une section à un conteneur en auto-layout allonge le contenu mais
  pas le canevas : la barre d'onglets se retrouve **au milieu** de la liste. Recalculer `tab.y`, `home.y` et la
  hauteur du frame après chaque insertion.
- **Un rang soulevé doit sortir du flux**, donc quitter le conteneur en auto-layout pour se poser en absolu sur le
  frame — mais **avant** le chrome dans l'ordre des enfants, sinon il passe par-dessus la barre de navigation
  translucide.
- Une variante ajoutée à `Icon` atterrit à (0, 0) si on ne lui donne pas sa case ; `line.3.horizontal` y était depuis
  la passe précédente, superposée à `book` (D40).
