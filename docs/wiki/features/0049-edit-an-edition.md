# Modifier une édition, depuis la fiche livre

Livré le 2026-10-25, sur `main` : d'abord en autopilot, en un commit (une seule tranche, donc ni PRD ni issues),
puis complété le même jour par l'œuvre et ses auteur·ices, à la demande, après un essai sur « Penss et les plis du
monde », dont l'œuvre n'avait pas d'auteur. Maquette : la section Figma `Fiche livre · Données bibliographiques`
(`744:2382`), frames `744:2383` (toute la longueur) et `744:2482` (défilée jusqu'en bas), spec `744:24535` ; pour la
recherche de l'œuvre, `V2 · Quelle œuvre ?` de `Nouveau livre v2` (`712:21368`).

> **Prolongée le même jour par la [feature 0050](0050-every-bibliographic-datum.md)** : le formulaire montre
> désormais toutes les propriétés de l'édition, liste ses œuvres, ajoute les auteur·ices dans « Modifier l'œuvre »
> et épingle « Enregistrer » ; la fiche finit sur une rangée « Données bibliographiques ». Ce qui suit décrit l'état
> d'avant.

## Ce que c'est

La fiche d'une édition se termine sur une section **« Données bibliographiques »** d'une seule rangée, **« Modifier »**,
teintée, sans glyphe ni chevron, comme « Toutes les transactions » dans le Profil. Elle est là pour toute édition, que
je la possède ou non : les données d'inventaire.io sont ouvertes à tout compte. La seule exception est une édition
Wikidata (`wd:`), qui ne se modifie que via OAuth Wikidata, et l'app n'en a pas.

« Modifier » ouvre une feuille, **« Modifier l'édition »**, dans la forme de `V3 · Nouvelle édition` :

- l'encart « Données bibliographiques » et le « ? » qui ouvre l'aide, comme dans la création ;
- **« Édition de »** : l'œuvre dont c'est une édition, avec ses auteur·ices sur la ligne du dessous (voir plus bas) ;
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

### L'œuvre et ses auteur·ices

« Édition de » montre l'œuvre comme `V3` la montre, sur une rangée à chevron. La toucher pousse **la recherche de
l'œuvre de la création** (`WorkSearchView`, `V2`), avec ses propres mots avant toute saisie (« De quelle œuvre
est-ce une édition ? ») :

- **une œuvre trouvée** remplace celle de l'édition. Reprendre celle qu'elle a déjà n'est pas un changement ;
- **« Créer l'œuvre « … » »** revient au formulaire avec un champ « Titre de l'œuvre », pré-rempli par la recherche.
  Une œuvre créée doit avoir un titre et au moins un·e auteur·ice pour que « Enregistrer » s'active.

Sous l'œuvre, **« Ajouter un·e auteur·ice »** pousse la recherche d'auteur·ices de la création (`AuthorPickerView`) :
une personne qu'inventaire.io connaît, ou une à créer sous le nom tapé. Les auteur·ices ajouté·es sont listé·es
jusqu'à l'enregistrement (« Créé·e sur inventaire.io à l'enregistrement » pour une nouvelle personne) et se retirent
d'un glissement. Quelqu'un qui est déjà sur l'œuvre, ou déjà ajouté, n'est pas ajouté deux fois : même uri, ou même
nom quand l'uri manque (la recherche d'œuvres ne donne que les noms). Une œuvre Wikidata (`wd:`) n'accepte pas
d'auteur·ice d'ici, et le pied de section le dit ; on peut toujours choisir une autre œuvre.

