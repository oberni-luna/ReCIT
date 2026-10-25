# Nouveau livre, l'œuvre d'abord

Livré le 2026-10-25, depuis le PRD 0026 et les issues 0133–0137, en autopilot, sur `main` : cinq
commits, un par issue. Il remplace le formulaire de la [feature 0020](0020-creating-a-book-that-inventaire-lacks.md)
— ce qui s'ouvre quand un scan ne trouve pas l'édition — par le parcours « Nouveau livre v2 » de la
maquette. Le PRD et les issues étaient un échafaudage et n'ont jamais été commités. Ils ont été
numérotés au-delà de tous les numéros que citent déjà les autres features.

## Ce que ça fait

Un scan ne trouve pas l'édition, la rangée inconnue porte son « + », et la feuille s'ouvre sur une
question : **de quel livre s'agit-il ?** Ce n'est plus un formulaire titre-auteur. La plupart du
temps, c'est *cette édition* qui manque à inventaire.io : l'œuvre — le texte, ses auteur·ices — y
est déjà, et il suffit de la désigner.

**La recherche d'œuvres** (`V1`, `V2`, `V4`) s'ouvre, champ actif, sur une phrase qui rappelle
l'ISBN lu. Elle part après deux caractères et 300 ms sans frappe. Chaque résultat montre sa
couverture entière (36 × 54), son titre, et « auteur·ices · année ». Sous les résultats,
« Aucune ne correspond : créer l'œuvre ». S'il n'y en a aucun, « Créer l'œuvre « … » », et une
phrase qui demande de vérifier l'orthographe ou de chercher l'auteur·ice d'abord.

**Une œuvre trouvée** pousse « Nouvelle édition » (`V3`). L'œuvre est rappelée en tête, puis viennent
la couverture et l'ISBN, et le titre de l'édition, rempli avec celui de l'œuvre. Rien d'autre n'est
demandé : ni auteur·ice, ni passe à blanc, puisque l'œuvre est nommée par son uri.

**Aucune œuvre ne convient** : « Nouvelle œuvre » (`V5`, `V7`). Le titre de l'œuvre est repris de
la recherche, avec une majuscule initiale. Viennent ensuite une ou plusieurs auteur·ices, chacun
choisi sur inventaire.io ou créé, par l'écran de choix existant. « Ajouter un·e autre auteur·ice »
en ajoute un autre, et un balayage en retire un, sauf le dernier. Puis l'édition : couverture, ISBN,
et un titre qui suit celui de l'œuvre tant qu'on ne l'a pas retouché. La passe à blanc de la v1
précède toujours la publication. Si elle reconnaît l'œuvre, « Œuvre déjà connue » (`V6`) le dit et
laisse choisir entre « Une édition de cette œuvre », qui ne crée ni œuvre ni auteur·ice, et « Non,
une autre œuvre ». Revenir en arrière depuis cet écran efface la réponse.

**La couverture** est un menu sur son cadre (`V8`) :

- « Prendre une photo », seulement là où il y a un appareil photo ;
- « Choisir dans Photos », par `PhotosPicker` ;
- « Choisir un fichier », par le sélecteur de fichiers ;
- « Depuis une URL… ».

Quand une couverture est posée, le menu commence par « Retirer la couverture » et propose les mêmes
sources sous « Remplacer par » (`V12`). Quelle que soit la source, l'image part en JPEG réduit à
1600 px de côté.

**Image depuis une URL** (`V9`–`V11`) :

- un lien qui cherche le titre de l'œuvre et l'ISBN sur Google Images, dans Safari ;
- le champ d'adresse, et un `PasteButton` : l'appui du lecteur vaut autorisation, sans alerte du
  presse-papiers ;
- un aperçu chargé dès que l'adresse est une URL http(s), décodé, avec sa taille en pixels.

Une page plutôt qu'une image — l'erreur courante, l'adresse du résultat Google — donne « Ce lien ne
mène pas à une image », et « Utiliser cette image » reste éteint.

**« Données bibliographiques ».** Un encart vert en tête de chaque écran du parcours dit d'où
viennent les données et que ce qu'on saisit devient public, sous CC0. Sa croix le ferme partout et
pour de bon (`@AppStorage`). Le « ? » de chaque barre et « En savoir plus » ouvrent l'aide entière
(`V13`) : ce que c'est, d'où elles viennent, ce que vous publiez, et trois liens — le wiki
d'inventaire.io, la salle Matrix du projet sur les entités, et « Voir mes contributions » sur le
site.

