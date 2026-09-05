# Les vraies couvertures, depuis recent-public

## Parent

`docs/prd/0011-welcome-cover-wall.md`

## What to build

Le mur montre les livres derniers ajoutés publiquement sur inventaire.io, récupérés en **une**
requête publique non authentifiée à chaque apparition de l'accueil :
`GET /api/items/recent-public?limit=60`. Chaque item porte `snapshot["entity:image"]`, un chemin
`/img/entities/<hash>` — aucun appel d'entité n'est nécessaire.

Les images sont demandées **redimensionnées par le serveur** (`/img/entities/<w>x<h>/<hash>`, deux
fois la taille de cellule pour le Retina) : ~11-20 ko l'unité au lieu de ~346 ko. Ce savoir reste
local au mur ; le cas général de `absoluteImageUrl` est un autre chantier.

Les couvertures remplacent les couvertures peintes **case par case**, en fondu court, avec un
décalage aléatoire de 0 à 400 ms : le mur se révèle au lieu de clignoter d'un bloc. Une case sans
image disponible garde sa couverture peinte, jamais un trou.

La mention sous les boutons est réécrite pour dire d'où viennent les images et où vivra le compte,
sans afficher aucun pseudo — en français et en anglais.

## Acceptance criteria

- [ ] `CoverWallCatalog`, module pur : depuis la réponse `recent-public`, il produit une liste
      ordonnée et déterministe de chemins de couverture — items sans image écartés, doublons
      retirés, plafond respecté — et attribue une teinte peinte déterministe aux cases restantes.
- [ ] `CoverWallModel`, `@Observable @MainActor`, construit avec un `APIServicing` : appelle
      l'endpoint sous sa forme **chemin** (jamais `?action=`), décode le DTO, expose la liste de
      couvertures. Ses méthodes ne renvoient pas la donnée d'affichage — la vue observe l'état
      (ADR 0001).
- [ ] L'accueil rafraîchit le mur à chaque apparition, y compris au retour après une déconnexion.
- [ ] Les URLs d'image demandées portent la taille (`/img/entities/176x264/<hash>` ou la taille
      réellement calculée depuis la cellule), et passent par le chargeur d'images déjà en place.
- [ ] Fondu case par case, décalage aléatoire 0-400 ms ; le mur peint reste visible sous les cases
      pas encore chargées, et une image qui échoue laisse sa couverture peinte en place.
- [ ] La mention est réécrite dans `Localizable.xcstrings`, en `fr` et en `en`, sans pseudo.
- [ ] Tests `CoverWallCatalog` : items sans image, doublons, plafond, ordre déterministe,
      attribution stable des teintes peintes.
- [ ] Tests `CoverWallModel` via `MockURLProtocol`, sur un payload `recent-public` **réel
      capturé** rangé en fixture : décodage complet, et échec réseau qui laisse le mur en place
      plutôt que de le vider.
- [ ] Aucun appel réseau n'est fait avec des identifiants de session : l'endpoint est public et
      l'écran est pré-login.
- [ ] Le projet compile et la cible de test passe sur `iPhone 17`.

## Blocked by

- `docs/issues/0068-painted-cover-wall-behind-the-welcome-screen.md`
