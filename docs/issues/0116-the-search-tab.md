Title: L'onglet Recherche
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0020-search-tab.md`

## What to build

La recherche unifiée quitte l'inventaire pour un onglet à elle, avec le rôle système `search`.

- `TabConfig` gagne `search`, avec son rôle ; iOS le pose à part au bout de la barre. Titre sous
  `tab.search`.
- Une racine d'onglet avec sa propre pile de navigation, qui reprend tout ce que l'inventaire tient
  pour la recherche : `.searchable` (avec `isPresented` lié), la soumission, `.onSubmit(of: .search)`.
- `SearchPhase.current(query:submittedQuery:)` : le focus ne compte plus, `nil` disparaît. Texte
  vide = `recents`, visible clavier levé ou non.
- `TabRouter`, `@Observable @MainActor`, en environnement : il possède l'onglet sélectionné et une
  demande d'activation du champ. L'étiquette « Rechercher » de l'étagère vide sélectionne
  Recherche et lève le clavier ; re-taper Recherche déjà sélectionné revient à la racine puis lève
  le clavier.
- Sélectionner l'onglet ne lève pas le clavier. Requête, résultats et pile survivent au changement
  d'onglet.
- L'inventaire perd son champ ; `ShelvesContent` perd sa branche `isSearching` et `onSearch`.
- Les fichiers `InventorySearch*` passent dans le dossier Search et perdent le préfixe
  `Inventory`. Clés `inventory.search.*` et identifiants `e2e.*` inchangés.
- Le carrousel « Chez mes amis » de l'issue 0115 (au repos seulement) suit la surface dans l'onglet.
- Les trois étapes de recherche du scénario e2e pilotent l'onglet ; quitter la recherche devient
  sélectionner l'inventaire.

## Acceptance criteria

- [ ] Un onglet Recherche à rôle `search` apparaît dans la barre ; l'inventaire n'a plus de champ.
- [ ] Au repos, l'onglet montre les récents (ou l'état vide) et le carrousel, sans clavier.
- [ ] Récents, suggestions, résultats, chargement, absence, échec, « Réessayer » et tirer-pour-rafraîchir se comportent comme avant.
- [ ] Changer d'onglet puis revenir conserve requête, résultats et livre ouvert, sans nouvel appel `GET /api/search`.
- [ ] Re-taper l'onglet sélectionné revient à la racine et lève le clavier.
- [ ] L'étiquette « Rechercher » de l'étagère vide ouvre l'onglet clavier levé.
- [ ] Tests `SearchPhase` (phases sans focus, texte blanc = repos) et `TabRouter` (étiquette, re-tap, demande consommée une fois).
- [ ] `ReCIT_iOSE2E` compile avec les étapes réécrites (le lancement de `scripts/e2e.sh` reste à l'issue 0118).

## Blocked by

- `docs/issues/0115-friends-carousel-animation-spike.md`
