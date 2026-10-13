Title: Le write-up : feature 0035, bibliothèque Figma, CLAUDE.md
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Ce que le réseau en graphe est devenu est écrit là où le repo le cherche.

- `docs/features/0035-network-graph.md` : ce qui a été construit, les décisions notables (groupes
  persistés, placement, feuille native, DEBUG), les écarts avec Figma (le code fait foi), ce qui n'a pas
  été vérifié (appareil, VoiceOver réel, vrai compte, 60 i/s, e2e non lancé).
- `docs/design-system/figma-library.md` : les passes du 2026-10-13 sur `512:15486` (composants locaux,
  écrans, panneau Décisions) et l'implémentation, avec ses écarts.
- CLAUDE.md : la ligne de la feature ; la correction « chaque racine d'onglet possède son
  `NavigationPath` » ; les groupes persistés.
- `docs/features/0028-network-tab-and-groups.md` : une note qui renvoie à 0035 pour les groupes désormais
  persistés et l'onglet 3e, sans réécrire l'histoire.
- Le PRD 0019 et les issues 0103–0112 sont supprimés une fois le write-up écrit ; 0113 reste ouverte.

## Acceptance criteria

- [ ] Les trois documents sont à jour et cohérents avec le code.
- [ ] Le PRD et les issues livrées sont supprimés ; 0113 reste.

## Blocked by

- `docs/issues/0103-groups-persisted.md`
- `docs/issues/0104-shared-avatar-fallback.md`
- `docs/issues/0105-all-segment-shell.md`
- `docs/issues/0106-constellation.md`
- `docs/issues/0107-viewport-and-sheets.md`
- `docs/issues/0108-answer-from-the-sheet.md`
- `docs/issues/0109-overview-controls-status.md`
- `docs/issues/0110-voiceover-graph.md`
- `docs/issues/0111-e2e-network-step.md`
