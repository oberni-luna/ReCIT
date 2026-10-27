# 0028 — Doublons : l'écran « Éditions » repère les doublons, et les fusionne sur inventaire.io

Maquettes : Figma `S7IvC6GvlcUFe5IgbtvQq6`, page « Inventaire », section « Doublons · ISBN et
signalement » (`767:4172`), **proposition C seulement** — `C1 · Éditions · Doublons probables`
(`770:4774`), `C2 · Doublon probable · 1 sur 2` (`770:5186`), `C3 · Éditions · Après l'envoi`
(`770:4986`), et le composant nouveau `Cell / Edition` (`767:4222`, variantes Leading ∈
{None, Off, On}). Le panneau `Spec · Doublons · ISBN et signalement` (`771:5090`) résume l'API.
Les propositions A et B, dans la même section, ne sont pas faites.

Décisions d'architecture : [ADR 0001](../adr/0001-swiftdata-reactive-optimistic.md) (upsert sans
effacement, écritures optimistes — et ses exceptions), [ADR 0008](../adr/0008-session-login-signup-keychain.md)
(un `401` sort du modèle, une réponse du serveur qui mérite une phrase est un cas sur un type pur).

## Problem Statement

J'ouvre « Autres éditions » sur *Le Comte de Monte-Cristo*. L'écran « Éditions » me montre deux
lignes « Le Comte de Monte-Cristo, tome 1 » et « Le comte de Monte Cristo », toutes deux du Livre de
Poche. Est-ce le même livre saisi deux fois, ou deux livres ? Je n'ai aucun moyen de le savoir : la
ligne ne montre ni l'ISBN, ni l'éditeur, ni l'année. Elle montre un titre et une couverture, qui
sont justement ce qui varie d'une saisie à l'autre.

Les doublons sont réels et nombreux. Sur les 131 éditions que inventaire.io donne pour *1984*
(vérifié le 2026-10-27), **sept paires** portent le même ISBN — à chaque fois une édition Wikidata
et une édition inventaire.io créée par-dessus. Chaque doublon partage les exemplaires des lecteurs
entre deux fiches, et rend l'écran « Éditions » plus long et moins lisible pour tout le monde.

inventaire.io sait fusionner deux éditions, et le fait pour n'importe quel compte connecté. Mais
rien dans l'app ne le permet, et rien ne m'aide à repérer les candidats. Le site web demande de
trouver les doublons à l'œil, ce que personne ne fait.

## Solution

L'écran « Éditions » d'une œuvre fait le travail de repérage lui-même :

- **Chaque ligne d'édition dit ce qui la distingue** : titre, puis « éditeur · collection · année »,
  puis « ISBN 978-2-253-09806-9 » — ou « Sans ISBN ». C'est le nouveau composant `Cell / Edition`.
- **L'écran compare les éditions de l'œuvre** et marque les doublons probables d'une étiquette :
  « Même ISBN » quand deux éditions ont le même ISBN, « Doublon probable » quand l'une n'a pas
  d'ISBN et qu'elles ont le même éditeur et la même année.
- **Un bandeau en tête de la liste** dit « N doublons probables », en une phrase dit pourquoi, et
  propose « Les comparer ». Il se ferme d'une croix.
- **« Les comparer » pousse une revue, un doublon à la fois** (« Doublon 1 sur 2 ») : les deux
  éditions, l'une cochée — celle qu'on garde, l'app coche la plus complète —, ce qui diffère entre
  elles, puis deux gestes : « Fusionner », ou « Ce ne sont pas les mêmes ». « Suivant » passe au
  doublon suivant sans rien envoyer.
