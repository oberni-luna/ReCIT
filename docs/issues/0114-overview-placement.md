Title: Un placement propre à la vue d'ensemble du graphe Réseau
Labels: needs-triage, bug
Type: AFK

## Parent

`docs/features/0035-network-graph.md`

## What to build

Sur un grand réseau, « Tout » s'ouvre en vue d'ensemble — et ses pastilles et ses tuiles se chevauchent dès le
cadrage d'ouverture : 13 paires sur la fixture R3 (42 amis, 6 groupes), beaucoup sur 200 amis + 30 groupes (constat
du commit `2478796`, issue 0109).

La cause : `NetworkGraphLayout` garantit zéro chevauchement des boîtes **pleines** (avatar + nom, cartes de groupe).
La vue d'ensemble dessine aux mêmes positions, multipliées par une échelle sous ×0,6, des nœuds de taille fixe à
l'écran (pastille 24 pt, tuile compacte 52 pt et son nom, « Vous » à 70 %). Rien ne garantit que des positions
rapprochées par l'échelle restent plus écartées que ces boîtes-là. Au-dessus de ×0,6, les nœuds pleins rétrécissent
avec le réseau et le problème ne se pose pas.

- La vue d'ensemble a son propre placement : calculé à partir des boîtes de `NetworkOverviewBoxes` (pastilles,
  tuiles mesurées, « Vous » ×0,7) et des positions pleines comme point de départ, pour que le passage d'un niveau à
  l'autre reste lisible (mêmes anneaux, même ordre des groupes, chaque ami du même côté).
- Il reste pur, `nonisolated`, déterministe (graine `DeterministicTilt`), mis en cache par empreinte et calculé hors
  de l'acteur principal, comme le placement plein (Q16, Q45).
- `GraphViewport` place les nœuds selon le niveau dessiné ; le cadrage d'ouverture en vue d'ensemble se fait sur ce
  placement. Les deux bascules (×0,6 / ×0,7) font glisser les nœuds d'un placement à l'autre, sauf avec Réduire les
  animations (Q17) ; un pincement en cours ne saute pas.
- Le toucher (le plus proche dans 44 pt), les bornes, le panoramique sous la feuille et l'ordre VoiceOver suivent
  le placement du niveau dessiné.

## Acceptance criteria

- [ ] Zéro chevauchement des boîtes de la vue d'ensemble, à son cadrage d'ouverture, sur R3 et sur 200 amis + 30 groupes (tests, comme `NetworkGraphLayoutTests`).
- [ ] Même entrée, mêmes positions d'un processus à l'autre ; ordre des groupes et anneaux respectés (tests).
- [ ] Le calcul 200 + 30 tient dans le budget existant (test).
- [ ] Tests `GraphViewport` : cadrage d'ouverture, toucher et bornes sur le placement de la vue d'ensemble ; hystérésis inchangée.
- [ ] Le graphe plein ne change pas (les tests existants passent sans modification).
- [ ] La build compile ; la suite est verte ; le feature doc 0035 ne cite plus ce défaut.

## Blocked by

None - can start immediately
