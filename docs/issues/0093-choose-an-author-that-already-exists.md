Title: Choisir un auteur qu'inventaire.io connaît déjà
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frame `C3`.

## What to build

Le doublon d'auteur est le seul dégât qu'un contributeur de bonne foi puisse faire. L'écran le rend
difficile : les auteurs existants d'abord, la création en dernier.

- Le champ « auteur » de la feuille ouvre un écran de choix, avec recherche au fil de la frappe.
  La recherche **existe déjà** : `SearchModel.searchEntity(query:entityTypes: [.humans])`, avec son
  score et sa description. On la réutilise, on n'en écrit pas une deuxième.
- Chaque résultat porte son nom, sa description et de quoi trancher entre deux homonymes.
- Une dernière rangée crée l'auteur saisi quand aucun ne correspond.
- Conséquence sur le payload : un auteur **choisi** part en `authors: [{ uri }]`, un auteur **créé**
  part en `authors: [{ labels }]`. C'est cette distinction qui empêche le doublon, et c'est le
  serveur qui arbitre ensuite.
- Une phrase dit pourquoi on préfère un auteur existant.

## Acceptance criteria

- [ ] Taper trois caractères propose des auteurs existants
- [ ] Choisir un auteur le rapporte dans la feuille, avec sa description
- [ ] La requête `resolve` porte alors l'uri de cet auteur et aucun label
- [ ] Créer l'auteur saisi porte les labels et aucune uri
- [ ] Une recherche en échec n'empêche pas de créer l'auteur à la main
- [ ] Les deux formes de payload sont couvertes par des tests purs
- [ ] Textes en français et en anglais

## Blocked by

- `docs/issues/0091-publish-a-minimal-edition.md`
