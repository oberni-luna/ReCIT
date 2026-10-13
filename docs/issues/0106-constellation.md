Title: La constellation : graphe et placement purs, nœuds et arêtes dessinés
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

« Tout » dessine mon réseau : « Vous » au centre, mes groupes en anneau, mes amis près des groupes qu'ils
partagent avec moi, les demandeurs et les amis isolés près de moi. Le graphe s'ouvre déjà posé, cadré sur
tout le réseau (sans geste encore), et reste le même d'une ouverture à l'autre.

- `NetworkGraph`, pur : instantané en types valeur → nœuds (`me`, `group(role, pendingCount)`,
  `friend(friend | requested)`), arêtes typées (me↔groupe pleine / pointillée si invité ; ami↔groupe pour
  admins et membres ; me↔ami ; me↔demandeur pointillée), amis isolés marqués, compteur (Q10), groupes
  communs d'un ami sans les invitations (Q27 bis), amis d'un groupe, voisins d'une sélection, ordre de
  lecture (Q44). Non-amis et demandes envoyées absents (Q4, Q5, Q8).
- `NetworkGraphLayout`, pur, `nonisolated` : radial puis relaxation (Q16), groupes par rôle puis nom,
  premier en haut, sens horaire (Q18), zéro chevauchement des boîtes mesurées (Q19), graine
  `DeterministicTilt`, mis en cache par empreinte, calculé hors de l'acteur principal (Q45).
- Rendu : arêtes dans un `Canvas` (vertes ; vous ↔ ami `foregroundTinted` 1 pt à 30 % ; pointillé
  `[4,4]`) sous des nœuds en vraies vues placées par `.position` ; cartes de groupe (rôle, détail
  « Admin · N membres » / « N membres » / « Invitation de X », point rouge, invité en pointillé), nœuds
  ami (44 pt, nom tronqué sur une ligne, demandeur au contour pointillé). Métriques hors tokens dans une
  struct de la feature.
- Dynamic Type plafonné à `.xxxLarge` sur le graphe (Q43). Changement de données : transition animée des
  anciennes aux nouvelles positions, coupée par Réduire les animations (Q17, Q23).

## Acceptance criteria

- [ ] Fixture R1 : 1 « Vous », 3 groupes, 8 amis, les arêtes de la maquette ; Paul isolé ; Ariane demandeur en pointillé (tests `NetworkGraph`).
- [ ] Un ami dans deux groupes = un nœud, deux arêtes ; un non-ami membre d'un groupe n'apparaît pas (tests).
- [ ] Compteur R1 = 8 amis · 2 groupes ; R3 = 42 · 6 (tests).
- [ ] Même entrée → mêmes positions, y compris d'un processus à l'autre (test épinglé comme `DeterministicTiltTests`).
- [ ] Zéro chevauchement sur R1, R3 et 200 amis + 30 groupes ; ordre des groupes respecté ; isolés plus proches de « Vous » ; calcul 200 + 30 sous un budget mesuré (tests).
- [ ] En DEBUG, Tout affiche la constellation cadrée, en clair et en sombre, avec le repli d'avatar.
- [ ] Un ami ajouté ou retiré fait glisser les nœuds ; rien ne glisse avec Réduire les animations.
- [ ] La build compile ; la suite est verte.

## Blocked by

- `docs/issues/0103-groups-persisted.md`
- `docs/issues/0104-shared-avatar-fallback.md`
- `docs/issues/0105-all-segment-shell.md`