**Les brouillons** restent gardés par ISBN dans la session, comme dans la v1. Rouvrir le même
code-barres repousse l'écran où l'on en était : « Nouvelle édition » si une œuvre était choisie,
« Nouvelle œuvre » si une œuvre était en cours de description. Un livre publié n'est plus rendu à la
session en sortant.

Les échecs de publication sont ceux de la v1 — compte, refus, réseau — sur l'écran qui a publié.

## Ce qui part sur le fil

- **La recherche** : `SearchModel.searchEntity(entityTypes: [.works])`. Elle trouve une œuvre par le
  nom de son auteur·ice, vérifié en production le 2026-10-25 : « kim stanley robinson » rend ses
  romans. Il n'y a donc pas besoin de chercher les personnes puis leurs œuvres.
- **La ligne d'œuvre** : `/api/search` ne rend ni auteur ni date. Un appel public,
  `GET /api/entities/by-uris?…&attributes=labels|claims&relatives=wdt:P50`, rend les œuvres et leurs
  auteur·ices dans la même enveloppe (`EntityCreationModel.describeWorks`, `WorkCandidate`). S'il
  échoue, c'est la description de la recherche qui s'affiche.
- **`resolve`**, deux formes :

| Cas | Graine d'édition | `works` | `authors` |
|---|---|---|---|
| Œuvre trouvée, ou reconnue et acceptée | ISBN, titre, langue, `wdt:P629`, `image` | `[{ uri }]` | aucune |
| Nouvelle œuvre | ISBN, titre, langue, `image` | `[{ labels: titre de l'œuvre }]` | chacun par `uri` ou `labels` |

- **La couverture** : l'upload rend un chemin (`/img/entities/…`), envoyé maintenant en URL
  absolue. Une adresse web part telle quelle dans `image` : `resolve` la télécharge lui-même
  (`convertAndCleanupImageUrl`). `POST /api/images/convert-url`, que proposait la spec, n'est donc
  pas appelé. Dans les deux cas, un serveur qui n'obtient pas l'image publie le livre sans
  couverture.

## Deux défauts de la v1, corrigés en passant

Lus dans le code du serveur (Codeberg), pas reproduits contre la production.

- **Une œuvre reconnue pouvait être dédoublée.** La v1 envoyait `wdt:P629` et `works: nil`. Or
  `sanitize_entry.ts` fabrique une graine d'œuvre à partir du titre de l'édition quand il n'y en a
  aucune. Cette graine pouvait se résoudre ailleurs, ou être créée à côté de l'œuvre revendiquée. La
  v1 envoyait aussi la graine d'auteur, que `create_unresolved_entry.ts` résout ou crée quelle que
  soit l'œuvre. Une œuvre connue est maintenant **nommée**, sans graine d'auteur.
- **Une couverture photographiée faisait refuser le livre.** L'upload rend un chemin relatif.
  `sanitize_seed.ts` exige une URL absolue (`isUrl`) et refuse sinon l'entrée entière, d'un 400 que
  l'app affichait comme « inventaire.io a refusé ce livre ».

## Ce qui a été tranché sans entretien

La spec Figma laissait cinq questions ouvertes.

1. La recherche d'œuvres trouve par auteur·ice (vérifié) : elle se limite à `types=works`.
2. Le titre de l'édition est pré-rempli par celui de l'œuvre et le suit, jusqu'à ce qu'on le
   retouche. Le pied de section rappelle de le corriger pour une traduction.
3. Une édition rattachée à la mauvaise œuvre n'est pas corrigeable depuis l'app (`update-claim`) :
   reporté.
4. La majuscule initiale du titre d'œuvre est mise par l'app, et modifiable.
5. `V1` rappelle l'ISBN dans sa phrase, sans reprendre la rangée du scanner.

## Ce qui a été vérifié

