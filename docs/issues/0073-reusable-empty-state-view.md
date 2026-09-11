Title: Une vue d'état vide réutilisable, et « Aucune recherche récente » pour commencer
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0012-unified-inventory-search.md`

## What to build

Quand je n'ai aucune recherche récente, le premier temps n'a rien à montrer : derrière le clavier,
un écran nu qui se lit comme un bug. Cette tranche lui donne un état vide — **et donne à l'app sa
première vue d'état vide réutilisable**.

Il n'y en a aucune aujourd'hui : chaque liste dessine son propre `Text` centré
(`ShelvesContent`, `InventoryListContent`, `EntityListView`, `EntityListDetail`). C'est exactement
ce que la passe « États vides » du 2026-08-28 a relevé et proposé de remplacer, en dessinant le
composant `Empty State` (`204:263`, `Layout=Centered`) — voir
`docs/design-system/figma-library.md`. Cette tranche implémente cette proposition, une fois, dans
`Features/Components/`, pour que les quatre autres états vides puissent l'adopter ensuite
(issue 0076 pour le premier) au lieu de faire chacun une variante du même bloc.

La vue : un glyphe, un titre, une phrase, et une action facultative — le glyphe, la phrase et
l'action se taisent chacun sur demande. Tokens du design system uniquement, pas de valeur
littérale.

Son premier emploi, ici : « Aucune recherche récente » / « Vos recherches récentes apparaîtront
ici. », glyphe loupe, sans action. Le bloc est **centré entre le bas du champ et le haut du
clavier**, pas au centre de l'écran — la maquette le pose à `y=225` pour un bloc de 177, soit le
milieu de la bande réellement visible.

Frontière à tenir : cette tranche traite les **récentes** vides. Une recherche **sans résultat**
est un autre état, et c'est l'issue 0076.

## Acceptance criteria

- [ ] Une vue d'état vide réutilisable existe dans `Features/Components/`, avec glyphe, titre,
      phrase et action tous facultatifs sauf le titre
- [ ] Elle n'utilise que des tokens du design system (`textStyle`, `foregroundStyle`, `Spacing`)
- [ ] Un utilisateur sans aucune recherche récente voit « Aucune recherche récente » et « Vos
      recherches récentes apparaîtront ici. », avec un glyphe loupe et sans bouton
- [ ] Le bloc est optiquement centré dans la bande entre le champ et le clavier, pas dans la frame
- [ ] Envoyer une recherche fait disparaître l'état vide et apparaître la section des récentes
- [ ] « Effacer » ramène à l'état vide
- [ ] L'état vide se lit en clair et en sombre
- [ ] Les rangées et l'état vide grandissent avec Dynamic Type
- [ ] Les nouvelles chaînes sont dans `Localizable.xcstrings`, au vouvoiement
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0072-recent-searches-kept-locally.md`
