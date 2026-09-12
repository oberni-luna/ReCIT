Title: La recherche de lecteurs saute d'une barre de navigation entière quand on touche le champ
Labels: needs-triage, bug
Type: AFK

## Parent

`docs/features/0018-reader-network.md` — `ReaderSearchView`.

## What happened

Enregistrement d'écran fourni le 2026-09-12 à 22:11 (iPhone, sombre), et mesure au pixel entre
l'image au repos et l'image clavier levé : **le contenu monte de 162 px @3x, soit 54 pt**, puis
redescend d'autant quand le clavier s'en va. Sur un écran dont le contenu fait deux rangées, un
sursaut de 54 pt dans chaque sens est l'essentiel de ce qu'on voit.

Le même enregistrement confirme au passage que le fond ne lâche plus : `42,42,42` du haut en bas
pendant toute l'animation, dans les deux sens. L'issue 0092 est réglée.

La cause n'est pas le clavier, c'est l'activation de la recherche. Au repos la barre fait **deux
rangées** : le titre inline avec sa flèche de retour, et le tiroir de recherche en dessous. Quand
le champ prend le focus, UIKit escamote la première — c'est
`UISearchController.hidesNavigationBarDuringPresentation`, vrai par défaut — et l'encart haut de
la `List` perd exactement une barre. Tout le contenu suit.

Vérifiable sans clavier du tout : sur un simulateur à clavier matériel, toucher le champ fait
déjà disparaître le titre et la flèche.

## What to build

`searchPresentationToolbarBehavior(.avoidHidingContent)` (iOS 17.1+) est le pendant SwiftUI de ce
réglage UIKit. Rien à introspecter, rien d'UIKit à écrire.

Ce que l'escamotage achetait — de la place — ne sert à rien ici : le champ est déjà à l'écran
(c'est tout l'objet du tiroir en `.always`), et le lecteur doit garder de quoi repartir.

**Périmètre : cet écran seul.** Les autres `.searchable` de l'app (`ShelvesView`,
`EntityListView`) sont des racines d'onglet à grand titre, où escamoter le titre libère une
hauteur réelle pour les résultats. C'est le titre *inline* sur un contenu court qui rend le saut
disproportionné.

## Acceptance criteria

- [ ] Toucher le champ ne déplace plus ni le titre, ni la flèche de retour, ni la liste
- [ ] Le ✕ d'annulation apparaît toujours, et annuler rend bien la main
- [ ] Faire monter et redescendre le clavier ne déplace rien d'autre que ce que le clavier couvre
- [ ] La flèche de retour reste atteignable pendant que le champ a le focus

## Blocked by

—
