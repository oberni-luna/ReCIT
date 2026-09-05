# 0013 — Le mur de couvertures de l'écran d'accueil

Livré le 2026-09-05 depuis le PRD `docs/prd/0011-welcome-cover-wall.md` (supprimé — voir l'histoire
git), en quatre issues : 0068 (le mur peint), 0069 (le défilement), 0070 (les vraies couvertures),
0071 (la mémoire). Maquette retenue : `B3 · Accueil · Plein écran illustré` du fichier Figma
(`265:7532`), choisie parmi six propositions dessinées le 2026-09-04.

## Ce que ça fait

L'écran d'accueil — le premier écran de l'app, et le seul qu'un visiteur voit avant de décider
s'il ouvre un compte — s'ouvre sur un **mur de couvertures de livres** qui remplit l'écran et
**dérive lentement** pendant qu'on lit : quatre colonnes, les impaires vers le bas, les paires vers
le haut, entre 10,5 et 15 pt/s, chacune depuis sa propre phase. Par-dessus, un voile vert dégradé et
le texte en crème.

Les couvertures sont **les livres derniers publiés sur inventaire.io**, récupérés à chaque
apparition de l'écran. Le mur n'est donc jamais deux fois le même, et il dit sans le dire qu'il y a
des gens de l'autre côté. La mention sous les boutons dit d'où viennent ces images et où vivra le
compte, sans nommer personne.

Avant la première réponse — et pour de bon si le serveur ne répond jamais — le mur est **peint** :
des jaquettes à plat dans les teintes de la marque, avec un pli, un bandeau et deux lignes de titre.
Aucun visuel d'éditeur n'est embarqué dans le binaire, et l'écran n'a donc pas d'état vide.

Les trois arrangements `ViewThatFits` de l'écran (tout debout, le pitch défilant sous une barre
épinglée, tout défilant) sont inchangés : ils résolvent déjà Dynamic Type jusqu'aux tailles
d'accessibilité, et le mur passe simplement derrière.

## Surface technique

**Modules purs** — `Model/CoverWall/`, sans SwiftUI ni réseau :

- `CoverWallGeometry` — pour une taille disponible, un nombre de colonnes et un instant : le
  décalage de chaque colonne, sa direction, sa phase, et l'index d'image de chaque case. Deux
  invariants, tous deux asseris : la grille **pave** le conteneur à tout instant (aucun trou
  n'apparaît en haut d'une colonne qui dérive), et le décalage **boucle** sur sa période sans saut.
- `CoverWallCatalog` — tamise le flux (pas de couverture, la même édition possédée par deux
  personnes, plus de soixante), plafonne, et construit les URL **à la taille où la couverture est
  dessinée**.

**Modèle** — `AppModels/CoverWall/CoverWallModel.swift`, `@Observable @MainActor`, construit par la
racine de composition (`RootView`) et injecté dans la branche déconnectée. Le seul modèle de l'app
qui tourne avant qu'il y ait un utilisateur, ce qui fixe ses manières : il ne lève rien vers
l'écran, ne signale rien au `AppErrorReporter`, et **ne vide jamais** le mur.

**Vues** — `Features/Components/` : `CoverWallView` (colonnes, `TimelineView`, politique
d'animation), `CoverWallSlotView` (une case : la jaquette peinte, la vraie couverture par-dessus),
`PaintedCoverView`, `CoverWallPalette`. Le voile, lui, appartient à l'écran :
`Features/Authentication/View/WelcomeWallBackground.swift`.

**Endpoint** — `GET /api/items/recent-public?limit=60`, public, sans session, **en forme chemin**
(`?action=` est déprécié côté serveur). La réponse porte `snapshot["entity:image"]` pour chaque
item : aucun appel d'entité n'est nécessaire. Vérifié le 2026-09-05 : 100 % des items ont une
couverture.

**Taille des images** — `/img/entities/<w>x<h>/<hash>` pèse ~11 ko là où `/img/entities/<hash>` en
pèse 346. Le facteur 30 vaut le détour : soixante jaquettes pleine taille, c'est une vingtaine de
mégaoctets pour dessiner un fond. Ce savoir est **local au mur** ; `absoluteImageUrl` tire encore
l'image pleine taille pour toutes les autres vignettes de l'app, ce qui reste à faire.

**Cache** — les chemins du dernier succès dans `UserDefaults`
(`coverWall.recentPublicPaths`), relus avant tout réseau et plafonnés à la lecture ; les données
d'image sont déjà en cache disque via Nuke. Hors ligne, le mur d'hier revient à la première frame.

## Les choses à savoir avant d'y toucher

**Le défilement est lu sur une horloge, pas animé.** `TimelineView(.animation)` demande à la
géométrie où sont les couvertures *maintenant*. Il n'y a donc aucune animation en vol : rien à
redémarrer au retour de veille, rien à recoller après une rotation, et mettre la timeline en pause
fige le mur exactement où il est — toujours composé. Ne pas remplacer par un
`repeatForever` : c'est précisément ce que ce choix évite.

**Quatre choses arrêtent la dérive**, et ce sont toutes le système ou l'appelant qui disent non :
`accessibilityReduceMotion`, le mode économie d'énergie (suivi en direct via la séquence asynchrone
de `NotificationCenter`, pour que brancher un chargeur relance le mur), l'app qui quitte le premier
plan, et le `isMoving` de l'appelant.

