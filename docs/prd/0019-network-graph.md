# 0019 — Le réseau en graphe : un segment « Tout » dans l'onglet Réseau

Maquette : [Figma, section « Réseau · Graphe »](https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=512-15486)
(`512:15486`). Elle a été complétée et validée le 2026-10-13 : les écrans R1′, R1′b, R3′, R2′, R2b, R2c,
R2d, E1–E3, R5′, R6′, R1′ · Sombre, R3′ · Sombre, la bande « Feuille groupe · variantes de texte », et le
panneau « Décisions · grilling 2026-10-13 », qui fait foi sur le panneau « Spec » d'origine. R4 (zoomé avec
minicarte) est **hors v1**.

Décisions : les 48 questions du grilling du 2026-10-13 (Q1–Q48, plus « Après la passe Figma »). Elles sont
reprises ci-dessous là où elles comptent ; le numéro entre parenthèses renvoie à la question.

Architecture : [ADR 0001](../adr/0001-swiftdata-reactive-optimistic.md) (UI réactive sur SwiftData, upsert
en place, écritures optimistes). Feature dont celle-ci part : [0028](../features/0028-network-tab-and-groups.md)
(l'onglet Réseau et les groupes), [0033](../features/0033-group-pending-dot.md) (le point rouge).

## Problem Statement

L'onglet Réseau me donne deux listes : mes amis, mes groupes. Chacune est juste, et aucune ne me dit ce
qui les relie. Je sais qu'Inès est mon amie et que je suis admin du Club de Belleville ; je ne vois pas
qu'Inès, Léa, Rémi et Camille y sont aussi, ni que Camille est le pont entre le Club et les Lecteurs du
11e qui viennent de m'inviter. Pour l'apprendre, je dois ouvrir chaque groupe et lire sa liste de membres
en la comparant de mémoire à la liste de mes amis.

Le réseau est un graphe et l'app me le montre en deux colonnes. Ce qui en fait la valeur — qui lit avec
qui, par où passe une invitation, quel ami n'est relié à rien d'autre qu'à moi — n'est visible nulle part.

Deux choses aggravent ça :

- **Rien n'explique le badge.** La pastille rouge de l'onglet compte mes demandes d'ami, mes invitations de
  groupe et les demandes à examiner dans les groupes que j'administre. Elle m'envoie sur la liste Amis, qui
  n'en montre qu'une partie.
- **Les groupes n'ont pas de mémoire.** Ils vivent en mémoire (choix de 0028) et arrivent après la synchro
  de mon inventaire, parfois plusieurs minutes au premier lancement, et jamais hors ligne. Toute vue qui
  voudrait les dessiner s'ouvrirait vide puis se réarrangerait sous mes yeux.

Et quand un ami ou un groupe n'a pas de photo — à peu près quatre sur dix dans un échantillon réel —
l'app dessine un carré gris vide.

## Solution

Un troisième segment, **« Tout »**, en tête du contrôle de l'onglet Réseau, dessine mon réseau en
constellation : **« Vous »** au centre, mes groupes en anneau autour, mes amis placés près des groupes qu'ils
partagent avec moi. Les arêtes disent qui est où ; une invitation ou une demande d'ami reçue est en
pointillé. Le graphe s'ouvre cadré sur tout le réseau, se pince et se glisse toujours ; dézoomé, il passe
en vue d'ensemble (amis en pastilles, groupes en tuiles), zoomé il montre les noms. Toucher un nœud allume
ses liens, atténue le reste, et ouvre une feuille qui le résume — avec, pour une invitation ou une demande,
Accepter et Refuser — et qui mène à la fiche du groupe ou au profil.

Pour que ce graphe soit le même à chaque ouverture, les groupes sont désormais **persistés en SwiftData**
et synchronisés juste après les relations. Pour qu'il ne se couvre pas de carrés gris, un **repli d'avatar
partagé** — initiales pour un lecteur, glyphe pour un groupe — remplace le carré vide partout, listes
comprises.

« Tout » est compilé en `DEBUG` seulement jusqu'à la revue sur appareil, puis sort en 1.4.0. La persistance
des groupes, l'ordre de synchro et l'avatar partagé partent dès qu'ils sont prêts.

## User Stories

### Le segment et sa place

1. En tant que lecteur, je veux un segment « Tout » en premier dans l'onglet Réseau, pour voir mon réseau entier avant ses deux listes. (Q12, Q13)
2. En tant que lecteur, je veux que l'onglet Réseau s'ouvre sur « Tout » la première fois, puis sur le dernier segment que j'ai choisi, pour que qui préfère les listes n'ait pas à re-choisir. (Q12)
3. En tant que lecteur, je veux que le contrôle segmenté soit le contrôle natif d'iOS, pour qu'il se lise avec VoiceOver et grandisse avec la taille de texte. (Q13)
4. En tant que lecteur, je veux que le contrôle segmenté reste au même endroit, sous le titre, quel que soit le segment, pour qu'il ne saute pas quand je change de segment. (Q14)
5. En tant que lecteur, je veux que le graphe soit sur fond blanc, barre de navigation comprise, et que les listes gardent leur fond gris, comme dans la maquette. (Q14)
6. En tant que lecteur, je veux que le « + » de la barre, sur « Tout », ouvre un menu « Ajouter des amis lecteurs » / « Créer un groupe », pour agir sur les deux moitiés du réseau sans changer de segment. (Q15, Q15 bis, Q15 ter)
7. En tant que lecteur, je veux que ce menu soit un menu natif sans voile sur l'écran. (Q15 ter)
8. En tant que lecteur, je veux que le « + » d'Amis et celui de Groupes fassent ce qu'ils font aujourd'hui. (Q15)

### Ce que le graphe dessine

9. En tant que lecteur, je veux me voir au centre, avec ma photo et la pastille « Vous », pour savoir d'où part le réseau. (R1)
10. En tant que lecteur sans photo, je veux voir mes initiales à la place, pas un disque vide. (Q21)
11. En tant que lecteur, je veux voir les groupes dont je suis admin ou membre, chacun relié à moi par une arête pleine. (Q4)
12. En tant que lecteur invité dans un groupe, je veux voir ce groupe relié à moi en pointillé, sa carte en pointillé, avec « Invitation de Camille ». (Q4, Q9)
13. En tant que lecteur, je ne veux pas voir dans le graphe les groupes auxquels j'ai demandé à entrer : ils restent dans la liste Groupes. (Q4)
14. En tant que lecteur, je veux voir mes amis, et une arête entre un ami et chacun de mes groupes dont il est admin ou membre. (Q7)
15. En tant que lecteur, je veux qu'un ami présent dans deux de mes groupes soit dessiné une seule fois, avec une arête vers chacun. (déjà tranché)
16. En tant que lecteur, je veux que l'ami qui n'a aucun groupe en commun avec moi soit dessiné près de moi, relié à moi, et qu'il ne disparaisse jamais du graphe. (Q6)
17. En tant que lecteur qui a reçu une demande d'ami, je veux voir le demandeur dans le graphe, avatar au contour pointillé, relié à moi en pointillé. (Q5, Q5b)
18. En tant que lecteur, je ne veux pas voir les demandes d'ami que j'ai envoyées dans le graphe. (Q5)
19. En tant que lecteur, je ne veux pas voir dans le graphe les membres de mes groupes qui ne sont pas mes amis : ils comptent dans « N membres ». (Q8)
20. En tant que lecteur, je veux que chaque carte de groupe dise « Admin · 12 membres », « 12 membres » ou « Invitation de Camille ». (Q9)
21. En tant qu'admin d'un groupe où des demandes attendent, je veux le point rouge après le nom de la carte dans le graphe, pour que le graphe explique le badge de l'onglet. (Q22)
22. En tant que lecteur, je veux qu'un ami ou un groupe sans photo montre ses initiales ou le glyphe de groupe, sur un disque teinté, pas un carré gris. (Q20, Q21)
23. En tant que lecteur dont le pseudonyme est « olivier_berni », je veux les initiales « OB », pas « OL ». (Q20)
24. En tant que lecteur, je veux un compteur « 42 amis · 6 groupes » qui compte mes amis acceptés et les groupes dont je suis admin ou membre — sans demandes ni invitations. (Q10)
25. En tant que lecteur, je veux que les arêtes ami ↔ groupe et vous ↔ groupe soient vertes, et vous ↔ ami d'un vert plus léger, en clair comme en sombre. (Q32, Q32 bis)

### Le placement

26. En tant que lecteur, je veux que mes groupes soient rangés en anneau autour de moi, les miens d'abord (admin, puis membre, puis invitation), chaque bloc par ordre alphabétique, le premier en haut, dans le sens horaire. (Q16, Q18)
27. En tant que lecteur, je veux que chaque ami soit placé près des groupes qu'il partage avec moi, poussé vers l'extérieur. (Q16)
28. En tant que lecteur, je veux que le graphe soit le même à chaque ouverture tant que mon réseau n'a pas changé. (Q16, Q17)
29. En tant que lecteur, je veux que le graphe apparaisse déjà posé, sans animation d'installation. (Q23)
30. En tant que lecteur, quand un ami arrive, part ou qu'un groupe change, je veux que les nœuds glissent de leur ancienne place à la nouvelle, sauf si j'ai activé Réduire les animations. (Q17)
31. En tant que lecteur, je veux qu'aucun nœud n'en chevauche un autre, même avec une grande taille de texte, et qu'un nom trop long soit tronqué sur une ligne. (Q19)
32. En tant que lecteur, je veux que les arêtes passent sous les nœuds, et « Vous » au-dessus de tout. (Q19)

### Le zoom

33. En tant que lecteur, je veux que le graphe s'ouvre cadré sur tout mon réseau. (Q33)
34. En tant que lecteur, je veux pincer pour zoomer autour de mes doigts, et glisser pour me déplacer, toujours. (Q33)
35. En tant que lecteur, je ne veux pas pouvoir faire sortir le réseau de l'écran, ni dézoomer au-delà de « tout le réseau », ni zoomer au-delà d'environ deux fois la taille normale. (Q33)
36. En tant que lecteur qui ne pince pas, je veux des boutons Zoomer, Dézoomer et Recentrer en bas à droite, toujours visibles. (Q34)
37. En tant que lecteur, je veux que Recentrer me ramène au cadrage d'ouverture, centré sur moi. (Q33)
38. En tant que lecteur, je veux que ces boutons et le compteur soient en verre, comme les autres contrôles flottants d'iOS 26. (Q35)
39. En tant que lecteur d'un grand réseau, je veux qu'en dézoomant les amis deviennent des pastilles sans nom et les groupes des tuiles compactes, et que « Vous » rétrécisse. (Q31, R3)
40. En tant que lecteur, je veux que ce passage dépende seulement de l'échelle, sans clignoter autour du seuil. (Q31)
41. En tant que lecteur en vue d'ensemble, je veux que les arêtes vous ↔ ami disparaissent, sauf celles des amis sans groupe commun et des demandeurs. (Q6, R3)
42. En tant que lecteur en vue d'ensemble, je veux pouvoir toucher une pastille de 24 pt : la zone de toucher fait 44 pt et le nœud le plus proche gagne. (Q36)
43. En tant que lecteur, je veux que les pastilles montrent la photo ou un disque teinté uni, sans initiales minuscules. (Q37)

### Toucher un nœud

44. En tant que lecteur, je veux qu'en touchant un nœud ses arêtes s'allument, que ses voisins restent nets et que le reste passe à 30 %. (R2)
45. En tant que lecteur, je veux qu'un groupe touché prenne le même aspect sélectionné quel que soit mon rôle. (Q25)
46. En tant que lecteur, je veux qu'une feuille native s'ouvre, à la hauteur de son contenu, et que le graphe derrière reste manipulable. (Q24, Q24b)
47. En tant que lecteur, je veux que toucher un autre nœud remplace le contenu de la feuille sans la refermer. (Q24b)
48. En tant que lecteur, je veux que toucher le vide, ou glisser la feuille vers le bas, la referme et efface la sélection. (Q24b)
49. En tant que lecteur, je veux que le graphe se décale juste assez si le nœud touché passe sous la feuille, sans changer le zoom. (Q30)
50. En tant que lecteur, je veux que la feuille d'un groupe dise son nom, « Admin · 12 membres, dont 4 de vos amis : Inès, Léa, Rémi et Camille. », leurs avatars, et « Ouvrir le groupe ». (R2, Q29 bis)
51. En tant que lecteur, je veux qu'au-delà de quatre amis en commun la phrase nomme les trois premiers puis « et N autres », avec au plus cinq avatars. (Q29, Q29 bis)
52. En tant que lecteur, je veux que la phrase s'arrête au nombre de membres quand je n'ai aucun ami dans le groupe. (Q29)
53. En tant que lecteur invité, je veux que la feuille du groupe me propose Accepter, Refuser et « Ouvrir le groupe ». (Q26)
54. En tant que lecteur qui a reçu une demande d'ami, je veux que la feuille du demandeur dise qui il est, depuis quand il est membre, et me propose Accepter, Refuser et « Voir le profil ». (Q5, Q26)
55. En tant que lecteur, je veux qu'après Accepter le pointillé devienne plein sous mes yeux et que la feuille reste ouverte sur le nouvel état. (conséquence)
56. En tant que lecteur, je veux qu'après Refuser le nœud disparaisse et que la feuille se ferme. (conséquence)
57. En tant que lecteur, je veux qu'Accepter et Refuser réagissent tout de suite, et qu'un échec serveur me soit signalé et défasse le geste. (ADR 0001)
58. En tant que lecteur, je veux qu'en touchant un ami, lui, ses arêtes vers ses groupes et vers moi, et ses groupes s'allument. (Q27)
59. En tant que lecteur, je veux que la feuille d'un ami dise « Membre depuis … », « 1 groupe en commun : Club de Belleville. », et me propose « Voir le profil ». (Q27, Q27 bis)
60. En tant que lecteur, je veux qu'un groupe où je suis seulement invité ne compte pas comme groupe en commun, même s'il reste allumé. (Q27 bis)
61. En tant que lecteur, je veux que « Ouvrir le groupe » et « Voir le profil » ferment la feuille puis ouvrent l'écran, avec le retour arrière qui me ramène au graphe. (conséquence)
62. En tant que lecteur, je veux que toucher « Vous » ne fasse rien. (Q28)

### États

63. En tant que nouveau lecteur sans ami ni groupe, je veux voir « Vous » seul, une phrase qui dit ce qui viendra ici, et deux actions : « Ajouter des amis lecteurs » et « Trouver un groupe » — sans boutons de zoom ni compteur. (Q39)
64. En tant que lecteur au premier lancement, je veux voir ce qui est déjà arrivé, avec une pastille « Synchronisation… » à la place du compteur tant que relations ou groupes n'ont jamais répondu. (Q40)
65. En tant que lecteur au premier lancement hors ligne, je veux une pastille « Réessayer » qui relance la synchro, et jamais « Tirez vers le bas » sur un écran qui ne défile pas. (Q41)
66. En tant que lecteur hors ligne qui a déjà synchronisé, je veux voir mon réseau tel qu'à la dernière synchro, sans message. (Q11, Q41)
67. En tant que lecteur en mode sombre, je veux que le graphe suive l'apparence, ses arêtes et ses nœuds restant lisibles sur noir. (Q42, Q32 bis)
68. En tant que lecteur avec une grande taille de texte, je veux que les noms grandissent jusqu'à une taille plafonnée, au-delà de laquelle les listes et VoiceOver prennent le relais. (Q43)
69. En tant que lecteur VoiceOver, je veux entendre « Vous », puis mes demandes et invitations, puis chaque groupe en nommant ses amis, puis chaque ami une fois en nommant ses groupes communs. (Q44)
70. En tant que lecteur VoiceOver, je veux des actions sur chaque nœud : Ouvrir, Voir le profil, Accepter, Refuser. (Q44)
71. En tant que lecteur VoiceOver, je veux que les boutons de zoom aient un nom. (déjà tranché)
72. En tant que lecteur avec Réduire les animations, je veux que rien ne glisse. (Q17)

### Les groupes persistés

73. En tant que lecteur, je veux que mes groupes soient là dès l'ouverture de l'app, avant toute synchro, et hors ligne. (Q11)
74. En tant que lecteur, je veux qu'au premier lancement mes groupes arrivent juste après mes amis, avant mon inventaire. (Q11c)
75. En tant que lecteur, je veux qu'un groupe que j'ai quitté, ou dont l'invitation a été retirée, disparaisse à la synchro suivante. (Q11)
76. En tant que lecteur, je veux qu'une synchro mette à jour mes groupes sans faire sauter un écran ouvert sur l'un d'eux. (ADR 0001)
77. En tant que lecteur qui se déconnecte ou supprime son compte, je veux que mes groupes soient effacés de l'appareil avec le reste. (0025, 0017)
78. En tant que lecteur qui met l'app à jour, je veux qu'elle s'ouvre normalement sur un store existant. (Q11)

### Les listes

79. En tant que lecteur, je veux que les listes Amis et Groupes montrent le même repli que le graphe — initiales ou glyphe de groupe — au lieu d'un carré gris. (Q21)
80. En tant que lecteur, je veux que les listes gardent tout ce qu'elles font aujourd'hui, sections, tri, actions et identifiants compris. (déjà tranché)

### Livraison

81. En tant que développeur, je veux que « Tout » n'existe qu'en `DEBUG` jusqu'à la revue sur appareil, pour que les tranches intermédiaires ne partent pas en production. (Q47)
82. En tant que développeur, je veux que la persistance des groupes, l'ordre de synchro et l'avatar partagé puissent partir sans « Tout ». (Q47)
83. En tant que développeur, je veux une étape du scénario de bout en bout qui ouvre Réseau, « Tout », touche un groupe et ouvre sa fiche. (Q46)

## Implementation Decisions

### Modules

**1. Groupes persistés.** Un modèle SwiftData par groupe, identifié par l'`_id` serveur (unique), qui porte
`_rev`, nom, slug, description, image (URL déjà absolue), ouvert/cherchable, et les listes de rôles (admins,
membres, invités, refusés, demandeurs) en tableaux de memberships `{user, invitor, timestamp}` — des ids,
**aucune relation SwiftData vers `User`** (Q11b). `init(dto:)` + `update(from:)` idempotent et sans écraser
une bonne valeur locale par une absence (ADR 0001). Seuls les groupes où j'ai un rôle sont persistés ; un
groupe ouvert depuis la recherche reste en mémoire comme aujourd'hui.

- Le type valeur `ReaderGroup` reste le type de domaine : ses transitions (`applying`), `role(of:)`,
  `memberIds`, `memberCount`, `invitor(of:)` et leurs tests ne bougent pas. Le modèle persisté se convertit
  en `ReaderGroup` et inversement. Le nom exact du `@Model` est libre ; le critère est que les 12 tests
  purs de `ReaderGroup` passent sans changement.
- `GroupModel` lit et écrit le store au lieu de son dictionnaire. La synchro `GET /api/groups` + les
  relectures `by-id` du registre de demandes font un **upsert avec portée de suppression** : un groupe de
  la portée absent de la réponse est supprimé (précédent : feature 0019). Les gestes optimistes de 0028
  (accepter, refuser, quitter, inviter…) écrivent dans le store et se réconcilient ou se défont.
- `hasLoaded` / `syncFailed` en mémoire sont remplacés : « déjà synchronisé au moins une fois » vit dans
  `SyncStatusStore` (marqueur persistant, comme `.community`), l'échec de la dernière synchro reste un état
  en mémoire.
- La liste Groupes lit par `@Query` (ADR 0001, invariant 1).
- Le schéma du `ModelContainer` gagne ce modèle. Migration légère automatique, sans `VersionedSchema`,
  comme les trois ajouts de propriétés livrés depuis 1.1.0. Un test ouvre un store au schéma précédent et
  vérifie qu'il s'ouvre au nouveau.
- La déconnexion (feature 0025) et la suppression de compte (feature 0017) effacent ces groupes.
- `GroupRequestLedger` reste la seule source des demandes envoyées (Q4).

**2. Ordre de synchro.** Mon utilisateur, mes étagères, **relations, groupes**, mon inventaire, listes,
transactions, inventaires des amis (Q11c). Rien d'autre ne change dans 0027.

**3. Avatar partagé.**
- Une fonction pure d'initiales : une lettre par mot si le pseudonyme contient des séparateurs
  (`_`, `.`, `-`, espace, changement de casse), sinon ses deux premières lettres ; majuscules, accents
  gardés ; une chaîne vide donne une chaîne vide (Q20).
- Une vue de repli : lecteur = cercle `backgroundTinted` + initiales `foregroundTinted` ; groupe = carré
  arrondi `backgroundTinted` + `person.2` (Q21). Deux tailles de typographie : `action300` à 44 pt et plus,
  `action200` en dessous (Q21 bis). Un groupe n'est jamais un cercle (règle de `GroupCellView`).
- `CellThumbnail` (ou la vue qui l'enveloppe pour les lecteurs et les groupes) montre ce repli quand
  l'URL est absente ou que le chargement échoue, au lieu du carré `backgroundDisable`.
- Adopté par `UserCellView`, `GroupCellView` et leurs dérivés (invitations, membres), par les nœuds du
  graphe et par les feuilles.
- L'URL d'avatar d'un `User` passe par `APIService.absoluteImageUrl`, comme celle d'un groupe.

**4. `NetworkGraph` — le graphe, en pur.** Entrée : un instantané en types valeur (mon id, ma photo et
mon pseudonyme ; les amis acceptés et les demandeurs reçus — id, pseudonyme, photo, date d'inscription ;
mes groupes admin/membre/invité en `ReaderGroup` ; le nombre de demandes à examiner par groupe que
j'administre). Sortie :
- nœuds : `me`, `group(id, role, pendingCount)`, `friend(id, state: friend | requested)` ;
- arêtes typées : me↔groupe (pleine si admin/membre, pointillée si invité), ami↔groupe (admin ou membre
  seulement, Q7), me↔ami (pleine) et me↔demandeur (pointillée), avec, pour chaque ami, s'il est **isolé**
  (aucun groupe commun, Q6) ;
- le compteur : amis acceptés, groupes admin/membre (Q10) ;
- pour un groupe : ses amis, triés ; pour un ami : ses groupes **communs** (admin/membre seulement,
  Q27 bis) et ceux où je suis invité (allumés, non comptés) ;
- l'ordre de lecture VoiceOver (Q44) ;
- les voisins à allumer pour une sélection (R2, Q27).
Aucune dépendance à SwiftUI ni SwiftData. Un snapshot est bâti à partir des `@Query` de la vue.

**5. Règles de texte, en pur.** La règle des noms (jusqu'à 4 nommés ; au-delà, 3 puis « et N autres »,
N ≥ 2 ; au plus 5 avatars — Q29 bis) et la composition des phrases des feuilles et du compteur, avec des
clés `Localizable.xcstrings` à substitutions plurielles (`%#@…@`), `.list(type: .and)` pour les noms, une
espace fine insécable avant « : ». Clés réutilisées : `groups.role.admin`, `groups.members_count`,
`groups.invited_by`, `user.member_since`, `network.invitation.accept` / `.refuse`,
`network.invitation.explanation`, `network.add_friends`, `groups.create`, `groups.find`. Clés neuves :
« Tout », « Vous », « Ouvrir le groupe », « Voir le profil », « dont N de vos amis », « et N autres »,
« N groupes en commun », le compteur à deux pluriels, « Synchronisation… », « Réessayer » (réutiliser une
clé existante si elle dit exactement ça), la phrase de l'état vide, les libellés Zoomer / Dézoomer /
Recentrer et les libellés VoiceOver des nœuds.

**6. `NetworkGraphLayout` — le placement, en pur, `nonisolated`.** Entrée : le graphe et la taille mesurée
de chaque nœud (texte réel, Dynamic Type). Sortie : une position par nœud et la boîte englobante, en
coordonnées « monde » centrées sur « Vous ». Algorithme (Q16) : groupes sur un anneau dans l'ordre rôle
puis nom, premier en haut, sens horaire (Q18) ; chaque ami au barycentre de ses groupes, poussé vers
l'extérieur ; amis isolés et demandeurs sur un anneau proche de « Vous » ; puis une relaxation à graine
fixe qui garantit **zéro chevauchement** des boîtes (Q19). La graine vient de `DeterministicTilt` sur les
`_id`, jamais de `String.hashValue`. Même entrée, même sortie. Mis en cache par empreinte des données et
des tailles (Q45), calculé hors de l'acteur principal.

**7. `GraphViewport` — la caméra, en pur.** Comme `CoverZoom`, mais ancrée au point de pincement et bornée.
Il connaît : la transformation monde → écran ; le cadrage d'ouverture (tout le réseau, centré sur Vous) ;
échelle min = ce cadrage, max ≈ ×2 de la pleine taille (Q33) ; pincement ancré aux doigts, glissement
borné pour que le réseau ne quitte pas l'écran ; pas de ±×1,5 pour les boutons ; recentrer = cadrage
d'ouverture ; le niveau sémantique (plein / vue d'ensemble) avec hystérésis — bascule sous ≈ ×0,6, retour
au-dessus de ≈ ×0,7 de la pleine taille, valeurs à régler sur appareil (Q31) ; le toucher : le centre de
nœud le plus proche dans 44 pt d'écran (Q36) ; le panoramique minimal qui sort un nœud de sous la feuille
(Q30). Testé comme `CoverZoomTests`.

**8. L'interface.**
- `NetworkSegment` gagne `.all`, déclaré en premier, **sous `#if DEBUG`** (Q47). Le segment choisi est
  retenu (`@AppStorage`) ; une valeur retenue absente de la build retombe sur Amis (Q12).
- `NetworkView` : le `Picker` natif sort de la `List` vers un bandeau fixe sous le titre
  (`safeAreaInset(edge: .top)`) pour les trois segments (Q14) ; Amis et Groupes restent des `List` avec
  `applyListBackground()` ; Tout est sur `backgroundDefault`, barre de navigation comprise. Le « + » de
  Tout est un `Menu` natif à deux entrées (Q15). Tous les identifiants `e2e.*` existants survivent.
- La vue du graphe : arêtes dans un `Canvas` (couleurs des tokens via `DesignSystem.Color.x.color`,
  pointillé `[4,4]`) ; nœuds en vraies vues `Button` placées par `.position` à partir du viewport — la
  taille des nœuds ne change pas avec le zoom, seules les positions bougent ; `MagnifyGesture` +
  `DragGesture` ; atténuation 30 % des nœuds et 12 % des arêtes non allumées, arêtes allumées 2,5 pt ;
  arêtes vous ↔ ami en `foregroundTinted` 1 pt à 30 % (Q32 bis) ; un seul style d'arête par niveau
  sémantique (Q32).
- Nœuds : « Vous » (72 pt, anneau `backgroundTintedInverse`, pastille « Vous », ×0,7 en vue d'ensemble) ;
  ami (44 pt + nom `footnote200`, état sélectionné et état demandeur au contour pointillé) ; pastille
  24 pt (photo ou disque teinté) ; carte de groupe (rôle, détail, point rouge, état sélectionné unique,
  invité en pointillé) ; tuile compacte. Les tailles hors tokens vivent dans une struct de métriques de
  la feature (précédents : `ShelfCardMetrics`, `SortGridMetrics`) — aucun token nouveau.
- Contrôles flottants : Zoomer / Dézoomer / Recentrer en `.buttonStyle(.glass)` dans un
  `GlassEffectContainer`, avec libellés et `.labelStyle(.iconOnly)` ; la pastille d'état (compteur,
  « Synchronisation… », « Réessayer ») en `.glassEffect`. À 16 pt des bords de la zone sûre, au-dessus de
  la barre d'onglets (Q34, Q35).
- La feuille : `.sheet` native, un seul detent `.height` mesuré, `presentationBackgroundInteraction`
  activé ; contenu remplacé quand la sélection change ; fermeture = sélection effacée (Q24, Q24b). Quatre
  contenus : groupe, invitation, demandeur, ami (Q26, Q27). Accepter / Refuser appellent les gestes
  optimistes existants de `GroupModel` et `UserModel` (ADR 0001). « Ouvrir le groupe » / « Voir le
  profil » ferment la feuille puis poussent `.group(id:)` / `.user(user:)` sur le path de `NetworkView`.
- États : vide (Q39), synchro (Q40), échec au premier lancement avec « Réessayer » (Q41).
- Dynamic Type plafonné à `.xxxLarge` sur le graphe seul (Q43) ; Réduire les animations coupe les
  transitions (Q17) ; VoiceOver lit l'ordre de `NetworkGraph` avec des actions personnalisées (Q44).
- Images dans le `Canvas` : aucune ; les photos sont dans les vues nœuds, via le chargeur existant.

**9. Bout en bout.** Identifiants `e2e.network.graph.*` sur le graphe, les nœuds, la feuille et ses
boutons ; `E2EDriver` apprend l'onglet Réseau ; une étape ouvre Réseau, Tout, touche un groupe, « Ouvrir
le groupe », revient (Q46). Le scénario n'est lancé que sur demande d'Olivier.

### Contraintes

- iOS 26, Swift 6.2, SwiftUI seulement, pas de paquet SPM nouveau.
- Les trois modules purs sont `nonisolated` (la cible est `MainActor` par défaut).
- Le code fait foi sur Figma ; les écarts se notent dans `docs/design-system/figma-library.md`.

## Testing Decisions

Un bon test porte sur le comportement observable d'un module par son interface publique — ce qu'il rend
pour une entrée donnée — jamais sur ses détails internes. Pas de réseau réel, pas de store sur disque :
`MockAPIService`, `MockURLProtocol` et `TestStore` (`Tests/Support/`). Swift Testing (`@Suite`, `@Test`,
`#expect`).

Modules testés :

- **Groupes persistés** : upsert en place (l'identité d'un objet survit à une synchro) ; portée de
  suppression (un groupe quitté disparaît, un groupe de recherche n'est pas touché) ; un DTO clairsemé
  n'efface pas une valeur ; gestes optimistes réconciliés et défaits ; purge à la déconnexion ; ouverture
  d'un store au schéma précédent. Précédents : `GroupModelTests`, `UserRelationTests`,
  `FriendShelvesLifecycleTests`.
- **Ordre de synchro** : les groupes sont demandés avant l'inventaire. Précédent : les tests de
  `RootView+RefreshUserData` s'il y en a, sinon un test sur l'ordre des appels au `MockAPIService`.
- **Initiales** : `olivier_berni` → « OB », `Léa` → « LÉ », `Aïcha` → « AÏ », `JeanLuc` → « JL »,
  chaîne vide, emoji, un seul caractère.
- **`NetworkGraph`** : nœuds et arêtes pour la constellation R1 (fixture des maquettes) ; ami dans deux
  groupes = un nœud et deux arêtes ; ami isolé marqué isolé ; demandeur pointillé et isolé ; invitation
  pointillée ; non-amis absents ; compteur (R1 : 8 · 2, R3 : 42 · 6) ; groupes communs sans les
  invitations ; ordre VoiceOver ; voisins allumés.
- **Règles de texte** : 0, 1, 4, 5 et 6 amis ; nom long.
- **`NetworkGraphLayout`** : même entrée, mêmes positions (y compris d'un lancement à l'autre, comme
  `DeterministicTiltTests`) ; zéro chevauchement sur R1, R3 et un réseau de 200 amis + 30 groupes ; ordre
  des groupes ; isolés plus proches de « Vous » que les autres ; temps de calcul sous un budget pour
  200 + 30. Précédents : `ShelfBooksLayoutTests`, `CoverWallGeometryTests`.
- **`GraphViewport`** : cadrage d'ouverture ; bornes ; pincement ancré (le point sous les doigts ne bouge
  pas) ; pas de ±×1,5 ; recentrer ; hystérésis ; toucher au plus proche dans 44 pt ; panoramique minimal.
  Précédent : `CoverZoomTests`.
- **Bout en bout** : l'étape ci-dessus, écrite, compilée, **non lancée** sans demande.

Les vues ne sont pas testées unitairement. La passe sur appareil (sombre, VoiceOver, grande taille de
texte, vrai compte, 60 i/s en panoramique avec 200 amis + 30 groupes, Q45) est une issue HITL.

## Out of Scope

- Android : le Réseau Android reste amis seulement ; le graphe y est noté « non porté » (Q1).
- R4 : la minicarte et tout indicateur de bord pour les nœuds hors champ (Q3, Q38).
- Les groupes d'un ami dont je ne suis pas membre : aucun endpoint ne les donne.
- Les membres non amis de mes groupes dans le graphe (Q8).
- Les demandes d'ami envoyées et les demandes d'adhésion envoyées dans le graphe (Q4, Q5).
- Les comptes de livres dessinés dans R5 / R6 (« 42 livres », « 340 livres ») : non construits, comme en
  0028.
- Toucher « Vous » (Q28).
- L'avatar caché de l'en-tête de profil.
- Un mode de couleur forcé pour le graphe : il suit le système (Q42).
- L'iPad : l'app est iPhone seulement.

## Further Notes

- La maquette de référence est l'état du 2026-10-13 de la section `512:15486` ; le panneau « Décisions »
  y résume ce PRD. Les composants locaux y sont `Graph / Me`, `Graph / Friend` (Default, Highlighted,
  Requested), `Graph / Friend · Dot` (Default, Requested), `Graph / Group` (rôle × état, « Show pending »),
  `Graph / Group · Compact`, `Graph / Zoom Controls`, `Graph / Status Pill`, `Avatar · Repli`.
- Glyphes : Figma n'a pas `minus`, `scope`, `person.badge.plus` ni `arrow.clockwise` ; le code prend les
  SF Symbols `minus`, `scope`, `person.badge.plus`, `arrow.clockwise`.
- Le compteur de R3 d'origine (« 42 amis · 7 groupes ») est faux sous Q10 ; R3′ dit « 6 groupes ».
- `network.invitation.explanation` dit « ne le prévient pas » au masculin : chaîne existante, gardée.
- La documentation dérive à corriger au passage : CLAUDE.md dit que `MainTabView` possède les
  `NavigationPath` (c'est chaque racine d'onglet) ; 0028 parle d'un « 4e onglet » (Réseau est le 3e) et de
  groupes « en mémoire » (désormais persistés).
- Feature doc à écrire à la fin : `docs/features/0035-…` (0034 est pris), entrée dans
  `docs/design-system/figma-library.md` pour les passes du 2026-10-13, ligne dans CLAUDE.md.