- **Tests unitaires**, tous sur des types purs ou sur `MockAPIService` :
  - `WorkCandidateTests` — l'année, la ligne d'auteur·ices, le repli sur la description ;
  - `NewBookDraftTests` — le choix d'une œuvre, le titre qui suit, la majuscule, ce qui est
    publiable, l'écran où le brouillon rouvre ;
  - `CoverAddressTests` — les adresses acceptées, la recherche Google Images ;
  - `CoverImageReducerTests` — la réduction à 1600 px ;
  - `BibliographicDataLinksTests` — les trois liens ;
  - `ResolveRequestBuilderTests` (œuvre nommée, plusieurs auteur·ices, titre d'œuvre) et
    `EntityCreationModelTests` (`describeWorks`, upload absolu), complétés.
- **Simulateur** iPhone 17, iOS 26.4, en français et en clair, connecté au compte de test, avec un
  ISBN inventé passé au scanner simulé par `E2E_SCAN_CODES`. Vus : `V1`, `V2` (couvertures et
  lignes « Franz Kafka · 1915 »), `V3`, `V5`/`V7`, le menu `V8`, `V9`, `V10` (collage sans alerte,
  aperçu 309 × 500 px, couverture posée dans le cadre) et `V13`. Ce passage a corrigé deux choses :
  - les couvertures des résultats ne chargeaient jamais (placeholder `EmptyView`, cadre nul) ;
  - les en-têtes et pieds de section étaient dans la police du système.

**Rien n'a été publié** pendant ce passage. En revanche, un appui pris en retard sur la caméra
simulée a ajouté **« Un psaume pour les recyclés sauvages »** à l'inventaire de `OlivierB_test4`, le
2026-10-25 à 16:44. C'est l'ISBN de repli du scanner simulé. Cet exemplaire est à retirer.

## Ce qui n'a pas été vu ou fait

- Pas vus sur simulateur :
  - `V6` (il faut une passe à blanc qui reconnaît) et `V11` ;
  - `V12` (menu d'une couverture posée) ;
  - le choix de plusieurs auteur·ices ;
  - les trois échecs ;
  - les sélecteurs Photos et Fichiers ;
  - l'appareil photo.
- **La publication elle-même** n'a pas été jouée : elle écrit dans la base publique.
- **Le scénario end-to-end n'a pas été joué**, et il ne passe pas par ce parcours. Les identifiants
  `e2e.createBook.*` sont posés : `search`, `work.create`, `edition.work`, `workTitle`,
  `addAuthor`, `coverUrl.*`, `notice.*`, `help`.
- **Pas d'appareil.** [L'issue 0098](../issues/0098-create-a-book-device-review.md) — la passe sur
  appareil de la v1 — vaut toujours, et s'étend aux nouvelles sources de couverture.
- **Android** (feature 0043) garde son formulaire.

## Écarts avec la maquette

Le code fait foi.

- **Le champ de recherche actif** : sur iOS 26, la barre de recherche active remplace la barre de
  navigation. Le titre, la croix et le « ? » de `V1` cèdent la place au champ et à son bouton
  d'annulation, et reviennent quand on annule. SwiftUI n'expose pas
  `hidesNavigationBarDuringPresentation`.
- **L'état vide de `V1`** est `EmptyStateView`, le composant de l'app. Son titre est en `title50`
  (Open Sans), pas en `content400Bold` (Alegreya) : c'est l'écart D50 déjà documenté.
- **« Coller le lien copié »** est le libellé système d'un `PasteButton`, « Coller », qui ne se
  renomme pas.
- **Les menus** ont leurs glyphes à gauche, à la manière d'iOS 26.
- **La ligne d'œuvre** retombe sur la description Wikidata quand les auteur·ices ne peuvent pas être
  lus. Une œuvre inventaire.io sans auteur·ices n'a alors pas de seconde ligne.
- **`convert-url`** n'est pas appelé (voir plus haut).
- **L'encart** est sur tous les écrans du parcours, y compris `V2`, `V4` et `V6`, que la maquette
  dessine encart fermé.

## Les maquettes

Section `Nouveau livre v2` (`712:21292`) sur la page `Screens` du
[fichier Figma](https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=712-21292) :
`V1` → `V13`, `Spec · Nouveau livre v2` (`713:21515`) et `Spec · Couverture d'une nouvelle œuvre, et
l'encart des données` (`718:21971`). Voir [docs/design-system/figma-library.md](../design-system/figma-library.md).
