# Toutes les données bibliographiques d'une édition, de la fiche livre et du scanner

Livré le 2026-10-25, sur `main`, en autopilot : quatre tranches (PRD 0027, issues 0119 à 0122, supprimés depuis),
quatre commits, après un commit de base qui posait la partie « œuvre et auteur·ices » de la
[feature 0049](0049-edit-an-edition.md). Maquette : la section Figma `Modifier l'édition · Toutes les données`
(`750:2508`, page `Inventaire`) — `E1` (`750:2509`, clair, et `752:2856`, sombre), `E2` depuis le scanner
(`752:2917`), `E3` à l'ouverture (`758:3589`), `E4` détacher (`758:3657`), `E5` modifier l'œuvre (`758:3803`), spec
`754:3472` — et le bas de la fiche livre, retouché à la main dans `744:2383`.

## Ce que c'est

**La fiche livre** se termine sur une seule rangée teintée, **« Données bibliographiques »**, sans en-tête de section,
et sous elle la note « Enrichir les données bibliographiques permet d'enrichir la base de données open data de
inventaire.io ». La rangée ouvre « Modifier l'édition », comme la rangée « Modifier » qu'elle remplace, pour toute
édition sauf une édition Wikidata.

**« Modifier l'édition »** montre et modifie tout ce qu'inventaire.io accepte sur une édition, dans cet ordre :

- l'encart « Données bibliographiques » et le « ? » d'aide, comme avant ;
- **« Édition de »** : les œuvres de l'édition (une, ou plusieurs pour un recueil), puis « Ajouter une œuvre » ;
- **« Couverture et ISBN »** : la couverture et son menu, l'ISBN-13 et l'ISBN-10, affichés sans être modifiables ;
- **« Titre »** : le titre, obligatoire, et le sous-titre ;
- **« Publication »** : la maison d'édition, la collection, la date de publication, la langue ;
- **« Format »** : un menu de six formats (broché, relié, poche, album de bande dessinée, livre numérique, livre
  audio), le nombre de pages, le nombre de volumes ;
- **« Ont aussi fait cette édition »** : traduction, illustrations, illustration de couverture, préface, postface,
  direction éditoriale ;
- **« Bases bibliographiques »** : les identifiants de l'édition dans 22 catalogues (BnF, Open Library, SUDOC,
  VIAF, OCLC, Google Books, Goodreads…), puis « Ajouter un identifiant » ;
- **« Sur le web »** : dix sortes de liens (site officiel, blog, Mastodon, Bluesky, Instagram…), puis « Ajouter un
  lien ».

**« Enregistrer »** est épinglé en bas de la feuille, toujours à portée de doigt, et désactivé tant que rien n'a
changé, que le titre est vide ou que l'édition n'a plus d'œuvre.

Une rangée à chevron pousse un écran : la **recherche** d'une maison d'édition, d'une collection, d'une langue ou
d'une personne, avec « Créer « … » » en dernier (sauf pour une langue) ; ou, quand la propriété nomme déjà
quelqu'un, la **liste de ses valeurs**, qui se retirent d'un glissement et s'enrichissent par « Ajouter ». Une
collection ne se crée que sous une maison d'édition, et la recherche le dit quand il n'y en a pas. La **date** se
règle à l'année, au mois ou au jour, dans un écran à elle. Pages et volumes se tapent. Un **identifiant** se choisit
dans la liste des catalogues, puis se tape, vérifié au format de la base pendant la frappe, avec l'exemple que
donne le serveur. Identifiants et liens se retirent d'un glissement.

### Les œuvres, et « Modifier l'œuvre »

- **« Ajouter une œuvre »** pousse la recherche d'œuvre de la création (`V2`). Une œuvre trouvée s'ajoute à la liste
  (une seule fois). « Créer l'œuvre » ajoute une œuvre nouvelle et ouvre aussitôt son écran, puisqu'elle ne
  s'enregistre pas sans auteur·ice.
