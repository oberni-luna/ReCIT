# Doublons : l'écran « Éditions » repère les doublons, et les fusionne sur inventaire.io

Livré le 2026-10-27, sur `feature/edition-duplicates`, en autopilot : six tranches (PRD 0028, issues 0134 à 0140,
supprimés depuis), six commits de code et celui de cette page. Maquette : la section Figma `Doublons · ISBN et signalement` (`767:4172`, page
`Inventaire`), **proposition C seulement** — `C1 · Éditions · Doublons probables` (`770:4774`), `C2 · Doublon probable
· 1 sur 2` (`770:5186`), `C3 · Éditions · Après l'envoi` (`770:4986`), le composant `Cell / Edition` (`767:4222`) et
le panneau `Spec · Doublons · ISBN et signalement` (`771:5090`). Les propositions A et B ne sont pas faites.

## Ce que c'est

**Chaque ligne de l'écran « Éditions »** dit ce qui distingue l'édition : le titre, puis « éditeur · collection ·
année », puis « ISBN 978-2-07-036822-8 » — l'ISBN-13, sinon l'ISBN-10, tel qu'inventaire.io l'écrit — ou « Sans
ISBN ». Les éditions sont rangées de la plus ancienne à la plus récente, les éditions sans date à la fin.

**L'écran compare les éditions de l'œuvre** et marque les doublons probables d'une étiquette après l'ISBN :

- **« Même ISBN »** : deux éditions ont le même ISBN, une fois l'ISBN-10 et l'ISBN-13 lus sous une même forme ;
- **« Doublon probable »** : l'une au moins n'a pas d'ISBN, et elles ont le même éditeur et la même année ;
- **« Doublon signalé »** (gris, une horloge) : inventaire.io a une tâche de fusion ouverte sur la paire, que le
  signalement vienne de ce compte ou d'un autre.

Deux ISBN différents ne font jamais un doublon. Une paire n'est proposée que si quelqu'un peut agir : l'une des deux
doit être une édition `inv:` (on ne fusionne que *depuis* une édition inventaire.io), elles ne doivent pas avoir été
déclarées différentes, et aucune tâche ne doit déjà les attendre. Trois éditions au même ISBN font deux doublons à
trancher, pas trois.

**Un bandeau** ouvre la liste : « 2 doublons probables », une phrase par raison, le lien « Les comparer », une croix.
Fermé, il reste fermé pour cette œuvre tant que les paires sont les mêmes, et revient si elles changent.

**« Les comparer »** pousse la revue, **« Doublon 1 sur 2 »** :

- « Même ISBN · laquelle garder ? » : les deux éditions, avec le nombre d'exemplaires de chacune, celle qu'on garde
  cochée. L'app coche la plus complète ; on peut cocher l'autre. Une édition Wikidata est toujours gardée — l'autre
  ne se coche pas, et la note dit pourquoi.
- « Ce qui diffère » : titre, ISBN, éditeur, date de parution, pages, couverture, langue, avec les deux valeurs
  (« 542 · — »), puis « Pareil : ISBN, éditeur et langue. » et une note : les deux réponses s'écrivent sur
  inventaire.io, pour tout le monde.
- **« Suivant »**, dans la barre, laisse la paire pour plus tard.
- **« Fusionner »** envoie la fusion et attend la réponse. **« Ce ne sont pas les mêmes »** déclare les deux éditions
  différentes.

Après chaque réponse la revue passe d'elle-même à la paire suivante, et revient à la liste après la dernière. Là, un
SnackBar résume : « Les deux éditions n'en font plus qu'une. Un doublon est signalé à l'équipe d'inventaire.io. »

## Ce qui part sur le réseau

- **Fusionner** : `PUT /api/entities/merge`, corps `{ from, to }`. `from` est l'uri `inv:` de l'édition qui
  disparaît, `to` celle de l'édition gardée (`inv:` ou `wd:`).
  - `{ ok: true }` : la fusion est faite. Les exemplaires de ce téléphone passent à l'édition gardée, une œuvre qui
    s'ouvrait sur l'édition disparue s'ouvre sur l'autre, l'édition est supprimée du store, puis l'édition gardée
    est relue, en arrière-plan : la revue passe tout de suite à la paire suivante. Jusqu'au 2026-10-29, toute
    l'œuvre était resynchronisée et la revue l'attendait — sur *L'Appel de la forêt*, « Fusionner » tournait sans
    fin sur la paire suivante, le bouton retour masqué.
  - `{ ok: true, taskId }` : inventaire.io a confié la fusion à son équipe. Rien n'est supprimé ; l'édition note la
    tâche, et la paire porte « Doublon signalé ».
  - Un `400` devient une phrase, un cas par message du serveur (« can't merge editions with different ISBNs »,
    « entities have conflicting properties », « entities are referring to one antoher », « 'from' entity is already a
    redirection », puis un refus générique). Le store n'est pas touché, la paire reste.
- **Ce ne sont pas les mêmes** : `PUT /api/entities/update-claim` `{ uri, property: "wdt:P1889", new-value }` sur
  l'édition `inv:` de la paire.
- **Signalements en attente** : `GET /api/tasks/by-uris?uris=…&type=merge`, par lots de 50, sur les uris `inv:` des
  éditions de l'œuvre, à chaque ouverture de l'écran.
- **Exemplaires** : `GET /api/items/by-entities?uris=<uri>&limit=1`, champ `total`, pour les deux éditions de la paire
  affichée.
- **Les éditions de l'œuvre sont toutes relues** à l'ouverture de l'écran (`reverse-claims`, puis `by-uris` par lots
  de 50), et les noms des éditeurs et collections lus en un appel groupé, seulement pour ceux qu'on ne connaît pas.

## Surface technique

