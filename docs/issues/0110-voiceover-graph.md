Title: VoiceOver sur le graphe
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Un lecteur VoiceOver parcourt « Tout » comme une liste ordonnée et peut agir sur chaque nœud (Q44).

- Ordre : « Vous » (en-tête) → demandes d'ami et invitations reçues → chaque groupe (rôle puis nom), son
  libellé nommant ses amis → chaque ami une fois (alphabétique), son libellé nommant ses groupes communs.
- Actions personnalisées : Ouvrir, Voir le profil, Accepter, Refuser selon le nœud.
- Les arêtes et décorations sont cachées ; le point rouge garde son libellé ; les contrôles de zoom ont
  leur nom ; la pastille d'état est lue.

## Acceptance criteria

- [ ] L'ordre de lecture vient de `NetworkGraph` (testé là) et l'interface le respecte (vérifié à l'Accessibility Inspector ou au simulateur).
- [ ] Chaque nœud a un libellé complet et ses actions ; aucun élément décoratif n'est focalisable.
- [ ] Libellés dans `Localizable.xcstrings` (fr, en) ; la build compile ; la suite est verte.

## Blocked by

- `docs/issues/0108-answer-from-the-sheet.md`
- `docs/issues/0109-overview-controls-status.md`
