# Modifier une édition, depuis la fiche livre

Livré le 2026-10-25, en autopilot, sur `main`, en un commit : une seule tranche, donc ni PRD ni issues. Maquette :
la section Figma `Fiche livre · Données bibliographiques` (`744:2382`), frames `744:2383` (toute la longueur) et
`744:2482` (défilée jusqu'en bas), spec `744:24535`.

## Ce que c'est

La fiche d'une édition se termine sur une section **« Données bibliographiques »** d'une seule rangée, **« Modifier »**,
teintée, sans glyphe ni chevron, comme « Toutes les transactions » dans le Profil. Elle est là pour toute édition, que
je la possède ou non : les données d'inventaire.io sont ouvertes à tout compte. La seule exception est une édition
Wikidata (`wd:`), qui ne se modifie que via OAuth Wikidata, et l'app n'en a pas.

« Modifier » ouvre une feuille, **« Modifier l'édition »**, dans la forme de `V3 · Nouvelle édition` :

- l'encart « Données bibliographiques » et le « ? » qui ouvre l'aide, comme dans la création ;
- la couverture actuelle dans son cadre, avec le même menu : appareil photo, Photos, Fichiers, une adresse web
  (« Image depuis une URL », poussée dans la feuille), et « Retirer » ;
- l'ISBN, affiché sans être modifiable ;
- le titre de l'édition, obligatoire, et son sous-titre, facultatif ;
- **« Enregistrer »** au pied du formulaire, désactivé tant que rien n'a changé ou que le titre est vide.

À l'ouverture, un spinner s'affiche pendant la lecture de l'édition. Si la lecture échoue, l'écran « Impossible
d'ouvrir ce livre » propose « Réessayer ». Une couverture qui ne se télécharge pas laisse le cadre vide, et une image
posée dedans remplace celle de l'édition.

L'enregistrement attend la réponse du serveur. S'il réussit, la feuille se ferme et la fiche montre aussitôt le
nouveau titre, le nouveau sous-titre ou la nouvelle couverture. S'il échoue, un bandeau en tête de formulaire dit
pourquoi, en trois cas : la session a expiré, inventaire.io a refusé, ou il n'a pas répondu. Tout ce qui a été écrit
reste à l'écran, et « Réessayer » n'envoie que ce qui n'est pas passé.

## Surface technique

**Sur le fil.**
- Lecture : `GET /api/entities/by-uris?uris=<uri>&attributes=info|claims`, sans cookie (`publicAPIService`). Un
  `isbn:` y est redirigé vers son `inv:`, l'uri que `update-claim` accepte. Les claims lus sont `wdt:P1476` (titre),
  `wdt:P1680` (sous-titre), `invp:P2` (le hash de la couverture), `wdt:P212` et `wdt:P957` (ISBN).
- Écriture : un `PUT /api/entities/update-claim` par claim modifié, dans l'ordre titre, sous-titre, couverture, avec
  `{ uri, property, old-value, new-value }`. Un côté absent est omis du corps : sans ancienne valeur, le claim est
  ajouté ; sans nouvelle valeur, il est retiré. Contrat vérifié sur la spec live (v5.1.1) et sur le source Codeberg
  (`update_claim.ts`, `update_inv_claim.ts`).
- Couverture : `POST /api/images/upload?container=entities` d'abord. Le chemin renvoyé se termine par le hash que
  `invp:P2` attend (`EntityImageHash`). Contrairement à la création, une adresse web n'est jamais envoyée telle
  quelle : `update-claim` veut un hash, donc les octets sont uploadés.

**Types purs (`Model/Creation/`).**
- `EditionClaims` : ce que le serveur tient. Il porte l'uri canonique, le titre, le sous-titre, le hash et l'ISBN
  affiché, plus `canEdit(uri:)`.
- `EditionEdit` : le brouillon du formulaire. `coverData` est le binding du cadre ; `Cover` vaut `unchanged`,
  `replaced` ou `removed`. Il expose `claimUpdates`, `coverToUpload`, `isSaveable`, et `landed(_:)`, qui fait
  avancer `original` d'un claim passé.
- `EditionClaimUpdate` (le corps envoyé), `EditableEditionProperty`, `EntityImageHash`, `EditionSaveFailure` (l'erreur
  et l'édition telle qu'elle est arrivée).
- `EditableEditionDTO` (`AppModels/Creation/`) décode cette lecture de `by-uris`.

**Modèle.** `EntityCreationModel` gagne `editableEdition(uri:)`, `coverURL(hash:)`, `saveEdition(_:)` et
`apply(_:since:to:modelContext:)`. Aucun nouveau modèle d'environnement.

**Vues.**
- `BookBibliographicDataSection` (`Features/Book/`) et sa place dans `BookDetailView`, avec `.sheet(item:)`.
- `Features/EditEdition/` : `EditEditionFlowView` (la feuille, sa pile, chargement et enregistrement),
  `EditEditionView` (le formulaire), `EditEditionStep`, et `CreateBookFailure+EditEdition` (les textes d'échec).

**Factorisé au passage.**
- `CreateBookCoverRow` ne connaît plus `NewBookDraft` : il prend un ISBN, son libellé et un `Binding<Data?>`.
  `NewBookDraft.cover` est le binding de la création ; c'est lui qui oublie l'upload précédent.
- `CoverURLView` prend un titre de recherche et un ISBN, et rend l'image avec son adresse ; chaque formulaire décide
  de ce qu'il envoie. `NewBookDraft.coverSearchTitle` reprend l'ancienne logique.
- `CreateBookFailureBanner` prend un titre et une explication ; `init(failure:)` reste pour la création.

**Chaînes.** `book.bibliographic_data`, `edit_edition.title`, `.isbn`, `.subtitle_field` et
`edit_edition.failure.{account,refused,network}.{title,body}`, en anglais et en français. `action.edit`,
`action.save`, `create_book.title_field` et `create_book.retry` sont réutilisées.

**Tests.** `EditionEditTests` (9), `EditionClaimsTests` (5), `EntityCreationModelEditionTests` (6). `MockAPIService`
enregistre les corps envoyés et peut faire échouer un envoi précis (`sentPayloads`, `onSend`).

## Décisions notables

- **Lu sur le serveur, pas dans le store.** `update-claim` ne remplace une valeur que si on lui dit laquelle, et
  l'`Edition` locale ne garde qu'un titre d'affichage et une URL d'image : ni l'uri `inv:`, ni le hash, ni les claims.
- **Pas d'optimisme**, comme pour un nouveau livre. Ce sont des données publiques : une modification affichée puis
  refusée aurait laissé croire qu'elle était faite.
- **Un claim passé n'est pas renvoyé.** Chaque claim est une requête, donc un titre peut passer et une couverture
  échouer. `landed(_:)` fait avancer l'état de départ, et le hash d'une image déjà uploadée est gardé : réessayer
  n'envoie que le reste, sans uploader deux fois la même image.
- **Une nouvelle couverture n'est pas un ornement ici.** À la création, un upload raté coûte une image et le livre
  est publié quand même. Ici, l'image peut être toute la modification demandée, donc son échec est un échec.
- **Le store n'est écrit qu'avec ce qui a bougé**, et après la réponse du serveur, sans relecture qui pourrait
  tomber sur un cache périmé. Une image locale venue d'ailleurs que de `invp:P2` n'est pas effacée parce que le
  hash est absent. Après un échec partiel, ce qui est passé est aussi reporté dans le store.
- **Le sous-titre est dans le formulaire**, alors que `V3` ne l'a pas : il s'affiche sous le titre de la fiche, et le
  corriger est le cas le plus fréquent après le titre.

## Non fait, non vérifié

- **Aucun enregistrement réel.** Sur le simulateur (iPhone 17, iOS 26.4, compte connecté), la section s'affiche en
  bas de la fiche, la feuille s'ouvre avec le titre, l'ISBN et la couverture lus en production, et « Enregistrer »
  s'active au premier changement. La feuille a été fermée sans rien envoyer : enregistrer aurait modifié une
  édition publique. Le chemin d'écriture n'est couvert que par les tests sur `MockAPIService`.
- **Pas d'étape e2e**, pour la même raison : le scénario tourne contre inventaire.io en production.
- **Hors du formulaire** : l'œuvre, les auteur·ices, l'éditeur, la date, le nombre de pages, la langue. Ils restent à
  modifier sur inventaire.io.
- **Les vignettes d'inventaire** tirent leur titre et leur image du snapshot de l'item : elles ne changent qu'à la
  synchronisation suivante.
- **Pas de passe en français** sur le simulateur : il est en anglais.
- **Android** : non porté.

## Écarts avec Figma (le code fait foi)

| Point | Figma | Code |
|---|---|---|
| Le formulaire | non maquetté ; la spec renvoie à `V3 · Nouvelle édition` | `V3` sans « Édition de », avec un champ sous-titre et « Enregistrer » au lieu de « Publier » |
| Libellé de l'ISBN | « ISBN, lu sur le code-barres » (`V3`) | « ISBN » |