- `Edition` gagne `isbn`, `publisherUri` / `publisherName`, `collectionUri` / `collectionName`, `publicationDate`,
  `invUri`, `differentFromUris` et `pendingMergeTargetUris` ; `Work` gagne `dismissedDuplicatesSignature`. Tous
  optionnels ou vides par défaut : migration légère. `EntityResultDTO` décode `invId`.
- `EditionBibliographicClaims` lit ces claims ; `Edition.update(entityDto:)` ne les efface jamais avec `nil`.
  `IsbnNormalization` met un ISBN sous sa forme de comparaison.
- `Model/Duplicates/` : `EditionFacts`, `EditionDuplicateDetector`, `EditionDuplicatePair`, `EditionDuplicates`,
  `EditionDuplicateReason`, `EditionDuplicateTag`, `MergeChoice`, `EditionMergeRequest`, `EditionComparison`,
  `MergeOutcome`, `MergeFailure`, `DuplicatesReviewSummary` — tout pur, testé.
- `AppModels/Duplicates/EditionDuplicatesModel` (`@Observable @MainActor`, construit dans `RootView`, injecté à côté
  d'`EntityModel`) : `merge`, `markNotTheSame`, `refreshPendingReports`, `copyCount`.
  `EntityModel.refreshWorkEditions` remplace `getWorkEditions` dans le gateway.
- Écrans : `EditionCell` (`Cell / Edition`), `EditionDuplicateTagLabel`, `EditionDuplicatesBanner`, la destination
  `NavigationDestination.editionDuplicates(workUri:)` et `EditionDuplicatesReview`, avec `EditionDuplicatePairForm`
  et `EditionDifferencesSection`. `WorkEditionPicker` lit ses éditions sur la `Work` observée.
- Tests : `EditionBibliographicClaimsTests`, `EditionDuplicateDetectorTests`, `EditionComparisonTests`,
  `EditionDuplicatesModelTests` — ce dernier sur `MockURLProtocol`, sans jamais toucher le réseau.

## Décisions notables

- **La fusion n'est pas optimiste.** Elle est irréversible pour ce compte (`revert-merge` est réservé aux
  dataadmins) et modifie la base publique. Le serveur répond d'abord ; SwiftData suit, ensuite seulement.
- **« Ce ne sont pas les mêmes » l'est**, parce qu'un claim ajouté a un inverse propre. inventaire.io accepte
  `wdt:P1889` sur une édition (vérifié dans `properties.ts` le 2026-10-27) : le refus est écrit sur le serveur, rien
  n'est retenu sur ce seul téléphone, et le serveur refusera ensuite de fusionner la paire.
- **« Une des deux n'a pas d'ISBN » se lit « au moins une »** : deux éditions sans ISBN, du même éditeur et de la
  même année, sont aussi proposées.
- **Pour un compte ordinaire, la fusion est presque toujours immédiate.** Le serveur fusionne quand les libellés des
  œuvres des deux éditions concordent, ce qui est le cas pour deux éditions d'une même œuvre, sauf si un identifiant
  externe diffère. La réponse `taskId` est donc rare.
- **Les ISBN ne sont pas validés par leur clé** : le serveur les valide à l'écriture, et deux saisies du même numéro
  fautif restent le même numéro.
- **Une édition que le serveur ne liste plus** pour l'œuvre est détachée de l'œuvre, pas supprimée : d'autres œuvres,
  des exemplaires ou des listes peuvent encore la citer. Seule une fusion faite depuis l'app supprime une édition.
- **`by-uris` rend l'uri `inv:`** d'une édition, même demandée sous son `isbn:` (vérifié le 2026-10-27). `invUri`
  est gardé quand même : c'est la seule uri qu'une fusion accepte comme `from`.
- **Les signalements sont la vérité du serveur**, pas des claims : une réponse réussie remplace la liste, et une
  tâche close fait tomber l'étiquette. Un appel en échec ne change rien.
- **Le nombre d'exemplaires** est celui que ce compte voit, pas celui de toute la base.

## Non fait, non vérifié

- **Aucune fusion réelle.** Les sept paires même-ISBN de *1984* (une édition Wikidata et une édition inventaire.io à
  chaque fois) seraient fusionnables, mais aucune n'a été envoyée. Le premier essai se fait avec une paire fournie
  par le propriétaire du projet.
- **Jamais vu sur simulateur ni sur appareil** : ni la liste avec ses étiquettes, ni le bandeau, ni la revue, ni le
  SnackBar.
- **Scénario de bout en bout non joué** (`scripts/e2e.sh`), et sans étape pour cette feature. Les identifiants
  `e2e.duplicates.*` sont posés.
- **Les listes et les étagères** qui citent l'uri d'une édition fusionnée ne sont pas réécrites : la prochaine
  synchronisation et la redirection du serveur s'en chargent.
- **Android** : rien.
- `docs/design-system/figma-library.md` ne recense pas encore la section `Doublons` ni `Cell / Edition`.

## Écarts avec Figma (le code fait foi)

- « Même ISBN · **laquelle** garder ? » : la maquette écrit « lequel », mais on garde une édition.
- La revue ajoute une note sous « Ce qui diffère » : les deux réponses s'écrivent sur inventaire.io, pour tout le
  monde.
- Les phrases du bandeau sont génériques (« Deux éditions ont le même ISBN. ») ; la maquette nomme l'éditeur et
  l'année.
- Le SnackBar compte les paires fusionnées et signalées ; la maquette nomme l'éditeur.
- Le nombre d'exemplaires n'apparaît que dans la revue, comme dans la maquette, et seulement quand l'appel répond.
- Les couvertures d'exemple de C1 et C3 (*Le chaos qui vient*) sont des restes de maquette, pas un état reproduit.
