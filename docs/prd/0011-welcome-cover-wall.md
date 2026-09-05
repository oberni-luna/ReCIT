# Un mur de couvertures, vivant, derrière l'écran d'accueil

## Problem Statement

L'écran d'accueil est le premier écran de l'app, et le seul qu'un visiteur voit avant de décider
s'il ouvre un compte. Aujourd'hui il dit ce que fait l'app — inventorier, prêter, emprunter — avec
un titre, une accroche, trois lignes et deux boutons, sur fond blanc. C'est juste, c'est lisible,
et c'est froid : rien à l'écran ne ressemble à un livre, rien ne prouve qu'il y a des gens et des
bibliothèques derrière l'app. Une app dont le sujet est le livre ouvre sur une page de texte.

Le même reproche vaut, en plus discret, pour l'état « inventaire vide » — mais c'est un autre écran
et il n'est pas traité ici.

## Solution

L'accueil s'ouvre sur un **mur de couvertures** qui occupe tout l'écran et **défile lentement**
pendant qu'on lit : quatre colonnes, les impaires vers le bas, les paires vers le haut, à des
vitesses légèrement différentes. Par-dessus, un voile vert dégradé (`green/900`) et le texte en
crème : le nom, l'accroche, les trois usages, les deux portes.

Les couvertures ne sont pas décoratives : ce sont **les livres derniers ajoutés publiquement sur
inventaire.io**, récupérés en une requête publique à chaque ouverture de l'écran. Le mur n'est donc
jamais deux fois le même, et il dit, sans le dire, qu'il y a du monde de l'autre côté. Une mention
sous les boutons explique d'où viennent les images et où vivra le compte.

Avant que le réseau réponde — et définitivement, si l'API est injoignable — le mur se compose de
**couvertures peintes** générées en code, dans la grammaire déjà dessinée pour les étagères :
aplats verts, rouge brique, jaune, parchemin, bandeau et lignes de titre. L'écran n'est donc jamais
vide, jamais en attente, et l'app n'embarque aucun visuel d'éditeur.

## User Stories

1. En tant que visiteur qui ouvre l'app pour la première fois, je veux voir des couvertures de
   livres dès la première image affichée, pour comprendre en une seconde de quoi parle cette app.
2. En tant que visiteur, je veux que le fond bouge doucement pendant que je lis, pour sentir que
   l'app est vivante sans être distrait de ce que je lis.
3. En tant que visiteur, je veux que le texte reste parfaitement lisible par-dessus les images,
   pour ne pas avoir à plisser les yeux sur une phrase posée sur une couverture claire.
4. En tant que visiteur, je veux que les boutons « Se connecter » et « Créer un compte » restent
   évidents et atteignables, pour que la décoration ne me coûte pas l'action.
5. En tant que visiteur curieux, je veux savoir d'où viennent ces couvertures, pour ne pas croire
   qu'on me montre un catalogue commercial.
6. En tant que visiteur, je veux comprendre que le compte que je crée est un compte inventaire.io,
   pour savoir où vivront mes données avant de m'inscrire.
7. En tant que visiteur hors ligne, je veux un écran d'accueil aussi soigné qu'en ligne, pour ne
   pas juger l'app sur un fond vert plat.
8. En tant que visiteur au deuxième lancement sans réseau, je veux retrouver le mur que j'avais vu,
   pour que l'app ne régresse pas quand le train entre dans un tunnel.
9. En tant qu'utilisateur qui a activé « Réduire les animations », je veux un mur immobile, pour
   que mon réglage système soit respecté.
10. En tant qu'utilisateur en mode économie d'énergie, je veux que l'écran ne dépense pas de
    batterie à animer un fond, pour que l'app respecte l'état de mon téléphone.
11. En tant qu'utilisateur qui utilise une grande taille de texte, je veux lire l'intégralité du
    pitch et de la mention, pour que rien ne soit tronqué au nom de la composition.
12. En tant qu'utilisateur en taille d'accessibilité maximale, je veux que les deux boutons restent
    accessibles, pour ne pas avoir à deviner où appuyer.
13. En tant qu'utilisateur de VoiceOver, je veux que le mur soit ignoré par le lecteur d'écran,
    pour ne pas parcourir soixante images sans nom avant d'atteindre les boutons.
14. En tant qu'utilisateur qui appuie sur « Se connecter », je veux arriver sur un formulaire sobre
    et lisible, pour taper mon mot de passe sans fond animé sous les doigts.
15. En tant qu'utilisateur en mode clair système, je veux le même accueil que les autres, pour que
    l'écran garde son identité de couverture de livre plutôt que de suivre mon réglage.
16. En tant que visiteur sur une connexion lente, je veux que l'écran s'affiche immédiatement et se
    précise ensuite, pour ne pas attendre devant un écran en construction.
17. En tant que visiteur qui revient sur l'accueil après s'être déconnecté, je veux un mur
    rafraîchi, pour voir ce que la communauté a ajouté depuis.
18. En tant que visiteur, je veux que les couvertures apparaissent en fondu et non d'un bloc, pour
    que la mise à jour se lise comme une mise au point et non comme un clignotement.