- **« Fusionner » envoie la fusion à inventaire.io et attend sa réponse.** Deux issues, que l'app
  dit toutes les deux : la fusion est faite (la paire ne fait plus qu'une ligne), ou inventaire.io
  la confie à son équipe (la ligne garde l'étiquette « Doublon signalé » tant que la tâche est en
  attente).
- **« Ce ne sont pas les mêmes » l'écrit sur inventaire.io**, par la propriété « différente de »
  (`wdt:P1889`) : la paire n'est plus proposée, ni à moi ni à personne, et le serveur refusera
  désormais de la fusionner.
- **En revenant à la liste, un SnackBar résume** ce qui s'est passé : combien de paires ont été
  fusionnées, combien signalées.

## User Stories

### Voir ce qui distingue les éditions

1. En tant que lecteur, je veux voir l'ISBN de chaque édition dans la liste « Éditions », afin de
   distinguer deux éditions au même titre.
2. En tant que lecteur, je veux lire « Sans ISBN » quand une édition n'en a pas, afin de savoir que
   l'information manque plutôt que de croire qu'elle n'a pas été chargée.
3. En tant que lecteur, je veux voir l'éditeur, la collection et l'année de parution de chaque
   édition sous son titre, afin de reconnaître celle que je tiens en main.
4. En tant que lecteur, je veux que l'ISBN s'affiche tel qu'inventaire.io le donne, avec ses
   tirets, afin de pouvoir le comparer à celui imprimé au dos du livre.
5. En tant que lecteur, je veux qu'une édition qui n'a qu'un ISBN-10 montre cet ISBN-10, afin de ne
   pas lire « Sans ISBN » sur un livre qui en a un.
6. En tant que lecteur, je veux que ces informations apparaissent aussi pour les éditions déjà en
   cache sur mon téléphone, afin de ne pas voir des lignes incomplètes sur les œuvres que j'ai déjà
   visitées.
7. En tant que lecteur, je veux que l'écran s'affiche d'abord avec ce que le téléphone connaît puis
   se complète, afin de ne pas attendre le réseau pour voir la liste.
8. En tant que lecteur, je veux qu'une réponse incomplète du serveur n'efface jamais un ISBN, un
   éditeur ou une date déjà connus, afin que la liste ne perde pas d'information d'une visite à
   l'autre.

### Repérer les doublons

9. En tant que lecteur, je veux que deux éditions de la même œuvre au même ISBN soient marquées
   « Même ISBN », afin de voir d'un coup d'œil qu'il s'agit d'une double saisie.
10. En tant que lecteur, je veux qu'un ISBN-10 et l'ISBN-13 qui lui correspond soient reconnus comme
    le même ISBN, afin qu'un doublon ne m'échappe pas parce que les deux fiches ne notent pas l'ISBN
    de la même façon.
11. En tant que lecteur, je veux que les tirets et les espaces de l'ISBN ne comptent pas dans la
    comparaison, afin que deux saisies d'un même numéro soient reconnues.
12. En tant que lecteur, je veux qu'une édition sans ISBN, du même éditeur et de la même année
    qu'une autre, soit marquée « Doublon probable », afin de repérer les doublons que l'ISBN ne
    trahit pas.
13. En tant que lecteur, je veux que deux éditions aux ISBN différents ne soient jamais proposées
    comme doublons, afin de ne pas perdre mon temps sur une fusion que inventaire.io refusera.
14. En tant que lecteur, je veux qu'une paire que personne ne peut fusionner — deux éditions
    Wikidata — ne me soit pas proposée, afin que chaque proposition mène quelque part.
15. En tant que lecteur, je veux qu'une paire déclarée « pas les mêmes » sur inventaire.io ne me
    soit plus proposée, afin de ne pas trancher deux fois la même question.
16. En tant que lecteur, je veux que trois éditions au même ISBN donnent deux doublons à trancher,
    et non trois, afin que la revue corresponde au nombre de fusions à faire.
17. En tant que lecteur, je veux un bandeau en tête de la liste qui dit combien de doublons
    probables l'écran voit et pourquoi, afin de savoir qu'il y a quelque chose à faire avant de
    parcourir la liste.
18. En tant que lecteur, je veux pouvoir fermer ce bandeau, afin qu'il ne m'encombre pas quand je
    ne veux pas m'en occuper.
19. En tant que lecteur, je veux que le bandeau revienne si l'écran trouve de nouveaux doublons,
    afin de ne pas manquer un cas que je n'avais pas vu en le fermant.
20. En tant que lecteur, je veux qu'aucun bandeau ne s'affiche quand l'écran ne voit aucun doublon,
    afin que l'écran reste celui d'aujourd'hui pour la plupart des œuvres.

### Trancher un doublon

21. En tant que lecteur, je veux que « Les comparer » m'ouvre les doublons un par un, afin de
    trancher chaque paire sans perdre le fil.
22. En tant que lecteur, je veux lire « Doublon 1 sur 2 » en titre, afin de savoir combien il en
    reste.
23. En tant que lecteur, je veux que le titre de la section dise pourquoi la paire est proposée
    (« Même ISBN » ou « Doublon probable ») et pose la question « lequel garder ? », afin de
    comprendre ce que l'app me demande.
24. En tant que lecteur, je veux voir les deux éditions avec leur nombre d'exemplaires, afin de
    savoir laquelle les lecteurs utilisent.
25. En tant que lecteur, je veux que l'app coche d'avance l'édition la plus complète, afin de n'avoir
    qu'à confirmer dans le cas ordinaire.
26. En tant que lecteur, je veux pouvoir cocher l'autre, afin de garder celle que je juge meilleure.
27. En tant que lecteur, je veux qu'une édition Wikidata soit toujours celle qu'on garde, et que
    l'app me dise pourquoi l'autre ne peut pas l'être, afin de ne pas tenter une fusion que
    inventaire.io refuse.
28. En tant que lecteur, je veux lire ce que devient l'édition non cochée — un renvoi vers l'autre,
    ses exemplaires la suivent —, afin de savoir ce que je fais avant de le faire.
29. En tant que lecteur, je veux voir « Ce qui diffère » entre les deux éditions — titre, ISBN,
    éditeur, date, pages, couverture, langue —, afin de juger sur pièces.
30. En tant que lecteur, je veux lire en une ligne ce qui est pareil, afin de ne pas comparer ce qui
    ne varie pas.
31. En tant que lecteur, je veux « Suivant » pour passer au doublon suivant sans rien décider, afin
    de remettre à plus tard une paire dont je ne suis pas sûr.
32. En tant que lecteur, je veux que la revue passe d'elle-même au doublon suivant après une
    décision, et revienne à la liste après le dernier, afin de ne pas avoir à naviguer.

### Fusionner

33. En tant que lecteur, je veux que « Fusionner » envoie la fusion à inventaire.io et me montre
    qu'elle est en cours, afin de ne pas l'envoyer deux fois.
34. En tant que lecteur, je veux que la liste ne change qu'une fois que inventaire.io a répondu,
    afin de ne jamais voir une fusion qui n'a pas eu lieu — elle est irréversible pour moi.
35. En tant que lecteur, je veux qu'une fusion faite ne laisse qu'une ligne dans la liste, afin de
    voir le résultat de mon geste.
36. En tant que lecteur, je veux que mes propres exemplaires de l'édition disparue restent dans mon
    inventaire, rattachés à l'édition gardée, afin que la fusion ne me fasse pas perdre un livre.
37. En tant que lecteur, je veux que l'œuvre et ses éditions soient rechargées après une fusion,
    afin que la liste reflète ce que inventaire.io sait maintenant.
38. En tant que lecteur, je veux que l'app me dise quand inventaire.io a confié la fusion à son
    équipe plutôt que de la faire, afin de ne pas croire à tort qu'elle est faite.
39. En tant que lecteur, je veux qu'une paire signalée porte l'étiquette « Doublon signalé » tant
    que l'équipe n'a pas tranché, afin de ne pas la signaler encore.
40. En tant que lecteur, je veux que l'étiquette « Doublon signalé » apparaisse aussi pour une paire
    signalée par quelqu'un d'autre, afin de ne pas refaire ce qu'un autre lecteur a fait.
41. En tant que lecteur, je veux qu'une paire signalée ne soit plus proposée dans la revue, afin que
    la revue ne contienne que ce que je peux faire avancer.
42. En tant que lecteur, je veux qu'une fusion refusée m'explique pourquoi en une phrase — ISBN
    différents, propriétés en conflit, éditions qui se citent l'une l'autre, édition déjà fusionnée
    —, afin de comprendre que le refus ne vient pas d'une panne.
43. En tant que lecteur, je veux qu'une fusion refusée ou échouée laisse la paire telle quelle, afin
    de pouvoir choisir « Ce ne sont pas les mêmes » ou réessayer.
44. En tant que lecteur, je veux, de retour à la liste, un SnackBar qui résume ce qui a été fusionné
    et ce qui a été signalé, afin de savoir ce que ma revue a produit.

### Ce ne sont pas les mêmes

45. En tant que lecteur, je veux dire « Ce ne sont pas les mêmes » sur une paire, afin qu'elle
    disparaisse de la revue et des étiquettes.
46. En tant que lecteur, je veux que ce refus soit enregistré sur inventaire.io, afin que les autres
    lecteurs n'aient pas à trancher la même paire.
47. En tant que lecteur, je veux que la paire disparaisse aussitôt, sans attendre le réseau, afin
    que la revue reste fluide.
48. En tant que lecteur, je veux que la paire revienne et qu'un SnackBar me le dise si inventaire.io
    refuse l'écriture, afin de ne pas croire enregistré ce qui ne l'est pas.

### Accessibilité et langues

49. En tant que lecteur VoiceOver, je veux que chaque ligne se lise d'un tenant — titre, éditeur,
    année, ISBN, étiquette —, afin de comparer les éditions à l'oreille.
50. En tant que lecteur VoiceOver, je veux que la coche d'une édition se lise « sélectionnée »,
    afin de savoir laquelle sera gardée.
51. En tant que lecteur anglophone, je veux tous ces textes en anglais, afin de les comprendre.
52. En tant que lecteur sur iOS 18, je veux la même fonctionnalité que sur iOS 26, afin de ne pas
    être exclu.

## Implementation Decisions

### Les données d'une édition

- **`Edition` gagne cinq champs, tous optionnels ou à défaut vide**, ce qui garde la migration
  SwiftData légère :
  - `isbn` — la valeur de `wdt:P212` (ISBN-13) telle que le serveur la donne, sinon celle de
    `wdt:P957` (ISBN-10). C'est la forme affichée ; la comparaison passe par la normalisation.
  - `publisherUri` (`wdt:P123`), `collectionUri` (`wdt:P195`), et leurs libellés `publisherName`,
    `collectionName`.
  - `publicationDate` (`wdt:P577`), brute (« 1995 », « 1995-03-01 ») ; l'année s'en déduit.
  - `invUri` — `inv:<invId>`, lu dans le champ `invId` que `by-uris` renvoie. **C'est l'uri qu'on
    envoie comme `from`** : l'uri canonique d'une édition locale est souvent `isbn:…`, et la fusion
    exige le préfixe `inv:`. Une édition Wikidata n'en a pas (ou l'ignore) : elle ne peut qu'être
    gardée.
  - `differentFromUris` — les valeurs de `wdt:P1889`.
