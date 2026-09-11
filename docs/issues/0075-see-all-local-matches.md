Title: « Tout voir » — décider où mène le plafond de trois, puis l'implémenter
Labels: needs-triage, feature
Type: HITL

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

La section locale est plafonnée à trois résultats (issue 0070) pour une raison précise : au-delà,
la route vers inventaire.io passe sous le clavier et la seconde moitié de la recherche devient
invisible. Le plafond ne doit pourtant jamais **cacher** des livres. La maquette prévoit donc une
action « Tout voir » dans l'en-tête de section, affichée quand le total dépasse trois —
`InventorySearchRanking` renvoie déjà ce total, personne ne le consomme.

**Ce qui n'est pas tranché, et doit l'être avant de coder** : où mène cette action.

1. Un écran poussé dédié, « Dans mes livres et chez mes amis », qui liste tous les résultats
   locaux de la requête. Cohérent avec les résultats distants, mais c'est un cas de
   `NavigationDestination` de plus, et un écran qui n'existe que pour une liste filtrée.
2. La liste d'inventaire déjà filtrée : « Tout voir » referme le mode recherche et laisse
   l'inventaire filtré sur la requête — ce que l'app fait déjà aujourd'hui, sans les livres des
   amis. Rien de neuf à construire, mais l'utilisateur change d'écran et perd les suggestions.
3. La section se déplie sur place, sans plafond, et la section inventaire.io descend avec elle.
   Le plus simple, mais rend le clavier gênant — exactement ce que le plafond évitait.

La décision se prend d'abord, avec les maquettes sous les yeux ; l'implémentation suit dans la
même tranche. Si l'option 1 est retenue, la passe Figma correspondante est à faire aussi : la
section `Recherche unifiée` n'a pas cet écran.

## Acceptance criteria

- [ ] **Étape humaine** : la destination de « Tout voir » est choisie parmi les trois options, et
      la raison est écrite dans `docs/design-system/figma-library.md` (section « Tranché »)
- [ ] L'action n'apparaît que lorsque le total des résultats locaux dépasse trois
- [ ] Elle n'apparaît pas quand le total vaut trois ou moins
- [ ] L'action mène là où la décision dit, et le libellé le promet sans ambiguïté
- [ ] Les résultats atteints par « Tout voir » comprennent mes livres **et** ceux de mes amis,
      dans le même ordre que la section plafonnée
- [ ] Si un écran nouveau est retenu : il passe par `NavigationDestination` et le `NavigationPath`
      de l'onglet Inventaire, et il est maquetté dans la section `Recherche unifiée`
- [ ] Les nouvelles chaînes sont dans `Localizable.xcstrings`, au vouvoiement
- [ ] L'écran se lit en clair et en sombre
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0070-local-search-section-and-threshold.md`
