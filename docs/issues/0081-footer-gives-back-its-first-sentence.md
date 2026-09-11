Title: Le pied de page rend sa première phrase
Labels: needs-triage, feature, needs-owner-approval
Type: HITL

## Parent

`docs/prd/0013-sorting-tips.md`

## What to build

`manual_sort.footer.idle` porte deux choses : une instruction permanente et un état.

> « Drag & drop les livres dans les étagères pour les ranger. Rien à appliquer pour le moment. »

SORT-1 dit l'instruction mieux — une seule fois, au bon moment, en visant le livre dont elle
parle — et l'a dite à tous ceux qui en avaient besoin. La chaîne se réduit donc à son état, en
français et en anglais : « Rien à appliquer pour le moment. » / « Nothing to apply for now. »

**C'est une suppression de copie, et elle demande l'accord du propriétaire** : la phrase partie,
un utilisateur qui aurait fermé SORT-1 sans la lire, trois fois, n'a plus d'instruction écrite à
l'écran. Contrepartie assumée dans le PRD — mais c'est le dernier filet de l'écran, et le retirer
est une décision, pas une conséquence.

À trancher avec la même passe : garder ou non l'instruction dans la lecture « rien à appliquer »
lorsque la collection n'a aucune étagère, où le geste n'a encore nulle part où déposer.

## Acceptance criteria

- [ ] Le propriétaire a validé le retrait de la phrase d'instruction
- [ ] `manual_sort.footer.idle` ne porte plus que l'état, en français et en anglais
- [ ] Les trois autres lectures du pied de page — récapitulatif, compte rendu d'une exécution,
      compte rendu d'une exécution arrêtée — sont inchangées
- [ ] Le cas « aucune étagère » est tranché et le comportement retenu est écrit dans l'issue
- [ ] L'écran se lit en clair et en sombre, en français et en anglais
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe inchangée

## Blocked by

- `docs/issues/0077-sort-tip-drag-to-file.md`