19. En tant que visiteur attentif, je ne veux voir ni case vide, ni couverture répétée côte à côte,
    ni damier parfaitement aligné, pour que le mur ressemble à une bibliothèque et non à une grille.
20. En tant que visiteur qui laisse l'app en arrière-plan puis revient, je veux retrouver le mur
    sans saut ni ressaut, pour que l'écran n'ait pas l'air de redémarrer.
21. En tant que personne dont les livres sont publics sur inventaire.io, je veux que mes couvertures
    puissent apparaître sans que mon pseudo soit affiché sur l'écran d'accueil d'une app, pour rester
    maître de mon exposition.
22. En tant que développeur, je veux que la géométrie du mur soit calculée par un module testable
    sans SwiftUI, pour qu'un réglage de vitesse ne casse pas la boucle en silence.
23. En tant que développeur, je veux que le mur soit un composant réutilisable, pour que l'état
    « inventaire vide » puisse s'en servir sans réécriture.
24. En tant que développeur, je veux que l'app ne télécharge que des vignettes, pas des images
    pleine taille, pour que l'écran d'accueil ne coûte pas vingt mégaoctets.
25. En tant que mainteneur du scénario end-to-end, je veux un identifiant d'accessibilité sur le
    mur, pour que le compte-rendu prouve que l'écran s'est bien affiché.

## Implementation Decisions

### Source des couvertures

- **Une seule requête publique, non authentifiée** : `GET /api/items/recent-public?limit=60`.
  Elle renvoie `{ items, users }` ; chaque item porte `snapshot["entity:image"]`, un chemin
  `/img/entities/<hash>`. Aucun appel d'entité n'est nécessaire.
- La forme `?action=` est proscrite (dépréciée côté serveur) : chemin canonique uniquement.
- **Écartée** : la piste bbox (`/api/users/search-by-position` puis `/api/items/by-users`), qui
  demande deux allers-retours et une bounding box de Chambéry codée en dur pour tous les
  utilisateurs du monde. Elle reste le plan B documenté si `recent-public` s'avère trop pauvre.
- **Écartée** : la localisation réelle de l'appareil, qui ferait surgir une autorisation système
  sur l'écran d'accueil, avant que le visiteur sache ce qu'est l'app.
- Les images sont demandées **redimensionnées par le serveur** : `/img/entities/<w>x<h>/<hash>`
  renvoie ~11-20 ko de WebP là où la forme sans taille en renvoie ~346 ko. Le mur porte ce savoir
  localement ; généraliser le redimensionnement à `absoluteImageUrl` et aux vignettes de l'app est
  un autre chantier (voir *Out of Scope*).
- Rafraîchissement **à chaque apparition de l'écran d'accueil**, y compris après déconnexion.

### Persistance et repli

- Les chemins du dernier appel réussi sont persistés dans `UserDefaults` (quelques ko). Au
  lancement, ils sont affichés immédiatement, avant tout réseau ; les données d'image, elles, sont
  déjà en cache disque via Nuke.
- Repli, dans l'ordre : liste persistée → couvertures peintes générées en code. **Aucun visuel
  embarqué dans le bundle** : ce sont des images d'éditeurs, et leur distribution dans un binaire
  est une question de droits qu'on n'ouvre pas pour un fond d'écran.
- Une case sans image disponible reçoit une couverture peinte, jamais un trou.

### Modules

- **`CoverWallGeometry`** — module pur, sans SwiftUI ni Foundation réseau. Entrées : taille
  disponible, taille de couverture, gouttière, nombre de colonnes, nombre d'images, temps écoulé.
  Sorties : le décalage vertical de chaque colonne (bouclé, donc sans couture), sa direction, sa
  phase initiale, et l'index d'image de chaque case. Garantit qu'aucune colonne n'est vide, que
  deux colonnes voisines ne sont pas en phase, et que la boucle est continue quand l'offset
  franchit une période. Cas limites : zéro image, une seule image, moins d'images que de cases.
- **`CoverWallCatalog`** — module pur. Transforme la réponse `recent-public` en une liste ordonnée
  de chemins de couverture : rejette les items sans image, déduplique, plafonne, et attribue de
  façon déterministe une teinte peinte aux cases restantes. Déterministe : le même jeu d'entrée
  donne le même mur, ce qui rend l'écran testable et la recette reproductible.
- **`CoverWallModel`** — `@Observable @MainActor`, dans `AppModels/`, construit avec un
  `APIServicing`. Appelle l'endpoint, décode le DTO, écrit et relit le cache, expose la liste de
  couvertures. Aucune valeur de retour lue par la vue pour l'affichage : la vue observe l'état.
- **`CoverWallView`** et **`PaintedCoverView`** — composants réutilisables. `CoverWallView` prend
  ses couvertures, ses vitesses et sa taille de cellule en paramètres, pour que l'état
  « inventaire vide » puisse s'en servir plus tard sans réécriture. Le défilement est piloté par
  un `TimelineView(.animation)` qui calcule les offsets depuis la date — pas de
  `repeatForever` : rien à redémarrer au retour de veille, rien à recoller après un changement de
  taille.
