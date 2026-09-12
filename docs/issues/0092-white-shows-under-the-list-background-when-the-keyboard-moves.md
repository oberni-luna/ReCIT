Title: Du blanc passe sous le fond secondary quand le clavier bouge
Labels: needs-triage, bug
Type: AFK

## Parent

`ReCIT_iOS/DesignSystem/List/View+applyBackground.swift` — `applyListBackground()`, utilisé par
dix-huit écrans. Vu sur « Ajouter des amis lecteurs »
(`docs/features/0018-reader-network.md`), reproductible partout où un écran à fond secondary
porte un `.searchable` ou un champ de texte.

## What happened

Enregistrement d'écran fourni le 2026-09-12 (iPhone 17, clair), dépouillé image par image en
lisant une colonne de pixels :

```
t=0.00  [tout l'écran : 241,241,241]                          ← backgroundSecondary, au repos
t=1.00  [… clavier …] [bas de l'écran : 255,255,255]          ← liseré blanc sous le clavier
t=1.80  [0-271 : 241] [274-332 : 255,255,255] [337-… clavier] ← le clavier descend, laisse du blanc
t=1.90  [0-327 : 241] [331-415 : 255,255,255] [420-… clavier]
t=2.00  [0-404 : 241] [406-432 : 255,255,255]
t=2.10  [tout l'écran : 241,241,241]                          ← le fond rattrape
```

`241,241,241` est `backgroundSecondary` (`color/gray/50`), `255,255,255` est
`backgroundDefault` (`color/gray/0`) — c'est le fond de la fenêtre qui se voit, pas une nuance de
notre fond. La bande blanche dure le temps de l'animation du clavier, dans les deux sens, et le
liseré sous le clavier reste tant qu'il est levé.

La cause : `applyListBackground()` pose `.background(.backgroundSecondary)` sur la `List`, et une
`List` sous un clavier voit sa zone sûre rognée par l'encart clavier. Le fond est dimensionné sur
ce cadre rétréci ; la zone que le clavier occupe puis libère n'appartient à personne, et c'est la
fenêtre qu'on y voit. `SafeAreaRegions.all` couvre `.container` **et** `.keyboard` : c'est cette
seconde région qui manque.

Le fond seul doit déborder — pas la `List`. Un `.ignoresSafeArea(.keyboard)` posé sur la liste
elle-même ferait glisser ses rangées sous le clavier.

## What to build

Corriger le modificateur partagé, ce qui règle les dix-huit écrans d'un coup, et poser le fond
sur `UserDetailView`, seul écran du parcours réseau à ne pas l'avoir du tout : le profil d'un
lecteur est resté blanc pendant que les cinq autres étaient gris.

## Acceptance criteria

- [ ] Sur « Ajouter des amis lecteurs », faire monter puis descendre le clavier ne laisse
      apparaître aucune bande blanche, ni pendant l'animation ni sous le clavier levé
- [ ] Le profil d'un lecteur est sur fond secondary, comme les autres écrans du réseau
- [ ] En sombre, le fond des mêmes écrans est bien `color/gray/800` et rien ne passe dessous
- [ ] Aucune rangée de liste ne glisse sous le clavier : seul le fond déborde
- [ ] Les autres écrans à `applyListBackground()` sont inchangés au repos

## Blocked by

—
