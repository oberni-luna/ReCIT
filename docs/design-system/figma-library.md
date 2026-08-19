# Bibliothèque Figma — design system RECITs

Miroir Figma du design system iOS. **Le code Swift est la source de vérité** ; Figma en est le reflet.

- **fileKey** : `S7IvC6GvlcUFe5IgbtvQq6`
- **Lien** : https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits
- **Dernière passe** : 2026-08-18 — tokens, styles de texte, styles d'ombre, page `Tokens`. Aucun composant.
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
| `Color` | `VariableCollectionId:4:3` | `Light` (`4:1`), `Dark` (`4:2`) | 27 |
| `Spacing` | `VariableCollectionId:4:4` | `Value` (`4:3`) | 11 |
| `Radius` | `VariableCollectionId:4:5` | `Value` (`4:4`) | 8 |
| `Sizing` | `VariableCollectionId:4:6` | `Value` (`4:5`) | 4 |
| `Typography` | `VariableCollectionId:4:7` | `Value` (`4:6`) | 10 |
| `Opacity` | `VariableCollectionId:4:8` | `Value` (`4:7`) | 2 |

**Total : 92 variables, 10 styles de texte, 6 styles d'effet.**

Les modes clair/sombre ne vivent **pas** dans l'asset catalog : chaque `.colorset` porte une seule valeur, et la
paire light/dark est assemblée en Swift par `Color(light:dark:)` dans `DesignSystem/Tokens/Color.swift`. C'est là
qu'il faut lire les deux modes.

## Tables de tokens

### Primitives — `color/*` (source : `Assets.xcassets/color/`)

| Token | Hex | α | Consommé par |
|---|---|---|---|
| `color/gray/0` | `#FFFFFF` | 1 | `background/default` L |
| `color/gray/50` | `#F1F1F1` | 1 | `foreground/inverse` L · `foreground/default` D · `background/secondary` L |
| `color/gray/200` | `#E8ECE6` | 1 | `background/inverse` D · `background/disable` L · `border/default` L · `background/tinted-inverse` D |
| `color/gray/400` | `#AFAFAF` | 1 | `foreground/disable` L · `foreground/secondary` D · `foreground/placeholder` L |
| `color/gray/500` | `#959A92` | 1 | — inutilisé |
| `color/gray/600` | `#7E837C` | 1 | `foreground/secondary` L · `foreground/disable` D · `background/disable` D |
| `color/gray/700` | `#2D2D2D` | 1 | `border/default` D · `background/error` D |
| `color/gray/700 75%` | `#2D2D2D` | **0.50** | — inutilisé · **le nom ment** (voir D1) |
| `color/gray/800` | `#2A2A2A` | 1 | `background/secondary` D |
| `color/gray/900` | `#191919` | 1 | `foreground/default` L · `foreground/inverse` D · `background/inverse` L |
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
| `border/default` | `gray/200` | `gray/700` | `.borderDefault` |
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
| `shadow/lying-book` | noir 22 % | `Color.black.opacity(0.22)` |
| `shadow/spine` | noir 45 % | `Color.black.opacity(0.45)` |
| `shelf/parchment` | → `shelf/parchment` | `ShelfPalette.parchment` |
| `shelf/ink/dark` | → `shelf/ink-dark` | `ShelfPalette.ink(onHex:)` |
| `shelf/ink/cream` | → `shelf/ink-cream` | `ShelfPalette.ink(onHex:)` |
| `shelf/ink/fallback` | → `shelf/ink-fallback` | `ShelfPalette.ink(onHex:)` |

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

## Styles d'effet — 6 ombres

Couleur **bindée** à `shadow/*`, donc mode-aware. Le rayon SwiftUI est repris **tel quel** comme flou Figma.

| Style | x, y | Flou | Couleur | Source |
|---|---|---|---|---|
| `Shadow/Pressed` | 0, 2 | 8 | `shadow/soft` | `ScaleButtonStyle.swift:20` — **uniquement pendant l'appui** ; au repos rayon et offset valent 0 |
| `Shadow/Thumbnail` | 0, 0 | 2 | `shadow/soft` | `CellThumbnail.swift:49` |
| `Shadow/Entity Glow` | 0, 0 | 10 | `shadow/soft` | `EntityImageView.swift:22` |
| `Shadow/Painted Book` | 0, 1.5 | 1.5 | `shadow/book` | `PaintedBookView.swift:57` |
| `Shadow/Book Spine` | 0, 0.5 | 1 | `shadow/spine` | `ShelfSpineView.swift:24`, `ShelfBooksView.swift:80` |
| `Shadow/Lying Book` | 1, 2 | 3 | `shadow/lying-book` | `ShelfBooksView.swift:110` |

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
| D6 | `DesignSystem/DesignSystem.swift:24` | **Bug réel.** `registrationName` demande `"OpenSans-SemiBold"`, le fichier livré est `OpenSans-Semibold.ttf` (b minuscule). La recherche dans le bundle est sensible à la casse, donc le `guard … else { break }` se déclenche — et `break`, pas `continue`, avorte la boucle : `OpenSans-Regular` ne s'enregistre jamais non plus. `action200`, `action300` et `caption200` retombent silencieusement sur la police système | **ouverte — à corriger en priorité**, deux polices ne chargent pas en production |
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
| `Screens` | `20:4` | 16 frames d'écran + 8 panneaux de spécification |

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
| `Icon` | `21:60` | Glyph ∈ 15 valeurs | — | À consommer par `INSTANCE_SWAP`, jamais une variante par icône |

### Composites de feature

| Composant | node id | Variantes | Propriétés | Source Swift |
|---|---|---|---|---|
| `Thumbnail` | `28:163` | Size ∈ {Small 36, Medium 48, Large 64} × Shape ∈ {Minimal 4, Medium 8, Round} | — | `Components/CellThumbnail.swift` |
| `Section Header` | `28:164` | — | `Label#28:0` | 6 littéraux identiques dans le code |
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
| `Shelf Card` | `34:210` | Paint ∈ {Placeholder, Illustrative} | `Name#34:2` | `Shelves/ShelfRowView.swift` |
| `Shelf Create Card` | `34:211` | — | `Name#34:3` | `Shelves/ShelfEmptyStateView.swift` — le composant Figma porte encore l'ancien nom |
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
| D31 | `ShelvesContent.sectionTitle` | Utilise `foregroundDefault` là où les cinq autres en-têtes de section utilisent `foregroundSecondary`, et ses libellés sont des littéraux français | ouverte |
| D32 | `ReCIT_iOS.xcodeproj` | `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` alors qu'**aucun asset `AccentColor` n'existe**. Le `.tint(.foregroundTinted)` de `ReCIT.swift:31` sauve le rendu, mais le réglage pointe dans le vide | ouverte |
| D33 | `AllTransactionsView` | Ne fixe pas `navigationBarTitleDisplayMode`, donc iOS lui donne un grand titre. « Toutes les transactions » en `title200` (32 pt ExtraBold) passe à la ligne dans une barre de 96 pt | ouverte |

Rappel de la passe tokens : **D6 reste la priorité** — `OpenSans-SemiBold` et `OpenSans-Regular` ne s'enregistrent
pas au lancement, donc `action200`, `action300` et `caption200` retombent sur la police système sur l'appareil.
