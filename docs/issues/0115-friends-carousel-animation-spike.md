Title: Spike — le carrousel « Chez mes amis » pendant la frappe
Labels: needs-triage, feature
Type: HITL

## Parent

`docs/prd/0020-search-tab.md`

## What to build

Le carrousel « Chez mes amis » branché sur la surface de recherche telle qu'elle est aujourd'hui
dans l'inventaire, pour trancher une question : peut-il rester pendant la frappe, filtré et
rétréci, sans gêner ?

## Décision (2026-10-21)

**Non.** Le carrousel est de la découverte : il ne s'affiche qu'au repos, champ vide, et s'en va au
premier caractère. La section locale garde mes livres et ceux de mes amis, comme avant.

- La taille compacte ne gardait pas les suggestions inventaire.io au-dessus du clavier : les trois
  lignes locales atteignent déjà son bord (~516 pt sur iPhone 17), et la section inventaire.io
  commençait vers 684 pt même avec un carrousel compact.
- Repasser de trois à deux caractères retirait la section locale et laissait le carrousel des amis
  seul à l'écran — vu sur la capture du propriétaire.
- Les cellules sont celles de « Livres à ranger » (`SortBookCardView`), à la même largeur et au
  même espacement : les premières, maison, étaient trop espacées.

Ce qui reste du spike dans le code : le carrousel au repos, ses cellules, et l'animation de la liste
sur l'étape de la phase.

## Acceptance criteria

- [x] Le carrousel s'affiche au repos, sous les récentes, dans les cellules de « Livres à ranger ».
- [x] Il disparaît au premier caractère, dans la même animation que les sections qui arrivent.
- [x] La section locale montre mes livres et ceux de mes amis, comme avant.
- [x] Décision du propriétaire notée ici.

## Blocked by

None - can start immediately
