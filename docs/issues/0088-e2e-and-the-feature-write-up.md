Title: Le scénario end-to-end traverse « Autres éditions », et la feature est écrite
Labels: needs-triage, chore
Type: HITL

## Parent

`docs/prd/0014-search-results-are-editions.md` — [ADR 0002, Move 3](../adr/0002-unified-book-detail.md)

## What to build

Lire `docs/features/0012-end-to-end-scenario.md` avant de toucher à quoi que ce soit ici.

**Le scénario passe déjà.** `reachBookScreen` teste `if driver.exists("e2e.book.menu") { return }`
en premier, donc un push direct vers le livre le satisfait immédiatement. Le problème n'est pas
qu'il casse, c'est qu'il ne traverse plus jamais le picker : `e2e.workEdition` n'est plus atteint
par ce chemin, et plus rien ne protège `WorkEditionPicker` d'une régression.

**La moitié code est faite (2026-09-11)** : le pas « Autres éditions d'un livre », le
backtracking immédiat sur `e2e.book.noEdition`, `E2EDriver.skip(_:because:)`, les identifiants
`e2e.book.otherEditions` et `e2e.book.noEdition`, et la réécriture de l'étape 05 autour de
`e2e.shelves.scan` — cette dernière parce que le run du 2026-09-11 est mort dessus. `ReCIT_iOSE2E`
compile. **Ce qui reste : le run lui-même, et ce qu'on en écrit.**

À faire :

- **Un pas « Autres éditions »** : depuis le livre atteint, entrer dans la section, vérifier que le
  picker liste des `e2e.workEdition`, et revenir. Toutes les œuvres n'en ont pas — une édition dont
  l'œuvre n'a pas de sœur n'affiche pas la section — donc le pas doit se déclarer **non joué**
  plutôt que KO quand la section est absente, comme le compte-rendu sait déjà le faire.
- **Le backtracking devient immédiat** grâce à l'identifiant `e2e.*` posé sur l'écran d'absence par
  l'issue 0086 : `reachBookScreen` n'a plus à attendre 18 secondes de `patience` sur une œuvre
  fantôme. Sa boucle et son commentaire — *« some of them have no edition at all, and their gateway
  sits on a spinner forever »* — sont à mettre à jour : ce n'est plus vrai.
- **Le document de feature** dans `docs/features/`, et la suppression du PRD 0014, comme
  `docs/prd/README.md` le prévoit. L'index de `CLAUDE.md` gagne sa ligne.

Rappel : inventaire.io limite les connexions et rend un `429`. Plusieurs runs coup sur coup donnent
un KO sur l'étape de connexion qui ne veut rien dire — attendre quelques minutes.

## Acceptance criteria

- [ ] `scripts/e2e.sh` passe de bout en bout, compte-rendu à l'appui — **lancer avec
      `E2E_RESET_ACCOUNT=1`**, sinon les livres d'un run précédent empêchent l'accueil de
      s'afficher et le chemin nominal de l'étape 05 n'est jamais joué
- [ ] Le compte-rendu montre un pas qui traverse « Autres éditions » et revient
- [ ] Ce pas se déclare « non joué » et non KO quand l'œuvre n'a pas d'autre édition
- [ ] Le backtracking sur une œuvre sans édition est immédiat, plus de 18 secondes d'attente
- [ ] Le commentaire de `reachBookScreen` sur le « spinner forever » est corrigé ou retiré
- [ ] `docs/features/0012-end-to-end-scenario.md` décrit le nouveau pas et tout identifiant `e2e.*`
      ajouté
- [ ] Un document de feature est écrit dans `docs/features/`, et `docs/prd/0014-…` est supprimé
- [ ] La ligne de la feature est ajoutée à l'index de `CLAUDE.md`
- [ ] Une passe manuelle sur appareil : français et anglais, clair et sombre, grand corps de texte

## Blocked by

- `docs/issues/0086-the-two-absences.md`
- `docs/issues/0087-remember-the-chosen-edition.md`
