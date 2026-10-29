# « Éditions » par langue, et une œuvre de 7 742 éditions qui ne gèle plus

Livré le 2026-10-29, sur `main`, en autopilot : une seule tranche, donc ni PRD ni issues. Deux commits de code — la
performance d'abord, le filtre ensuite — et celui de cette page. Maquette : la section Figma `Éditions · Filtre par
langue` (`831:7654`, page `Inventaire`) — `L1 · Éditions · En français` (`831:7657`), `L2 · Éditions · Choix de la
langue` (`831:7849`), le composant `Chrome / Menu Row · Choice` (`830:23605`) et le panneau `Spec · Éditions · Filtre
par langue` (`831:9045`).

## D'où ça part

*L'Appel de la forêt* a 7 742 éditions sur inventaire.io, et l'ouvrir gelait le téléphone. Le gel venait de la
**fiche livre**, pas de l'écran « Éditions » : pour savoir s'il fallait offrir « Autres éditions », elle insérait
toutes les éditions de l'œuvre et ne sauvait qu'à la fin, si bien que chaque recherche d'une édition parcourait les
insertions en attente. Une fois arrivé, « Éditions » comparait chaque paire d'éditions (30 millions) à chaque rendu,
et la liste restait illisible : 7 742 lignes, dont 150 en français.

## Ce que c'est

**À droite de l'en-tête « Éditions de … »**, la langue affichée, en vert, suivie d'un `chevron.up.chevron.down` :
« Français ». Le titre de gauche se tronque en fin de ligne, le libellé jamais.

**Un toucher ouvre le menu** :

- « Toutes les langues », avec le total (« 7 742 éditions ») ;
- un séparateur, puis chaque langue présente parmi les éditions, la plus fournie d'abord, nommée dans la langue du
  téléphone (« Anglais · 1 388 éditions », « Français · 150 éditions », …) ;
- un séparateur, puis « Langue non renseignée » (« 5 613 éditions ») quand des éditions n'en ont pas.

La langue affichée porte la coche. En choisir une filtre la liste sur place, tout de suite, sans rien recharger.

**Par défaut**, la langue du téléphone si l'œuvre a des éditions dans cette langue, « Toutes les langues » sinon.
Tant que personne n'a choisi, le défaut suit la synchronisation : des éditions françaises qui arrivent pendant le
chargement font passer de « Toutes » à « Français ». Le choix tient le temps de l'écran — on peut ouvrir un livre ou
« Les comparer » et revenir — et s'oublie en le quittant.

**Le bandeau des doublons** ne compte que les paires de la langue affichée (« 15 doublons probables » en français,
6 en anglais, pour *L'Appel de la forêt*), et **« Les comparer »** ne passe que celles-là (« Doublon 1 sur 6 »).

**La langue d'une édition** est la sienne, `wdt:P407`, qu'inventaire.io rend en `originalLang` (`Edition.lang`).
Elle n'est jamais devinée : la plupart des éditions Wikidata n'en ont pas, et elles vont sous « Langue non
renseignée » plutôt que sous la langue qu'elles ont sans doute.

## Ce qui a changé pour la performance

- **La fiche livre** compte les uris d'un seul appel `reverse-claims` (`EntityModel.workEditionUris(work:)`) au lieu
  d'insérer les éditions. `getWorkEditions` et `getOrFetchEditions` disparaissent.
- **La détection des doublons** (`EditionDuplicateDetector`) ne compare que les éditions qui partagent un ISBN, ou un
  éditeur et une année, et trouve les paires signalées depuis les tâches de fusion : 8 001 éditions en moins d'un
  dixième de seconde. Le résultat ne change pas.
- **L'ordre, le filtre et les doublons** sont calculés une fois par changement, hors de l'acteur principal
  (`EditionListing`), et gardés dans l'état du picker.
- **La synchronisation** (`refreshWorkEditions`) charge d'abord les éditions absentes, par lots de 50 sauvés un à un,
  si bien que la liste se remplit au fil de l'eau. Les éditions déjà connues ne sont relues qu'une fois par jour
  (`Work.editionsRefreshedAt`, optionnel, migration légère), comme les tâches de fusion — qui étaient relues à
  chaque ouverture depuis la [feature 0051](0051-edition-duplicates.md). Après une fusion, seule l'édition gardée
  est relue, par `refreshEdition` et en arrière-plan : la revue n'attend plus la synchronisation de l'œuvre.
- **La passerelle** (`WorkEditionGatewayView`) garde le picker dans une seule branche, du chargement à la liste
  complète : sans quoi il redevenait une vue neuve à l'arrivée des éditions, et oubliait la langue choisie.

## Surface technique

| Fichier | Rôle |
|---|---|
| `Model/Books/EditionLanguageFilter.swift` | `all` / `code(String)` / `unspecified` ; `admits`, `options(of:)`, `preferred(_:among:)`, `name(of:in:)`. Pur, `nonisolated` |
| `Model/Books/EditionLanguageFilterOption.swift` | une entrée du menu : la langue et son nombre d'éditions |
| `Features/EntityBrowser/Work/EditionListing.swift` | la langue résolue, le menu, l'ordre et les doublons des éditions filtrées |
| `Features/EntityBrowser/Work/EditionLanguageMenu.swift` | le libellé et le menu |
| `Features/EntityBrowser/Work/WorkEditionPicker.swift` | `chosenLanguage` (`nil` tant que personne n'a choisi), l'en-tête |
| `Features/EntityBrowser/NavigationDestination.swift` | `editionDuplicates(workUri:language:)` |
| `Features/EntityBrowser/Work/EditionDuplicatesReview.swift` | filtre les éditions avant la détection |

`EditionLanguage` existait déjà (`Model/Creation`, la langue d'une édition qu'on crée), d'où le nom
`EditionLanguageFilter`.

**Le menu est fait de `Toggle`, pas d'un `Picker`** : dans un `Menu`, la rangée d'un `Picker` ne garde que son
premier `Text`, et le compte est le sous-titre. Un `Toggle` porte la même coche ; l'éteindre ne fait rien, une langue
est toujours affichée. Les trois groupes sont trois `Section`, que le menu sépare d'un filet.

Quatre chaînes en/fr : `editions.language.all`, `editions.language.count %lld` (pluriel), `editions.language.menu %@`
(le libellé d'accessibilité, « Langue : Français ») et `editions.language.unspecified`. Identifiant
`e2e.editions.language` sur le libellé.

**Tests** : `EditionLanguageFilterTests` (le menu, l'absence de « non renseignée », le défaut, le filtre, le nom, et
`EditionListing` filtré avec ses doublons), `EditionDuplicateDetectorTests/thousandsOfEditions`,
`EditionBibliographicClaimsTests/refreshWorkEditionsWithinADay`. Suite complète verte (1 155).

## Écarts avec la maquette

- Le menu est celui d'iOS : sa matière, ses polices et sa coche, pas `Chrome / Menu Row · Choice` ni les Alegreya de
  Figma. Les comptes sont des sous-titres système.
- Le glyphe est un SF Symbol `.imageScale(.small)`, pas le `Trailing glyph` de 16 pt de `Section Header`.
- `L1` n'a pas de bandeau ; l'app le montre quand la langue affichée a des doublons.

## Non fait, non vérifié

- **Déduire la langue manquante** (du préfixe de l'ISBN, de la langue des libellés) : non, comme la spec le propose.
  5 613 éditions de *L'Appel de la forêt* restent sous « Langue non renseignée ».
- **Android** : rien de porté.
- **Vu sur le simulateur** (iPhone 17, iOS 26, sombre, français) : le libellé, le menu, le passage du français à
  l'anglais, la revue des 6 paires anglaises, le choix gardé au retour. **Pas vu** : le clair, un téléphone en
  anglais, une œuvre sans édition dans la langue du téléphone, un appareil réel.
- **La première ouverture** d'une œuvre aussi grosse lit toujours ses 7 742 éditions (155 appels `by-uris`, une
  quarantaine de secondes) : il faut leur langue pour les compter. L'écran reste utilisable pendant ce temps.
- **Le toucher d'une œuvre dans la recherche** (`WorkEditionResolver`) lit encore toutes les éditions pour choisir
  laquelle ouvrir : lent sur *L'Appel de la forêt*, mais sans gel.
- **e2e** non joué (à la demande).
