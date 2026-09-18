Title: La deuxième porte — créer un livre depuis une recherche qui ne trouve rien
Labels: needs-triage, feature
Type: HITL

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frame `C6`, **hors périmètre de la v1**.

## What to build

Le scanner n'est pas le seul endroit où un livre manque. La recherche unifiée aussi peut ne rien
trouver, ni chez moi, ni chez mes amis, ni sur inventaire.io — et c'est le même livre absent.

- L'absence de la section « Sur inventaire.io » gagne une action « Ajouter ce livre », posée sur le
  composant d'absence de l'app.
- Sans code-barres, l'ISBN n'est plus connu : il devient un **champ à saisir**, avec sa validation
  de clé de contrôle. C'est le seul écart avec le parcours du scan ; tout le reste du formulaire est
  celui de la v1.
- À rattacher à l'issue 0086, qui refait les deux absences de la fiche livre.

Pourquoi HITL : reste à trancher si l'ISBN est obligatoire. inventaire.io exige un ISBN pour créer
une **édition** ; un livre sans ISBN ne peut donc être créé que comme œuvre, ce qui n'est pas la
même contribution et ne peut pas rejoindre un inventaire de la même façon.

## Acceptance criteria

- [ ] Une recherche sans résultat nulle part propose d'ajouter le livre
- [ ] Le formulaire est celui de la v1, avec un champ ISBN saisissable et validé
- [ ] Le livre créé apparaît dans les résultats de la même recherche
- [ ] Textes en français et en anglais

## Blocked by

- `docs/issues/0096-the-failure-and-the-draft.md`
