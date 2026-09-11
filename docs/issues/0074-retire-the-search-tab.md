Title: L'onglet Recherche disparaît, et le scénario end-to-end suit
Labels: needs-triage, feature
Type: HITL

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

La recherche vit maintenant dans l'inventaire (issues 0070 à 0073). Cette tranche **supprime ce
qu'elle remplace** et remet le scénario end-to-end d'aplomb.

À supprimer :

- l'onglet `.search` de `MainTabView` — son cas de `TabConfig` et son `TabRole.search`. La barre
  tombe à trois onglets visibles ;
- `Features/Search/MainSearchView.swift` et `Features/Search/SearchView.swift`.
  `SearchResultCell` et `SearchModel` restent ;
- `SearchModel.searchLocalInventory(query:modelContext:)`, mort depuis toujours (divergence D-R1) :
  la section locale lit les `@Query` de l'inventaire, une seconde requête casserait la réactivité
  qu'ADR 0001 demande.

Deux divergences meurent avec `SearchView`, sans travail supplémentaire : la chaîne non localisée
« loading more results... » avec son `HStack(spacing: 12)` littéral (D19 / D-R3), et le `Button`
qui enveloppe un `NavigationLink(value: UUID())` dont le seul rôle est de dessiner un chevron
(D-R5). Le fichier Figma doit être mis à jour en conséquence.

**Le scénario end-to-end casse en trois endroits** et se répare ici :

- `E2EDriver.Tab.search` (`UITests/E2EDriver.swift`) ;
- `openTab(.search)` dans `searchAndAdd` (`UITests/E2EScenarioTests.swift`) ;
- `popBack(to: .search)`, à la fin de la même fonction.

Les trois recherches du scénario partent désormais du champ de l'onglet Inventaire. Lire
`docs/features/0012-end-to-end-scenario.md` avant d'y toucher. `e2e.searchResult` doit continuer à
nommer la même chose — un résultat distant — pour que les compte-rendus passés restent
comparables ; les nouvelles rangées (récente, suggestion) reçoivent leurs propres identifiants au
lieu de le réutiliser.

**Pourquoi HITL** : la preuve de cette tranche est `scripts/e2e.sh`, qui prend dix minutes et
touche le rate limit de connexion d'inventaire.io. Le code et la relecture se font sans
interaction ; le lancement est une étape humaine, en fin de tranche.

## Acceptance criteria

- [ ] La barre d'onglets ne montre plus que Inventaire, Listes et Réglages
- [ ] `MainSearchView` et `SearchView` sont supprimés ; `grep` ne renvoie plus aucune référence
- [ ] `TabRole.search` n'est plus utilisé
- [ ] `SearchModel.searchLocalInventory` est supprimé
- [ ] Le scan reste exactement où il est, dans la barre de navigation de l'inventaire
- [ ] `E2EDriver.Tab` n'a plus de cas `search`, et le scénario cherche depuis l'onglet Inventaire
- [ ] `e2e.searchResult` désigne toujours un résultat distant ; les rangées récente et suggestion
      ont leurs propres identifiants
- [ ] Plus aucune chaîne non localisée dans la recherche
- [ ] `docs/design-system/figma-library.md` : D19 / D-R3 et D-R5 passent en résolues, D-R1 aussi
- [ ] `xcodebuild` passe pour les schémas `ReCIT_iOS`, `ReCIT_iOSTests` et `ReCIT_iOSE2E`
- [ ] **Étape humaine** : `scripts/e2e.sh` est lancé une fois, et le compte-rendu ne porte aucun
      KO nouveau sur les étapes de recherche

## Blocked by

- `docs/issues/0071-inventaire-io-suggestions-and-results.md`