- Le nombre de pages (`wdt:P1104`), déjà un champ, est désormais aussi rempli par l'upsert quand le
  claim est là.
- **`update(entityDto:)` suit l'invariant 2 de l'ADR 0001** : chaque nouveau champ n'est écrit que
  si la réponse le porte. Un claim absent ne l'efface jamais. Conséquence acceptée : un ISBN retiré
  sur inventaire.io reste en cache jusqu'à ce qu'une valeur le remplace.
- `EntityResultDTO` gagne `invId`. Les claims y sont déjà.
- **Les libellés d'éditeur et de collection** viennent d'un appel `by-uris` séparé
  (`attributes=labels`), groupé pour toutes les éditions de l'œuvre, et seulement pour les uris dont
  le libellé n'est pas encore connu. Pas de `relatives` sur `fetchEntities` : ses appelants
  prendraient les éditeurs pour des éditions.
- **Les éditions en cache sont revalidées à l'ouverture de l'écran « Éditions »** : aujourd'hui
  `getOrFetchEditions` ne refetche pas une édition déjà connue, si bien qu'aucune ne gagnerait
  jamais son ISBN. L'écran affiche d'abord le cache, puis upserte toutes les éditions de l'œuvre
  (par lots de 50, soit trois appels pour *1984*).

### Le repérage, en code pur