- **Glisser une œuvre vers la gauche** révèle « Détacher », en rouge. L'édition cesse d'en être une édition, et
  l'œuvre reste sur inventaire.io.
- **Toucher une œuvre** pousse **« Modifier l'œuvre »** : son titre et ses auteur·ices, ajouté·es par la recherche
  d'auteur·ices et retiré·es d'un glissement. C'est le seul endroit où l'on ajoute un·e auteur·ice, qui appartient à
  l'œuvre, donc à toutes ses éditions. Les changements partent avec « Enregistrer », au retour. Une œuvre Wikidata
  s'y montre en lecture seule, et le pied le dit.

### Créer un livre depuis le scanner

Après la recherche d'œuvre, **« Nouvelle édition »** est le même formulaire, en création : l'œuvre trouvée ou
décrite, la couverture et l'ISBN lus au code-barres, le titre repris de l'œuvre, le sous-titre, et toutes les
propriétés, la langue déjà remplie d'après l'ISBN. « Publier et ajouter à mes livres » est épinglé en bas, avec
« Garder le brouillon » sous lui après un échec. « Créer l'œuvre » ouvre le formulaire avec **« Nouvelle œuvre »**
par-dessus, qui ne garde plus que le titre et les auteur·ices de l'œuvre. Toucher une œuvre trouvée ramène à la
recherche ; glisser l'œuvre la détache. La passe à blanc et « Œuvre déjà connue » ne changent pas, et le brouillon
gardé par code-barres garde tout ce qui a été saisi.

## Surface technique

**Sur le fil.**
- Lecture : `GET /api/entities/by-uris?attributes=info|claims|labels&relatives=…` pour l'édition, avec les libellés
  des maisons d'édition, collections et personnes qu'elle nomme ; un second appel pour les langues, que `relatives`
  ne connaît pas. Les œuvres : un `by-uris` avec `relatives=wdt:P50`, toutes à la fois.
- Enregistrement : la couverture, puis `POST /api/entities` pour chaque personne, œuvre, maison d'édition, puis
  collection à créer (une collection n'a pas de libellé : son nom est `wdt:P1476`, et elle porte sa maison d'édition
  en `wdt:P123`). Viennent ensuite `PUT /api/entities/update-claim`, un par valeur ajoutée ou retirée — `wdt:P629`
  sur l'édition pour une œuvre ajoutée ou détachée, `wdt:P50` sur l'œuvre pour un·e auteur·ice — et enfin
  `PUT /api/entities/update-label` pour chaque œuvre renommée, dans la langue du libellé qu'elle remplace.
- Création : les entités à créer passent d'abord par `POST /api/entities`, puis `POST /api/entities/resolve` porte
  toutes les valeurs dans la graine d'édition.
- Les nombres (`wdt:P1104`, `wdt:P2635`) partent en nombres JSON : le serveur refuse `"256"`.

**Types.**
- `EditionProperty` est le catalogue : uri, genre (date, nombre, format, entité d'un type de recherche, identifiant
  avec son motif, url), section, multivaluée ou non. Il est lu de `/api/data/properties` et de
  `properties_per_type.ts`, et les motifs sont ceux de `properties_values_constraints.ts`.
- `EditionProperties` tient les valeurs (`EditionClaimValue` : littéral ou `EditionEntityValue`). Il dit quelles
  entités créer (collections en dernier) et quels claims envoyer depuis les valeurs d'origine. Il est partagé par
  `EditionEdit` et `NewBookDraft`.
- `ClaimLiteral` est une valeur typée (chaîne ou entier). `EditionClaimUpdate` prend une propriété quelconque et des
  valeurs typées. `EntityResolveRequest.Seed.claims` passe aux valeurs typées. `PublicationDate` gère les trois
  précisions, `EditionFormat` les six formats, et `EntityCreationKind` les trois sortes d'entités créées d'ici.
