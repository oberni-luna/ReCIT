Title: Une étape du scénario de bout en bout pour Réseau · Tout
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Le scénario `ReCIT_iOSE2E` visite l'onglet Réseau : il ouvre « Tout », touche un groupe, ouvre sa fiche
et revient (Q46).

- `E2EDriver` apprend l'onglet Réseau ; identifiants `e2e.network.graph.*` sur le graphe, les nœuds, la
  feuille et ses boutons.
- L'étape s'insère dans le compte-rendu avec capture et OK / KO / non joué ; elle tolère un compte de
  test sans groupe (« non joué » plutôt que KO).
- **Le scénario n'est pas lancé** : il coûte plus de dix minutes et bute sur la limite de connexions
  d'inventaire.io ; Olivier le lance.

## Acceptance criteria

- [ ] La cible `ReCIT_iOSE2E` compile avec la nouvelle étape.
- [ ] Les identifiants utilisés existent dans l'app.
- [ ] `docs/features/0012-end-to-end-scenario.md` mentionne l'étape.

## Blocked by

- `docs/issues/0107-viewport-and-sheets.md`