- **`IsbnNormalization`** : retire tout ce qui n'est pas chiffre ou `X`, convertit un ISBN-10 en
  ISBN-13 (préfixe 978, clé recalculée). Une chaîne qui n'est ni l'un ni l'autre ne vaut rien et
  ne rapproche aucune édition.
- **`EditionDuplicateDetector`** prend une liste de faits par édition (uri, uri de fusion, ISBN
  normalisé, éditeur, année, `differentFrom`, Wikidata ou non) et les uris des signalements en
  attente, et rend :
  - les **paires à trancher**, chacune avec sa raison (`sameIsbn` / `probable`) ;
  - l'**étiquette de chaque édition** (`Même ISBN`, `Doublon probable`, `Doublon signalé`, ou rien).
- Règles :
  1. Même ISBN normalisé → `sameIsbn`.
  2. **Au moins une** des deux sans ISBN, même `publisherUri`, même année → `probable`. (« Une des
     deux » est lu « au moins une » : deux éditions sans ISBN, même éditeur, même année, sont un
     doublon au moins aussi probable. À trancher à la validation si ce n'est pas le sens voulu.)
  3. Deux ISBN différents → jamais un doublon.
  4. Une paire n'est proposée que si **au moins une** des deux éditions a un `invUri` (sinon
     aucune ne peut être `from`).
  5. Une paire liée par `wdt:P1889`, dans un sens ou dans l'autre, n'est jamais proposée — le
     serveur la refuserait d'ailleurs (« entities are referring to one antoher »).
  6. Une paire déjà signalée (une tâche ouverte dont le suspect est l'une et la suggestion l'autre)
     n'est pas proposée ; ses deux éditions portent « Doublon signalé ».
  7. **Regroupement** : les éditions reliées par les règles 1–2 forment une grappe ; la grappe
     donne une paire par édition autre que sa meilleure (celle que `MergeChoice` garderait). Trois
     éditions au même ISBN donnent deux paires, pas trois.
