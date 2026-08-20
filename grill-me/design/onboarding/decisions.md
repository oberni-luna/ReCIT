# Décisions — onboarding option C

Session de grilling du 2026-08-20. Chaque ligne est tranchée ; ce fichier est la source pour le PRD.

## 1. Déclencheur de l'accueil (C1)

`User.lastInventorySync != nil` **et** inventaire vide **et** accueil jamais répondu.

Un `@Query` vide est ambigu — `SyncStatusStore` le documente : ça peut vouloir dire « pas encore
synchronisé ». On attend donc la première synchro. Le beat transitoire est déjà couvert par le code :
`ShelvesView.swift:22` affiche `SyncingPlaceholderView` tant que `lastInventorySync == nil`. L'accueil
arrive après le placeholder, jamais sur un écran vide.

## 2. Présentation de C1

`fullScreenCover` posé par `MainTabView`. L'app est chargée derrière, donc « Plus tard » est un dismiss qui
révèle l'inventaire (= C1b) sans transition d'écran. `MainTabView` gagne cette responsabilité en plus de son
observateur d'erreurs.

## 3. Propriété du bilan (C2)

**Le scanner, pas l'onboarding.** Toute session de scan qui ajoute au moins un livre montre le bilan à sa
fermeture — y compris une session lancée depuis l'onglet Recherche après un « Plus tard ». La règle vit à un
seul endroit, et l'incitation à ranger survit au refus de l'accueil.

## 4. Mécanique de C2

Le bilan **remplace la caméra dans le même modal**. Pas de cover imbriqué : la caméra s'éteint, C2 prend sa
place, et c'est le dismiss de C2 qui rend la main.

Deux conséquences à assumer : la fermeture devient à deux temps (le bouton « fermer » termine la session, il
ne quitte pas), et `BatchScanView` cesse d'être « le scanner » pour devenir « la session de scan » — son
doc-comment et peut-être son nom doivent suivre.

## 5. Ce que la session remonte

- **Le compte**, transporté : le titre en a besoin, et une requête ne peut pas le déduire.
- **Les couvertures**, non transportées : `@Query` des cinq derniers livres non rangés (`created` desc),
  conformément à l'invariant 1 de l'ADR 0001. La requête peut attraper un livre ajouté avant la session ;
  sans gravité, il est non rangé et récent lui aussi.

## 6. Illustration

- **C1 : planche nue.** Aucun livre. L'inventaire est vide ; des dos inventés se liraient comme des données
  que l'utilisateur n'a pas.
- **C2 : les vraies couvertures**, qui se posent une par une.

## 7. Mouvement

Sur C2 seulement. Opacité `0 → 1`, décalage `-32 → 0` pt, `easeOut 0.32 s`, échelon `0.08 s`, gauche →
droite, une fois par apparition. Reduce Motion garde le fondu et l'échelonnement, perd le décalage.
Détail : `motion.md`.

## 8. Extinction du bilan

Tant que l'utilisateur **n'a aucune étagère**. Déduit par `@Query`, pas un flag.

Conséquence assumée : créer une étagère à la main éteint aussi le bilan — défendable, l'utilisateur sait
alors ce qu'est une étagère.

## 9. Carte d'étagère vide

Mot **et** destination conditionnels :

| État | Mot | Destination |
|---|---|---|
| Inventaire vide | « ☐ Scanner mes livres » | le scanner |
| Livres non rangés | « ☐ Ranger mes livres » | le rangement automatique |

Ce n'est pas la substitution que features/0008 a retirée : celle-là était silencieuse et dépendait du
matériel. Ici le libellé change avec l'état, donc l'affordance est dite.

## 10. Indisponibilité du rangement

C2 lit la disponibilité et remplace son CTA par `AutoSortUnavailableView`, via un nouveau cas
d'`AutoSortEntryPoint` (« bilan de scan »). Aucun texte recopié — ce composant reste le seul endroit où les
trois raisons sont mises en mots, et c'est `AutoSortEntryPoint` qui décide qui a droit à un bouton Réglages.

## 11. État persisté

Une seule clé : **« accueil répondu »**, indexée sur `user._id`, dans un store `@Observable` adossé à
`UserDefaults` — le patron de `SyncStatusStore`, en per-user. Un deuxième compte sur le même téléphone a
droit à son accueil ; la remise à zéro en recette se fait compte par compte.

## 12. Style du lien de sortie

`Button` + `.buttonStyle(.plain)` + `.textStyle(.action300)` + `.foregroundStyle(.foregroundTinted)`. Rien
d'ajouté au design system. Le motif apparaît trois fois (C1, C2, C2b) ; à la quatrième, le promouvoir en
`ButtonStyle` avec son composant Figma.

## 13. Où vit la règle

Un type **pur** `OnboardingGate` sous `Model/Onboarding/`, sans SwiftUI ni SwiftData, sur le patron de
`BatchScanStateMachine` et de `Model/AutoSort/`.

Entrées : inventaire synchronisé, nombre de livres, accueil répondu, nombre d'étagères, ajouts de la
session. Sorties : afficher l'accueil, afficher le bilan.

Cas à tester : compte existant qui réinstalle, session à zéro ajout, étagère créée à la main, accueil
répondu par « Plus tard », rangement indisponible.

## Convention, pas une décision

Le titre du bilan se pluralise **dans le catalogue** (`Localizable.xcstrings`, règles de pluriel), pas en
Swift. `AutoSortPlanView` fait aujourd'hui des `\\(n > 1 ? "s" : "")` en dur — à ne pas reproduire ici.
