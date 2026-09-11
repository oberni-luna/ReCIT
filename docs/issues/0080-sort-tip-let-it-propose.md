Title: La troisième astuce : laissez proposer un rangement
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0013-sorting-tips.md`

## What to build

Le bouton de proposition est une baguette dans un rond, sans un mot. Une troisième clause dans
`SortTipGate` le présente : l'iPhone lit les titres et les genres et remplit les étagères, et la
proposition se corrige avant d'être appliquée.

Deux conditions, et elles comptent toutes les deux :

- **Apple Intelligence disponible**, lu par `AutoSortModel.availability` — la même source que le
  bouton lui-même, pour que l'astuce et le bouton ne puissent pas être en désaccord. Ce modèle
  étant observable, quelqu'un qui active Apple Intelligence et revient trouve les deux ensemble,
  sans relancer l'app.
- **SORT-1 déjà apprise.** La proposition est une aide au geste, pas son remplacement : la montrer
  avant apprendrait à ne jamais ranger soi-même.

Invalidée dès qu'une proposition est demandée.

Maquette : frame `SORT-3 · Proposer un rangement` (`314:8247`).

## Acceptance criteria

- [ ] Sur un appareil où le modèle tourne, et une fois le glissement appris, la carte apparaît et
      pointe le bouton de proposition
- [ ] Sur un appareil sans Apple Intelligence, elle n'apparaît jamais — pas plus que le bouton
- [ ] Elle n'apparaît pas avant que SORT-1 ait été invalidée
- [ ] Elle disparaît pour de bon dès qu'une proposition a été demandée
- [ ] Activer Apple Intelligence puis revenir sur l'écran la fait apparaître sans relancer l'app
- [ ] Elle ne s'affiche pas pendant une écriture ou une proposition en cours
- [ ] Texte au vouvoiement, français et anglais, clair et sombre, corps de texte agrandi
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe inchangée

## Blocked by

- `docs/issues/0077-sort-tip-drag-to-file.md`