- **`MergeChoice`** décide quelle édition est cochée et laquelle peut l'être :
  - une édition Wikidata est **toujours** gardée — l'autre ligne n'est pas cochable, et une `Note`
    dit pourquoi ;
  - sinon, la plus complète : un point par donnée présente (ISBN, couverture, pages, éditeur,
    date, sous-titre, langue), puis le nombre d'exemplaires, puis l'uri pour que l'ordre soit
    stable ;
  - il rend la paire `{from, to}` à envoyer.
- **`EditionComparison`** liste, pour une paire, les propriétés qui diffèrent (titre, ISBN, éditeur,
  date, pages, couverture « Oui / Non », langue) avec les deux valeurs, et celles qui sont pareilles
  — la `Note` « Pareil : … ». Une valeur absente s'écrit « — ».

### Fusionner, signaler, refuser — `EditionDuplicatesModel`

- **Nouveau modèle partagé `EditionDuplicatesModel`** (`@Observable @MainActor`), sous
  `AppModels/`, construit dans `RootView` avec l'`apiService` à session et injecté par
  `.environment` — CLAUDE.md : les deux endroits.
- **`merge(pair:)` n'est pas optimiste.** C'est l'exception de l'ADR 0001 pour les suppressions,
  doublée ici d'une raison plus forte : la fusion est irréversible pour nous (seuls les dataadmins
  ont `revert-merge`) et s'applique à la base publique. Le serveur d'abord, SwiftData ensuite —
  la règle des listes.
  - `PUT /api/entities/merge` (forme en chemin), corps `{ from, to }`, `from` = l'`invUri` de
    l'édition qui disparaît, `to` = l'uri de l'édition gardée (`inv:` ou `wd:`).
  - Réponse décodée en **`MergeOutcome`** : `{ ok: true }` → `.merged` ; `{ ok: true, taskId }`
    → `.reported(taskId)`. Ce que fait le serveur pour un compte ordinaire (code lu sur Codeberg) :
    il fusionne tout de suite si les libellés des œuvres des deux éditions concordent — pour deux
    éditions de la même œuvre, presque toujours — **sauf** si un identifiant externe diverge
    (BnF, OCLC…) ; alors il crée une tâche « merge » avec l'utilisateur comme rapporteur.
  - Après `.merged` : les exemplaires locaux de l'édition `from` sont rattachés à l'édition gardée,
    `Work.preferredEditionUri` suit si c'était elle, l'édition `from` est supprimée de SwiftData,
    puis l'œuvre et ses éditions sont resynchronisées par upsert.
  - Après `.reported` : l'édition `from` note le signalement en attente ; l'étiquette suit.
  - **`MergeFailure`**, type pur, classe un `400` par son message, un cas par message :
    « can't merge editions with different ISBNs », « entities have conflicting properties »,
    « entities are referring to one antoher » (sic), « 'from' entity is already a redirection ».
    Chaque cas porte sa phrase. Tout autre `400` est un refus générique ; un `401` sort du modèle
    sans être avalé (ADR 0008, règle 3). Le store n'est pas touché ; l'erreur passe par
    `AppErrorReporter`.
