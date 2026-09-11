Title: Trois suggestions mènent aux résultats complets d'inventaire.io, depuis l'inventaire
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

Le deuxième temps et le troisième : sous la section locale de l'issue 0070, **trois suggestions
pour aller plus loin sur inventaire.io**, et l'écran de résultats complets qu'elles ouvrent.

Les suggestions, dès trois caractères, dans une section « Chercher sur inventaire.io » :

- « Livres contenant **ma requête** » — glyphe livre, `types=works`
- « Auteur·ices contenant **ma requête** » — glyphe plume, `types=humans`
- « **ma requête** » — glyphe loupe, `types=humans|works`

La requête tapée apparaît en gras dans chaque libellé. Le module pur **`SearchSuggestion`**
(`Model/SearchResult/`) construit les trois depuis la requête et porte **la correspondance entre
une suggestion et les types d'entités de la requête API** — la rangée et l'appel ne peuvent donc
pas diverger.

La rangée elle-même est **la même vue** qui servira aux recherches récentes (issue 0072) : un
glyphe et un libellé. Une vue, pas deux — c'est ce que dit la maquette (`Search / Query Row`).

L'envoi part de deux gestes : la touche « rechercher » du clavier (`.onSubmit(of: .search)`) ou un
tap sur une suggestion. `SearchPhase` passe alors en `results(query)`, `SearchModel.searchEntity`
est appelé, et les résultats complets s'affichent **groupés par type** — « Livres · n » puis
« Auteur·ices · n » — en groupes encartés de `SearchResultCell`, la vue qui sert déjà les œuvres,
les personnes et les exemplaires possédés.

Éditer la requête après un envoi ressort de `results` et revient aux suggestions ; c'est
`SearchPhase` qui le dit, pas la vue.

L'appel est débouncé, sa `Task` en vol annulée quand la requête change, son échec remonté par
`AppErrorReporter` comme tous les autres modèles. Un résultat ouvre sa destination par le
`NavigationDestination` et le `NavigationPath` de l'onglet Inventaire : pas de nouvelle pile, pas
de nouveau cas d'énumération.

`SearchModel.searchLocalInventory` — mort aujourd'hui — n'est pas ressuscité : la section locale
lit les `@Query` de l'inventaire. Sa suppression est dans l'issue 0074, avec le reste.

## Acceptance criteria

- [ ] Dès trois caractères, trois suggestions s'affichent sous la section locale, dans l'ordre
      livres / auteur·ices / requête brute
- [ ] La requête apparaît en gras dans chaque libellé
- [ ] La rangée des suggestions est la même vue que celle qui servira aux récentes
- [ ] La touche « rechercher » du clavier lance la recherche
- [ ] Un tap sur une suggestion lance la recherche avec les types d'entités correspondants
- [ ] Les résultats s'affichent groupés par type, chaque en-tête portant son nombre
- [ ] Un tap sur une œuvre ouvre la fiche livre, sur une auteur·ice sa page, sur un de mes
      exemplaires l'exemplaire que je possède
- [ ] Éditer la requête après un envoi ramène aux suggestions
- [ ] Une requête remplacée pendant le vol annule l'appel précédent
- [ ] Un échec réseau remonte par `AppErrorReporter` sans vider la section locale déjà affichée
- [ ] Suite `SearchSuggestion` : trois suggestions dans un ordre stable, chacune portant les bons
      types d'entités
- [ ] Suite `SearchPhase` complétée : la transition vers `results` à l'envoi, et le retour vers
      `suggesting` quand la requête est ensuite modifiée
- [ ] Les nouvelles chaînes sont dans `Localizable.xcstrings`, au vouvoiement
- [ ] L'écran se lit en clair et en sombre
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0070-local-search-section-and-threshold.md`
