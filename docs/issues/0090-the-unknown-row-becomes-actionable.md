Title: La rangée inconnue cesse d'être une impasse
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frames `C1` et `C8` (variante A).

## What to build

Aujourd'hui un scan qui ne trouve rien monte une rangée rouge, sans action, et redescend au bout de
trois secondes : `ScanResultRowView.offersAdd` supprime le bouton **exprès**, et
`BatchScanViewModel.showNotice` arme un minuteur parce qu'« il n'y a rien à en faire ».

Cette tranche renverse les deux règles, et ouvre une feuille vide au bout.

- `.notFound` devient **actionnable et persistant** : plus de minuteur de notice pour cet état
  (`.alreadyOwned` garde le sien).
- Un **code différent évince** un `.notFound` — la machine refuse aujourd'hui tout nouveau code tant
  que l'état n'est pas `.idle`. `.resolved` et `.adding` restent inévictables. Sans cette
  contrepartie, un utilisateur qui ne veut pas créer reste coincé sur sa propre proposition.
- La rangée porte un **bouton rond** à la place exacte du « + » (variante A), en `background/tinted`
  comme l'autre, avec un libellé d'accessibilité distinct de celui de l'ajout — c'est la seule chose
  qui les distingue tant que le glyphe `book.badge.plus` n'existe pas dans le jeu `Icon`.
- Le bouton ouvre une `.sheet` posée sur la vue caméra (pas poussée dans la pile de navigation du
  flux, qui appartient au chemin de la fiche livre). Elle affiche l'ISBN lu, en lecture seule, et
  un bouton d'abandon. Elle ne publie rien : c'est la tranche suivante qui la remplit.
- Pendant que la feuille est ouverte, aucun code-barres n'est accepté — conséquence gratuite de
  l'état `.notFound` maintenu, à vérifier plutôt qu'à coder.

## Acceptance criteria

- [ ] Un scan sans résultat laisse la rangée à l'écran indéfiniment
- [ ] Un code-barres **différent** remplace cette rangée par une nouvelle recherche
- [ ] Le **même** code-barres, resté en vue, ne relance rien
- [ ] `.resolved` et `.adding` ne sont évinçables par aucun code
- [ ] La rangée inconnue porte un bouton rond, annoncé « Créer ce livre » et non « Ajouter »
- [ ] Le bouton ouvre une feuille portant l'ISBN en lecture seule ; l'abandon revient à la caméra
- [ ] La rangée d'un livre reconnu et celle d'un livre déjà possédé sont inchangées
- [ ] Les nouvelles règles de la machine sont couvertes par des tests purs
- [ ] Identifiants `e2e.*` posés sur le bouton et sur la feuille

## Blocked by

None - can start immediately
