Title: Les deux absences — une œuvre sans édition, et une connexion qui a lâché
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-search-results-are-editions.md` — [ADR 0002, Move 3](../adr/0002-unified-book-detail.md)

## What to build

Deux façons pour un tap de ne rien trouver, deux phrases différentes, et un écran qui répond dans
les deux cas.

**Des œuvres sans aucune édition existent.** La recherche « americanah » en rend deux, dont une
vide : `reverse-claims` répond `[]`. Aujourd'hui le gateway reste sur son `ProgressView`
indéfiniment, et le scénario end-to-end le sait — son commentaire dit *« some of them have no
edition at all, and their gateway sits on a spinner forever »* — et le contourne en attendant
18 secondes de `patience` avant de rebrousser chemin.

**`BookDetailView` rend `.noResult` en `Text("edition.no_result")` nu** ([BookDetailView.swift:75])
— pas d'`EmptyStateView`, aucune sortie. Personne n'y tombait ; avec l'issue 0085 c'est un chemin
atteignable.

À faire :

- `EmptyStateView` (celui d'issue 0073, déjà utilisé par `InventorySearchRemoteSection`) remplace le
  `Text` nu, pour `.noResult` comme pour `.error`.
- **Deux clés distinctes.** `edition.no_result` dit aujourd'hui « Cette édition n'existe pas sur
  inventaire.io », ce qui est faux pour une œuvre sans édition : il faut une clé qui dise qu'aucune
  édition n'est référencée pour ce livre, et une autre pour l'échec réseau — cette dernière avec une
  action « Réessayer », comme `inventory.search.error.retry`.
- **Un identifiant `e2e.*` sur l'absence**, pour que `reachBookScreen` puisse rebrousser chemin tout
  de suite au lieu d'expirer sur `patience`.
- `BookViewModel` doit distinguer les deux : une résolution qui rend `nil` proprement n'est pas une
  résolution qui a levé.

Les deux textes sont à écrire en français et en anglais dans `Localizable.xcstrings`.

[BookDetailView.swift:75]: ../../ReCIT_iOS/Features/Book/BookDetailView.swift

## Acceptance criteria

- [ ] Taper une œuvre sans édition ouvre un écran qui dit qu'aucune édition n'est référencée
- [ ] Le même geste en mode avion ouvre un écran qui dit que la connexion a échoué, avec
      « Réessayer »
- [ ] « Réessayer » relance la résolution et ouvre le livre quand le réseau revient
- [ ] Les deux états sont rendus par `EmptyStateView`, pas par un `Text` nu
- [ ] `edition.no_result` n'est plus employée pour une œuvre sans édition
- [ ] Les deux clés sont traduites en français et en anglais
- [ ] L'écran d'absence porte un identifiant `e2e.*`
- [ ] Le retour arrière depuis un de ces écrans rend la recherche intacte
- [ ] Tests `BookViewModel` pour les deux cas, distincts l'un de l'autre
- [ ] Les deux écrans sont vérifiés en clair et en sombre, et au plus grand corps de texte

## Blocked by

- `docs/issues/0085-tapping-a-result-opens-a-book.md`
