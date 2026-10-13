Title: Un repli d'avatar partagé : initiales pour un lecteur, glyphe pour un groupe
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Partout où un lecteur ou un groupe n'a pas de photo — ou que la photo ne charge pas — l'app montre ses
initiales sur un disque teinté, ou le glyphe `person.2` sur un carré arrondi teinté, au lieu du carré gris
vide (Q20, Q21, Q21 bis).

- Une fonction pure d'initiales : une lettre par mot si le pseudonyme a des séparateurs (`_`, `.`, `-`,
  espace, changement de casse), sinon ses deux premières lettres ; majuscules ; accents gardés.
- Une vue de repli lecteur / groupe : `backgroundTinted` + `foregroundTinted` ; `action300` à 44 pt et
  plus, `action200` en dessous ; un groupe n'est jamais un cercle.
- Les cellules des listes (Amis, Groupes, invitations, membres) l'adoptent.
- L'URL d'avatar d'un `User` passe par `APIService.absoluteImageUrl`, comme celle d'un groupe.

## Acceptance criteria

- [ ] `olivier_berni` → « OB », `Léa` → « LÉ », `Aïcha` → « AÏ », `JeanLuc` → « JL », chaîne vide → « » (tests).
- [ ] Une cellule de lecteur sans photo montre ses initiales ; une cellule de groupe sans image montre `person.2`.
- [ ] Une photo présente s'affiche comme avant ; un échec de chargement retombe sur le repli.
- [ ] `User.avatarURLValue` est construit par `absoluteImageUrl` (test : chemin `/img/...` et URL absolue).
- [ ] Aucun identifiant `e2e.*` ne change ; la suite est verte ; la build compile.

## Blocked by

None - can start immediately