- **`markNotTheSame(pair:)` est optimiste** (invariant 3, runner `optimistic`) : c'est un claim
  ajouté en place, son inverse est propre.
  - Vérifié le 2026-10-27 dans `properties.ts` : `wdt:P1889` (« différent de ») a pour
    `subjectTypes` tous les types édités localement, **édition comprise**, avec une valeur de type
    entité. Le claim est donc écrit sur inventaire.io, et rien n'est retenu en local seulement.
  - `apply` ajoute l'autre uri à `differentFromUris` de l'édition locale ; `request` envoie
    `PUT /api/entities/update-claim` `{ uri: <invUri>, property: "wdt:P1889", new-value: <autre uri> }`
    sur l'édition `inv:` de la paire (sur celle qui serait `from` si les deux le sont) ;
    `revert` retire l'uri.
  - Une `Note` sous le bouton le dit : le refus est public, comme toute donnée bibliographique.
- **`refreshPendingReports(work:)`** : `GET /api/tasks/by-uris?uris=a|b|…` (public, forme
  `{ tasks: { <uri>: [Task] } }`, seules les tâches ouvertes — la vue serveur filtre sur `state`
  absent), par lots, sur les `invUri` des éditions de l'œuvre. Les tâches sont indexées par
  l'uri **suspecte** (`from`). Contrairement aux claims, une réponse réussie fait foi pour les uris
  demandées : une tâche close efface l'étiquette. Un échec laisse ce qu'on savait.
- **`copyCount(edition:)`** : `GET /api/items/by-entities?uris=<uri>&limit=1`, champ `total`, pour
  « 3 exemplaires » dans la revue. Ce sont les exemplaires visibles de ce compte, pas tous ceux de
  la base ; en cas d'échec la mention disparaît.

### Les écrans

- **`Cell / Edition` → `EditionCell`**, nouveau composant : vignette, titre, « éditeur ·
  collection · année », « ISBN … » ou « Sans ISBN », et un `Tag` optionnel (« Même ISBN » et
  « Doublon probable » en `tinted` avec un glyphe d'avertissement, « Doublon signalé » en
  `secondary` avec une horloge). `Leading` ∈ `none` (la liste, avec chevron), `off`/`on` (la revue,
  un rond coché). Tokens et `.textStyle` du design system.
- **`WorkEditionPicker`** remplace `SearchResultCell` par `EditionCell`, et lit ses éditions sur la
  `Work` observée (`work.editions`) plutôt que sur le tableau figé que lui passe le gateway : une
  édition supprimée par une fusion doit quitter la liste sans être relue, et ne jamais être lue
  une fois supprimée.
- **Le bandeau** (`bandeau · doublons probables`) est une carte de section à part, sur le modèle
  de `BibliographicDataNotice` : glyphe, « N doublons probables », une phrase par raison présente,
  le lien « Les comparer », une croix. La croix enregistre sur la `Work` la signature des paires
  vues ; le bandeau revient si la signature change.
- **Nouvelle destination `NavigationDestination.editionDuplicates(workUri:)`**, poussée par
  « Les comparer », qui affiche **`EditionDuplicatesReview`** (C2). La revue lit l'œuvre par uri,
  recalcule les paires à l'arrivée, et les parcourt ; un bouton `Suivant` dans la barre de
  navigation ; « Fusionner » en `Button / Large` primary et « Ce ne sont pas les mêmes » en lien,
  dans une barre épinglée (`safeAreaInset(edge: .bottom)`, comme `FormActionBar`). Pendant
  l'envoi, les deux boutons sont désactivés et « Fusionner » montre sa progression.
- **Le SnackBar de retour** (C3) : la revue accumule ses issues dans un `DuplicatesReviewSummary`
  pur (fusionnées, signalées), qui produit une phrase pluralisée par `Localizable.xcstrings` ; il
  est montré en revenant à la liste.
