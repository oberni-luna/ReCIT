Title: Chargement, aucun résultat, erreur réseau : les trois états que la recherche ne dit pas
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

La recherche unifiée marche ; il lui manque de dire ce qui se passe quand elle ne renvoie rien.
Trois états, tous à la charge de la vue d'état vide de l'issue 0073 :

- **Chargement.** L'appel distant est parti, rien n'est encore là. Aujourd'hui `SearchView`
  affichait « loading more results... » — chaîne en dur, non localisée, dans une app entièrement
  en `Localizable.xcstrings` (divergences D19 / D-R3). Elle meurt avec `SearchView` à l'issue 0074
  et ne doit pas revenir sous une autre forme.
- **Aucun résultat.** La requête est partie, inventaire.io répond une liste vide. Cet état a
  **déjà sa maquette** : « C · Recherche sans résultat », frames proposées `211:6605` (clair) et
  `211:6686` (sombre) de la section `Empty states`, dessinées contre `InventoryListContent` lors
  de la passe du 2026-08-28. L'adopter est bon marché maintenant que la vue réutilisable existe.
- **Erreur réseau.** L'appel a échoué. Le message remonte déjà par `AppErrorReporter` vers la
  SnackBar de `MainTabView` ; ce qui manque, c'est que **la section locale reste affichée** —
  une connexion morte ne doit pas ressembler à une bibliothèque vide — et qu'un moyen de
  réessayer existe.

Trois choses à distinguer nettement à l'écran : « ça charge », « il n'y a rien », « ça n'a pas
marché ». C'est cette distinction qui est la valeur de la tranche, plus que les vues elles-mêmes.

Et une frontière à ne pas franchir : l'état vide des **récentes** (issue 0073) et l'état « aucun
résultat » pour une **requête** sont deux états différents, avec deux textes différents. Le second
ne remplace pas le premier.

## Acceptance criteria

- [ ] Pendant l'appel distant, un signe visible de chargement, localisé, sans chaîne en dur
- [ ] Un résultat distant vide affiche l'état « aucun résultat » avec sa propre copie, distincte
      de celle des récentes vides
- [ ] Cet état reprend la maquette `211:6605` / `211:6686` et la vue réutilisable de l'issue 0073
- [ ] Un échec réseau laisse la section locale affichée et dit qu'il a échoué
- [ ] Un moyen de réessayer existe après un échec
- [ ] Charger, ne rien trouver et échouer sont trois écrans distincts, jamais confondus
- [ ] Plus aucune chaîne non localisée dans la recherche ; D19 / D-R3 restent résolues
- [ ] Les trois états se lisent en clair et en sombre
- [ ] `docs/design-system/figma-library.md` : la passe « États vides » note quelle proposition a
      été implémentée et où
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0073-reusable-empty-state-view.md`
- `docs/issues/0074-retire-the-search-tab.md`
