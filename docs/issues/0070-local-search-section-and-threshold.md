Title: La recherche de l'inventaire trouve aussi les livres des amis, plafonnés à trois
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

La première tranche de la recherche unifiée : **le champ de l'inventaire cesse de ne chercher que
dans mes livres**. Taper trois caractères dans `ShelvesView` montre une section unique — mes
livres et ceux de mes amis qui correspondent — plafonnée à trois, mes livres d'abord.

Aujourd'hui la branche `isSearching` de `ShelvesContent` rend un `InventoryListContent` filtré sur
`.userInventory`. Elle est remplacée par la surface de recherche, pilotée par deux modules purs
nouveaux :

- **`SearchPhase`** (`Model/SearchResult/`) — la machine à états de l'écran, calculée depuis trois
  entrées : le champ a-t-il le focus, la requête nettoyée, une recherche a-t-elle été envoyée pour
  cette requête. Cas : `recents`, `typing` (un ou deux caractères), `suggesting` (trois ou plus),
  `results(query)`. **Elle porte le seuil de trois caractères**, qui n'est écrit nulle part
  ailleurs. Les cas `recents` et `results` existent dès cette tranche mais ne sont pas encore
  rendus (issues 0072 et 0071) : sous trois caractères, l'écran ne montre rien de neuf.
- **`InventorySearchRanking`** (`Model/SearchResult/`) — fonction pure sur des valeurs simples
  (identifiant, `searchIndex`, `isMine`, date de création) et non sur `InventoryItem`, pour être
  testable sans `ModelContainer`. Filtre avec `localizedStandardContains` comme le reste de l'app,
  ordonne **les miens avant ceux des amis**, le plus récemment ajouté d'abord dans chaque groupe,
  et renvoie à la fois les trois retenus **et le total** — le total est ce qui décidera plus tard
  d'afficher « Tout voir » (issue 0075).

Les résultats locaux viennent des `@Query` réactifs existants sur `InventoryItem` — les miens par
`ownerId`, ceux des amis par sa négation — filtrés en mémoire. Rien de neuf n'est persisté, aucune
écriture serveur, donc rien d'optimiste : ADR 0001 est respecté sans nouveau mécanisme.

Les cellules sont les `InventoryCell` existantes ; celle d'un livre d'ami nomme son propriétaire.
L'en-tête de section est une chaîne nouvelle à la première personne (« Dans mes livres et chez mes
amis »), pas `search.friends_inventory`, qui est le seul tutoiement du catalogue et meurt avec
`SearchView` à l'issue 0074.

## Acceptance criteria

- [ ] Taper trois caractères dans le champ de l'inventaire affiche une section unique mêlant mes
      livres et ceux de mes amis
- [ ] La section ne montre jamais plus de trois résultats
- [ ] Mes livres apparaissent avant ceux de mes amis ; à propriétaire égal, le plus récemment
      ajouté d'abord
- [ ] Un livre d'ami nomme son propriétaire dans la cellule
- [ ] « emile zola » trouve « Émile Zola » (accents et casse ignorés)
- [ ] Sous trois caractères, l'écran ne montre pas de section vide
- [ ] `SearchPhase` est un type valeur pur, sans dépendance à SwiftUI ni à SwiftData
- [ ] `InventorySearchRanking` se teste sans `ModelContainer`
- [ ] Suite `SearchPhase` : le seuil à zéro, un, deux et trois caractères ; une requête faite
      uniquement d'espaces ; la perte de focus
- [ ] Suite `InventorySearchRanking` : le plafond à trois avec le total renvoyé ; l'ordre entre
      les deux groupes et dans chaque groupe ; la casse et les accents ; une requête vide ; une
      requête qui ne matche rien
- [ ] Les nouvelles chaînes sont dans `Localizable.xcstrings`, au vouvoiement
- [ ] L'écran se lit en clair et en sombre
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe

## Blocked by

None - can start immediately