**L'écran est sombre dans les deux apparences système**, et c'est `AuthFlowView` qui l'épingle,
avec `.preferredColorScheme(path.isEmpty ? .dark : nil)`. Deux raisons de le faire là et pas dans
`WelcomeView` : l'apparence est une préférence de **scène**, donc c'est le seul endroit d'où la
status bar passe en blanc ; et `WelcomeView` reste dans la hiérarchie quand un formulaire est
poussé — déclarée là, la préférence suivrait l'écran de connexion et emmènerait le champ mot de
passe d'un utilisateur en mode clair dans le sombre avec elle. Toutes les couleurs de l'écran
restent des tokens ; elles résolvent simplement leurs valeurs sombres, ce qui donne gratuitement le
bouton crème de la maquette (`background/tinted-inverse` en sombre, c'est `green/200`).

**Le mur ne prend aucun toucher et ne répond pas au lecteur d'écran**
(`allowsHitTesting(false)`, `accessibilityHidden(true)`). Trente images sans nom entre le haut de
l'écran et le premier bouton, ce n'est pas un écran utilisable ; et un mur qui pourrait avaler un
appui coûterait à quelqu'un sa connexion. Corollaire : **pas d'identifiant `e2e` sur le mur** — un
nœud masqué au lecteur d'écran sort de l'arbre d'accessibilité, et XCUITest ne voit que cet arbre.
Le scénario end-to-end continue de prouver l'écran par `e2e.welcome.signIn`.

**La barre d'actions porte le dégradé du voile**, pas `backgroundDefault` : un fond opaque sous les
boutons perce un rectangle noir dans le mur. Son bord supérieur est transparent pour qu'il n'y ait
pas de couture, et opaque sous les boutons pour qu'une ligne du pitch ne puisse pas passer derrière
« Se connecter » et rester lisible.

**Les gouttières laissent voir le sol**, qui est vert et non le fond de fenêtre : huit points de
noir entre deux couvertures se lisent comme une grille de tuiles, huit points de vert comme de
l'ombre entre des livres.

## Décisions écartées, et pourquoi

| Écarté | Pourquoi |
|---|---|
| La bbox de Chambéry (`users/search-by-position` + `items/by-users`) | Deux allers-retours, et une bounding box codée en dur pour tous les utilisateurs du monde. Reste le plan B si `recent-public` s'avère trop pauvre : ~499 items autour de Chambéry, 96 sur 100 avec couverture. |
| La localisation réelle de l'appareil | Une autorisation système sur l'écran d'accueil, avant que le visiteur sache ce qu'est l'app. |
| Des couvertures embarquées dans le bundle | Ce sont des visuels d'éditeurs distribués dans un binaire. Les jaquettes peintes font le même travail sans la question de droits. |
| Un fond vert plein comme premier état | C'est exactement le « trop simple » que cette fonctionnalité corrige. |
| Le mur sur les écrans de formulaire | Ils gardent leur fond clair et leur composant de champ déjà recetté. On ne met pas un fond animé sous un champ mot de passe. |
| Un drapeau de déploiement | L'écran dégrade proprement seul ; un flag serait un chemin de plus à tester. |
| Nommer les propriétaires des couvertures | `recent-public` renvoie aussi leurs pseudos. On n'affiche pas d'identifiants de tiers sur un écran pré-login. |

## Tests

- `CoverWallGeometryTests` — pavage à quatre largeurs et cinq instants, continuité au franchissement
  de période, retour au point de départ après une période, vitesse par colonne, directions
  alternées, phases distinctes, mur figé, et les conteneurs dégénérés (taille nulle, une colonne).
- `CoverWallCatalogTests` — tamisage, déduplication, plafond, ordre déterministe, et les cinq formes
  d'URL (chemin d'entité, chemin déjà dimensionné, Wikimedia absolu, hash nu, chaîne vide).
- `CoverWallModelTests` — décodage d'une réponse `recent-public` **réelle capturée**, gardée
  verbatim jusqu'aux champs que l'app ne lit pas ; forme chemin de l'appel ; et les cinq façons
  d'échouer sans vider le mur (transport, 404, 429, 500, payload illisible, flux sans couverture).
  Plus le cache : relecture, remplacement, plafond, et l'échec qui ne l'efface pas.

Le défilement lui-même se juge à l'œil sur simulateur — mais sa formule est testée.

## Ce qui reste ouvert

- **L'état « inventaire vide »** (proposition A3 du Figma) veut le même mur sous un voile clair.
  `CoverWallView` est écrit pour resservir (colonnes, allure, mouvement en paramètres), mais c'est
  un écran clair, connecté, avec barre de navigation et barre d'onglets : voile, contraste et
  hiérarchie sont à rejouer.
- **Le redimensionnement des images ailleurs dans l'app** — `absoluteImageUrl` tire la pleine
  taille pour chaque vignette.
- **La version sombre système de l'accueil** n'existe pas et n'a pas à exister : l'écran est sombre
  par construction. Mais la maquette Figma n'a, elle, qu'une variante Light.
