Title: Vue d'ensemble, contrôles en verre, compteur et pastille d'état
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Un grand réseau reste lisible : en dézoomant, les amis deviennent des pastilles, les groupes des tuiles
compactes ; des boutons en verre zooment pour qui ne pince pas ; un compteur dit ce que j'ai ; une pastille
dit que la première synchro est en cours, ou propose de réessayer.

- Niveau sémantique dans `GraphViewport` : bascule sous ≈ ×0,6, retour au-dessus de ≈ ×0,7 de la pleine
  taille, hystérésis (Q31). Vue d'ensemble : pastilles 24 pt (photo ou disque teinté, sans initiales,
  Q37), tuiles compactes, « Vous » ×0,7, arêtes vous ↔ ami masquées sauf amis isolés et demandeurs (Q6),
  styles d'arête R3 (Q32).
- Zoomer / Dézoomer / Recentrer : `.buttonStyle(.glass)` dans un `GlassEffectContainer`, libellés +
  `.labelStyle(.iconOnly)`, ±×1,5 animé, recentrer = cadrage d'ouverture (Q33, Q34, Q35). Toujours
  visibles, sauf dans l'état vide (Q39).
- Pastille d'état en `.glassEffect`, en bas à gauche : compteur « N amis · N groupes » (deux pluriels,
  Q10) ; « Synchronisation… » tant que relations ou groupes n'ont jamais répondu (Q40) ; « Réessayer »
  au premier lancement en échec, qui relance la synchro (Q41). Jamais « Tirez vers le bas » sur Tout.

## Acceptance criteria

- [ ] Tests `GraphViewport` : hystérésis (pas de bascule en va-et-vient autour du seuil), pas de ±×1,5, recentrer.
- [ ] Dézoomer R3 donne pastilles et tuiles ; les arêtes des isolés et du demandeur restent.
- [ ] Les trois boutons marchent et ont un nom ; ils restent au-dessus de la barre d'onglets.
- [ ] Le compteur suit les données (42 · 6 sur la fixture R3) ; la pastille passe en « Synchronisation… » puis au compteur ; en échec de premier lancement, « Réessayer » relance la synchro.
- [ ] La build compile ; la suite est verte.

## Blocked by

- `docs/issues/0107-viewport-and-sheets.md`