À l'enregistrement, ce qui doit exister avant d'être nommé passe d'abord : la couverture, les auteur·ices
nouveaux·elles, l'œuvre nouvelle (avec ses auteur·ices). Viennent ensuite les claims de l'édition (titre, sous-titre,
couverture, œuvre), puis un claim d'auteur·ice par personne ajoutée à l'œuvre. Après coup, l'œuvre est relue
(`EntityModel.refreshWork`) et remplace celle de l'édition dans le store quand elle a changé, pour que la fiche nomme
qui l'a écrite.

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
- L'œuvre : lue avec `by-uris?uris=<œuvre>&attributes=labels|claims&lang=fr&relatives=wdt:P50`, sans cookie, pour son
  titre et ses auteur·ices (noms et uris). Changée par `update-claim` sur `wdt:P629` de l'édition. Une auteur·ice
  ajoutée l'est par `update-claim` sur `wdt:P50` de l'œuvre, sans ancienne valeur.
- Création : `POST /api/entities` avec `{ labels: { <langue>: <nom> }, claims }` — `wdt:P31` `wd:Q5` pour une
  personne, `wd:Q47461344` (œuvre littéraire) et `wdt:P50` pour une œuvre, les classes que le site donne aux entités
  qu'il crée. La réponse porte l'entité créée sous `entity`, dont on lit l'uri (`create.ts` sur Codeberg). La langue
  des labels est celle de l'édition (`originalLang`), à défaut celle du téléphone.

**Types purs (`Model/Creation/`).**
- `EditionClaims` : ce que le serveur tient. Il porte l'uri canonique, le titre, le sous-titre, le hash, l'ISBN
  affiché, l'uri de l'œuvre et la langue des labels, plus `canEdit(uri:)`.
- `EditionWork` : l'œuvre telle que le formulaire la montre (uri, titre, auteur·ices en `NewBookAuthor`), et si elle
  accepte des auteur·ices (`inv:`).
