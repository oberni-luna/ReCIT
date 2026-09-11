Title: La deuxième astuce : rien n'est encore enregistré
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0013-sorting-tips.md`

## What to build

La décision la plus importante de l'écran — la session vit en mémoire, rien ne part avant
« Appliquer » (PRD 0009) — est dite à l'utilisateur, **une fois qu'elle le concerne**.

Une deuxième clause dans `SortTipGate` : l'astuce est due dès qu'il y a au moins un changement en
attente, donc jamais avant que SORT-1 ait servi. La carte pointe « Appliquer » et renvoie au seul
endroit où la décision se lit déjà — le récapitulatif juste en dessous — au lieu d'ajouter une
quatrième lecture au pied de page.

Elle est muette pendant que l'écran travaille : `isApplying` ou `isProposing` suffit à la taire, ce
qui règle par construction le cas de la carte posée sur des cartes qui respirent. Elle est
invalidée par le **premier « Appliquer » lancé** — apprendre ce que fait le bouton en l'utilisant
suffit.

L'ordre est déjà porté par le `TipGroup(.ordered)` de l'issue 0077 : cette astuce ne peut pas
cohabiter avec SORT-1 à l'écran.

Maquette : frame `SORT-2 · Rien n'est enregistré` (`314:8199`).

## Acceptance criteria

- [ ] Après un premier dépôt, la carte apparaît et pointe « Appliquer »
- [ ] Elle n'apparaît jamais tant qu'il n'y a rien à enregistrer
- [ ] Elle disparaît pour de bon après un « Appliquer » lancé, y compris après relance
- [ ] Elle ne s'affiche pas pendant une écriture ou une proposition en cours
- [ ] Jamais deux astuces à l'écran en même temps
- [ ] Annuler tous les changements la fait taire plutôt que la laisser désigner un bouton inerte
- [ ] Texte au vouvoiement, français et anglais, clair et sombre, corps de texte agrandi
- [ ] `xcodebuild` passe, la suite `ReCIT_iOSTests` passe inchangée

## Blocked by

- `docs/issues/0077-sort-tip-drag-to-file.md`