- `WorkEdit` est une œuvre du formulaire face à ce qu'inventaire.io en tient. `EditionEdit` liste des `WorkEdit` et
  n'a plus d'œuvre unique. `EntityLabelUpdate` porte un renommage. `EntityLabel.language(of:)` dit dans quelle langue
  est le libellé affiché.
- `EditionEdit.nextStep` ajoute deux étapes, `.createEntity` et `.label`. Comme avant, ce qui a abouti passe dans
  l'original, et un nouvel essai ne recrée rien.

**Vues.**
- Partagées par les deux flux : les sections (`EditionWorksSection` côté modification, `NewEditionWorkSection` côté
  création, `EditionPublicationSection`, `EditionFormatSection`, `EditionContributorsSection`,
  `EditionIdentifiersSection`), `EditionPropertyRow`, les écrans poussés (`EntityPickerView`,
  `EditionEntityValuesView`, `PublicationDateView`, `IdentifierCatalogView`, `IdentifierInputView`) et leur routage
  commun (`EditionPropertyStep`, `EditionPropertyDestination`).
- `EditWorkView` est « Modifier l'œuvre ». `FormActionBar` est la barre épinglée (`safeAreaInset(edge: .bottom)`).
  `BookBibliographicDataSection` est la rangée de la fiche.

## Décisions notables

- **L'ISBN est en lecture seule.** Le serveur réserve la modification de `wdt:P212` aux admins
  (`updateAccessLevel: 'admin'`) et déduit `wdt:P957` de l'ISBN-13. La question ouverte de la maquette est tranchée
  par le serveur.
- **« Différente de » (`wdt:P1889`) n'est pas fait.** Il nomme une autre édition, et `/api/search` ne cherche pas les
  éditions. La section « Autres données » de la maquette devient « Sur le web ».
- **Les liens vers les réseaux sociaux sont là**, puisque inventaire.io les accepte sur une édition.
- **Une seule sauvegarde pour toute la feuille**, « Modifier l'œuvre » compris, et rien n'est optimiste.
- **Une édition sans œuvre ne s'enregistre pas** (`wdt:P629` est obligatoire). Une œuvre que la description n'a pas
  rendue reste listée sous son uri, pour ne jamais être détachée par accident.
- **Le glissement va vers la gauche**, l'action à droite (`.swipeActions(edge: .trailing)`), teintée en
  `foregroundError` : la teinte de l'app la peignait en vert pâle, libellé illisible.
- **La création garde `resolve`**, pour sa passe à blanc, son `enrich` et son contrôle strict, et une œuvre par livre,
  comme avant.

## Non fait, non vérifié

- **Rien n'a été enregistré pour de vrai** : toute édition est publique. L'enregistrement et la création n'ont été
  testés que contre un serveur simulé (1038 tests).
- **Vu sur le simulateur, en lecture seule** : la rangée de la fiche, toutes les sections du formulaire remplies par
  le serveur (date, langue, identifiant Open Library), la barre épinglée, la liste des œuvres, « Détacher » en rouge,
  « Modifier l'œuvre » d'une œuvre Wikidata, l'ouverture de la recherche d'entité.
- **Pas vu** : le parcours de création depuis le scanner (le simulateur n'a pas d'appareil photo), les écrans de date
  et d'identifiant, le mode clair.
- **e2e non joué.** Les identifiants `e2e.editEdition.*` ont changé de forme (une œuvre par rangée, `addWork`), et le
  scénario ne passe pas par ce formulaire.
- **Une langue retirée à la création revient** si l'ISBN en donnait une : le constructeur de la requête la reprend
  quand le formulaire n'en nomme aucune.

## Écarts avec Figma (le code fait foi)

- « Autres données » devient « Sur le web », sans « Différente de ».
- L'ISBN est un texte et non un champ.
- Les actions de glissement suivent le système (fond rouge, libellé blanc) et non `Form / Swipe Row` (`background/
  error`, libellé `foreground/error`).
- La date est un écran poussé, pas un menu.
- `E5` n'a pas de barre fixe : ses changements partent avec l'« Enregistrer » de l'édition.