- **`WelcomeView`** — modifiée, pas réécrite. Ses trois arrangements `ViewThatFits` (tout debout,
  pitch défilant sous une barre épinglée, tout défilant) sont conservés tels quels : ils résolvent
  déjà le cas Dynamic Type. Le mur devient son fond, sous le voile.

### Écran

- **Toujours sombre, hors thème système** : voile `green/900` dégradé, texte crème, status bar et
  home indicator forcés en apparence sombre. Même raisonnement que `ShelfPalette` — l'écran dépeint
  un objet physique, pas du chrome d'interface, et un voile clair délave les couvertures.
- Le mur est **décoratif** pour l'accessibilité : masqué au lecteur d'écran, et porteur d'un
  identifiant `e2e.welcome.coverWall` pour le scénario end-to-end.
- **Politique d'animation** : arrêt sur `accessibilityReduceMotion`, arrêt en mode économie
  d'énergie (`ProcessInfo.processInfo.isLowPowerModeEnabled`, et sa notification de changement),
  arrêt hors écran et en arrière-plan. Le mur reste alors composé, simplement immobile.
- **Apparition des couvertures** en fondu court, case par case, avec un décalage aléatoire de 0 à
  400 ms, pour que le passage du mur peint au mur réel se lise comme une mise au point.
- **Mention** sous les boutons : d'où viennent les couvertures, et où vit le compte. Sans pseudos —
  on n'affiche pas d'identifiants de tiers sur un écran pré-login. Les chaînes existantes sont
  localisées en français et en anglais ; la nouvelle formulation l'est aussi.
- Périmètre : **l'accueil seulement**. `LoginView`, `CreateAccountView`, `ForgotPasswordView` et
  `PasswordResetSentView` gardent leur fond clair et leur composant de champ déjà recetté.

## Testing Decisions

Un bon test ici décrit un comportement observable : « le mur ne laisse jamais de case vide », « la
boucle est continue au passage de période », « une réponse sans image ne fait pas disparaître le
mur ». Pas de test sur la façon dont un offset est calculé en interne, pas d'assertion sur une
hiérarchie de vues.

- **`CoverWallGeometry`** — testé sans SwiftUI, comme `SortGridMetricsTests` et
  `ShelfBooksLayoutTests` : nombre de cases couvrant l'écran, continuité de l'offset au franchissement
  d'une période, directions alternées, phases initiales distinctes, et les trois cas limites (zéro
  image, une image, moins d'images que de cases).
- **`CoverWallCatalog`** — items sans image écartés, doublons retirés, plafond respecté, ordre
  déterministe, et attribution des teintes peintes stable d'un appel à l'autre. Prior art :
  `ShelfMappingValidatorTests`, `SortProjectionTests`.
- **`CoverWallModel`** — décodage d'un payload `recent-public` **réel capturé** et rangé en
  fixture, via `MockURLProtocol` (prior art : `AuthServiceTests`, `SpineStripLoaderTests`,
  `APIServiceTests`) ; écriture puis relecture du cache ; et le cas d'échec réseau, qui doit laisser
  la liste persistée en place plutôt que la vider.
- Le défilement lui-même se juge à l'œil sur simulateur — mais sa formule, elle, est testée.

## Out of Scope

- **L'état « inventaire vide » (proposition A3)**. Il veut le même mur, et `CoverWallView` est écrit
  pour le resservir, mais c'est un écran clair, connecté, avec barre de navigation et barre
  d'onglets : voile, contraste et hiérarchie sont à rejouer. Issue séparée.
- **Le redimensionnement des images dans le reste de l'app**. `absoluteImageUrl` tire aujourd'hui
  l'image pleine taille pour toutes les vignettes ; c'est un vrai gain de performance, mais il
  touche chaque écran à images. Tâche à part.
- **Les écrans de formulaire du flux pré-login** — inchangés.
- **La piste bbox / Chambéry** et **la localisation appareil** — documentées comme écartées, pas
  implémentées.
- **Toute interaction sur le mur** : pas d'appui sur une couverture, pas de nom d'auteur, pas de
  pseudo. Le mur ne réagit pas.
- **Un drapeau de déploiement**. L'écran dégrade proprement seul ; un flag serait un chemin de plus
  à tester.

## Further Notes

- Faits d'API vérifiés le 2026-09-05 sans session : `recent-public` respecte `limit`, renvoie 100 %
  de ses items avec une couverture, et inclut les users ; `search-by-position` sur la bbox de
  Chambéry renvoie une vingtaine de comptes dont `OlivierB_test`, et `items/by-users` ~499 items
  dont 96 sur 100 avec couverture. Le serveur avertit que `?action=` est déprécié.
- La maquette de référence est la frame `B3 · Accueil · Plein écran illustré · Light` de la section
  `Propositions · Chaleur` du fichier Figma (`265:7532`) — mur, voile, texte crème, bouton papier.
  Les autres propositions de cette section (A1-A3, B1-B2) ne sont pas retenues.
- Le mur consomme des données publiques de tiers. C'est le modèle d'inventaire.io — une base
  ouverte — mais l'écran le dit, et n'affiche aucun identifiant.