- Textes en français et en anglais dans `Localizable.xcstrings`. iOS 18 minimum, rien qui exige
  iOS 26.

## Testing Decisions

Tests en Swift Testing. Un bon test ici décrit un comportement vu de l'extérieur — « deux éditions
au même ISBN-10 / ISBN-13 sont un doublon », « une fusion qui répond `taskId` laisse l'édition en
place et signalée » — et pas la forme interne des types. **Aucun test ne touche le réseau** : tout
ce qui parle à inventaire.io passe par `MockURLProtocol`, et aucune fusion réelle n'est lancée.

Modules testés :

- `IsbnNormalization` — tirets, espaces, `X`, ISBN-10 → ISBN-13, chaînes invalides.
- `EditionDuplicateDetector` — chaque règle, une par une ; la grappe de trois ; deux Wikidata ;
  `P1889` dans les deux sens ; une tâche ouverte.
- `MergeChoice` — Wikidata toujours gardée, score de complétude, égalité départagée de façon stable.
- `EditionComparison` — ce qui diffère, ce qui est pareil, valeurs absentes.
- `MergeOutcome` et `MergeFailure` — les deux réponses, les quatre messages, le `400` inconnu, le
  `401` qui sort.
- `DuplicatesReviewSummary` — les comptes.
- `Edition.update(entityDto:)` — les nouveaux champs remplis, et **jamais effacés par une réponse
  qui ne les porte pas**.
- `EditionDuplicatesModel` sur `MockURLProtocol` et un store en mémoire : la requête de fusion
  (méthode, chemin, corps) ; après `.merged`, l'édition `from` supprimée et les exemplaires
  rattachés ; après `.reported`, rien supprimé et le signalement noté ; après un `400`, le store
  intact ; `markNotTheSame` appliqué puis annulé sur échec ; `tasks/by-uris` décodé et appliqué.

Prior art : `EditionTitleTests`, `EditionRelevanceTests` (règles pures sur des éditions),
`AuthFailureTests` (un message serveur → un cas), `EntityUpsertTests` (upsert sans effacement),
`EntityCreationModelEditionTests` et `ShelfModelTests` (modèles sur `MockURLProtocol`),
`OptimisticRunnerTests` (apply / revert).

## Out of Scope

- Les propositions A (cocher les doublons dans la liste) et B (« C'est un doublon… » depuis une
  édition), et la comparaison côte à côte de B3.
- Fusionner des œuvres, des auteurs, des éditeurs.
- Défaire une fusion (`revert-merge` est réservé aux dataadmins).
- Repérer des doublons ailleurs que sur l'écran « Éditions » (fiche livre, inventaire, scanner).
- Les éditions de deux œuvres différentes qui seraient la même.
- Mettre à jour les listes et étagères qui citent l'uri disparue : la prochaine synchronisation
  les ramène, et le serveur suit la redirection.
- Le portage Android.
- Le scénario de bout en bout (`scripts/e2e.sh`) : pas lancé sans demande.

## Further Notes

- **Une fusion réelle n'est essayée qu'avec une paire fournie par le propriétaire du projet.** Les
  sept paires même-ISBN de *1984* sont réelles, et fusionnables (`inv:` → `wd:`), mais personne ne
  les fusionne pour tester.
- Les règles serveur ont été lues le 2026-10-27 sur Codeberg (`server/controllers/entities/merge.ts`,
  `server/controllers/tasks/lib/merge_or_create_tasks.ts`, `.../merge_validation.ts`,
  `server/controllers/tasks/by_entity_uris.ts`, `server/db/couchdb/design_docs/tasks.ts`,
  `server/controllers/entities/lib/properties/properties.ts`) et la spec en ligne (v5.1.1).
- `validateAbsenceOfConflictingProperties` refuse aussi deux ISBN-10 différents sans ISBN-13 : la
  normalisation de l'app couvre ce cas, et ne propose pas la paire.
- La feature 0050 avait laissé « Différente de » de côté parce que `/api/search` ne cherche pas les
  éditions. Ici l'autre édition est connue — c'est la paire —, ce qui lève l'obstacle pour ce geste
  seulement.
- Les maquettes C1 et C3 portent une couverture d'exemple sans rapport avec l'œuvre ; ce n'est pas
  un état à reproduire.
