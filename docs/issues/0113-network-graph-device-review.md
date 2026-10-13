Title: Revue sur appareil du réseau en graphe, puis sortie de DEBUG
Labels: needs-triage, feature
Type: HITL

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Rien de « Tout » n'a été vu sur un appareil. Avant de le livrer en 1.4.0 :

- Passe sur iPhone avec un vrai compte : clair et sombre, VoiceOver, grande taille de texte, Réduire les
  animations, hors ligne, premier lancement.
- Mesure Instruments : 60 i/s en panoramique avec 200 amis + 30 groupes (Q45) ; régler les seuils
  d'hystérésis (Q31) et l'échelle max (Q33).
- Lancer le scénario e2e (0111).
- Décider la sortie : retirer le `#if DEBUG` de `NetworkSegment.all`, notes de version 1.4.0 (Q47).
- Pourquoi HITL : appareil, compte réel et décision de livraison.

## Acceptance criteria

- [ ] Les constats sont consignés dans le feature doc 0035 ; les défauts deviennent des issues.
- [ ] Le segment sort de DEBUG dans un commit à part, avec les notes de version.

## Blocked by

- `docs/issues/0112-write-up.md`
