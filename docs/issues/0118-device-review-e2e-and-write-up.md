Title: Revue sur appareil, scénario e2e et rédaction de l'onglet Recherche
Labels: needs-triage, docs
Type: HITL

## Parent

`docs/prd/0020-search-tab.md`

## What to build

Fermer la feature.

- Le propriétaire lance `scripts/e2e.sh` et passe l'onglet sur appareil (Dynamic Type grand
  compris).
- Une feature doc sous `docs/features/` dit ce que l'onglet est devenu, et remplace la partie de
  0014 sur l'emplacement de la recherche ; 0014 est annotée, pas réécrite. Lien ajouté dans la
  liste des features de `CLAUDE.md`.
- `docs/design-system/figma-library.md` note la variante `Chrome / Tab Bar` comme divergence.
- Le PRD 0020 et les issues 0115–0118 sont supprimés.

## Acceptance criteria

- [ ] Compte-rendu e2e sans KO sur les étapes de recherche.
- [ ] Feature doc écrite, 0014 annotée, `CLAUDE.md` à jour.
- [ ] Divergence Figma notée.
- [ ] PRD et issues supprimés.

## Blocked by

- `docs/issues/0116-the-search-tab.md`
- `docs/issues/0117-the-friends-carousel-at-rest.md`