- `EditionEdit` : le brouillon du formulaire. `coverData` est le binding du cadre ; `Cover` vaut `unchanged`,
  `replaced` ou `removed` ; `WorkChange` vaut `unchanged`, `existing` ou `new`, avec `newWorkTitle` et
  `addedAuthors`. `nextStep` donne la prochaine requête (`EditionEditStep` : upload, création d'auteur·ice, création
  d'œuvre, claim) ; `coverUploaded`, `authorCreated`, `workCreated` et `landed(_:)` enregistrent ce qui est passé.
- `EditionClaimUpdate` (le corps envoyé), `EditableClaimProperty` (titre, sous-titre, couverture, œuvre, auteur·ice),
  `EntityImageHash`, `EditionSaveFailure` (l'erreur et l'édition telle qu'elle est arrivée).
- `EditableEditionDTO` et `EntityCreationDTO` (`AppModels/Creation/`) : la lecture de `by-uris`, et la création d'une
  entité.

**Modèle.** `EntityCreationModel` gagne `editableEdition(uri:)`, `describeWork(uri:)`, `coverURL(hash:)`,
`saveEdition(_:)` (une boucle sur `nextStep`, bornée) et `apply(_:since:to:modelContext:)`. Aucun nouveau modèle
d'environnement.

**Vues.**
- `BookBibliographicDataSection` (`Features/Book/`) et sa place dans `BookDetailView`, avec `.sheet(item:)`.
- `Features/EditEdition/` : `EditEditionFlowView` (la feuille, sa pile, chargement et enregistrement),
  `EditEditionView` (le formulaire), `EditEditionStep` (œuvre, auteur·ice, couverture par URL),
  `EditEditionAddedAuthorRow`, `EditEditionActionRow`, et `CreateBookFailure+EditEdition` (les textes d'échec).
- `WorkSearchView` prend en option le titre et le message de son état vide.

**Factorisé au passage.**
- `CreateBookCoverRow` ne connaît plus `NewBookDraft` : il prend un ISBN, son libellé et un `Binding<Data?>`.
  `NewBookDraft.cover` est le binding de la création ; c'est lui qui oublie l'upload précédent.
- `CoverURLView` prend un titre de recherche et un ISBN, et rend l'image avec son adresse ; chaque formulaire décide
  de ce qu'il envoie. `NewBookDraft.coverSearchTitle` reprend l'ancienne logique.
- `CreateBookFailureBanner` prend un titre et une explication ; `init(failure:)` reste pour la création.

**Chaînes.** `book.bibliographic_data`, `edit_edition.title`, `.isbn`, `.subtitle_field`,
`edit_edition.failure.{account,refused,network}.{title,body}` et `edit_edition.work.{choose,change,add_author,
new_author,help,new_help,wikidata_help,search_empty.title,search_empty.message}`, en anglais et en français.
`action.edit`, `action.save`, `create_book.title_field`, `create_book.new_work.title_field`, `create_book.edition.of`
et `create_book.retry` sont réutilisées.

**Tests.** `EditionEditTests` (9), `EditionEditWorkTests` (9), `EditionClaimsTests` (6),
`EntityCreationModelEditionTests` (9). `MockAPIService` enregistre les corps envoyés, peut faire échouer un envoi
précis (`sentPayloads`, `onSend`) et répondre différemment à deux appels du même endpoint (`stub(_:jsonSequence:)`).

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
- **Ce qui doit exister passe d'abord, une seule fois.** Une auteur·ice créée garde son uri dans le brouillon, une
  œuvre créée devient l'œuvre choisie : un nouvel essai après un échec ne crée pas de doublon sur une base publique.
- **L'œuvre se crée dans le formulaire**, pas sur un écran « Nouvelle œuvre » poussé : il n'y a que son titre et ses
  auteur·ices à donner, et le formulaire a déjà la place pour les auteur·ices.
- **On ajoute des auteur·ices, on n'en retire pas.** Retirer quelqu'un d'une œuvre partagée par d'autres éditions est
  une autre décision, laissée au site.

## Non fait, non vérifié

- **Aucun enregistrement réel.** Sur le simulateur (iPhone 17, iOS 26.4, compte connecté), la section s'affiche en
  bas de la fiche, la feuille s'ouvre avec le titre, l'ISBN et la couverture lus en production, et « Enregistrer »
  s'active au premier changement. « Édition de » montre l'œuvre et ses auteur·ices, la recherche de l'œuvre se pousse
  et trouve les deux « Penss et les plis du monde » ; en choisir une remplace l'œuvre affichée, avec « Ajouter un·e
  auteur·ice » pour l'œuvre `inv:` et le pied Wikidata pour l'autre. La recherche d'auteur·ices s'ouvre ; la suite
  (choisir quelqu'un, la ligne ajoutée) n'a pas été vue, ni l'état « Créer l'œuvre » dans le formulaire. Rien n'a été
  enregistré : c'est une base publique. Le chemin d'écriture n'est couvert que par les tests sur `MockAPIService`.
- **Pas d'étape e2e**, pour la même raison : le scénario tourne contre inventaire.io en production.
- **Hors du formulaire** : le titre de l'œuvre existante, retirer un·e auteur·ice, l'éditeur, la date, le nombre de
  pages, la langue. Ils restent à modifier sur inventaire.io.
- **Les vignettes d'inventaire** tirent leur titre et leur image du snapshot de l'item : elles ne changent qu'à la
  synchronisation suivante.
- **Pas de passe en français** sur le simulateur : il est en anglais.
- **Android** : non porté.

## Écarts avec Figma (le code fait foi)

| Point | Figma | Code |
|---|---|---|
| Le formulaire | non maquetté ; la spec renvoie à `V3 · Nouvelle édition` | `V3`, avec « Édition de » qui ouvre `V2`, « Ajouter un·e auteur·ice » sous l'œuvre, un champ sous-titre, et « Enregistrer » au lieu de « Publier » |
| Créer l'œuvre | `V5 · Nouvelle œuvre`, un écran à part | le titre de l'œuvre et ses auteur·ices dans « Édition de » |
| Libellé de l'ISBN | « ISBN, lu sur le code-barres » (`V3`) | « ISBN » |
