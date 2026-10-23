# Réseau · Graphe — décisions du grilling

Source : [Figma 512:15486](https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=512-15486) ·
extraction dans [design/](design/overview.md). Grilling du 2026-10-13.

## Décisions

| # | Sujet | Décision | Pourquoi |
|---|-------|----------|----------|
| Q1 | Plateforme | iOS seulement. Android garde son Réseau amis-seulement, le graphe est noté « non porté » dans le feature doc. | Android n'a aucun groupe (0028 non porté) : le graphe y serait une étoile. |
| Q2 | Trous de la maquette | Compléter Figma **avant** le code. | Choix d'Olivier. |
| Q2b | Qui dessine | Claude, après le grilling, dans la section 512:15486 (figma-use, composants locaux, tokens existants). Olivier valide la passe Figma avant le PRD. | Les règles tranchées ici disent quoi dessiner. |
| Q3 | Tranches | Deux tranches : (1) segment Tout, constellation, pincer/glisser, carte (R1/R2) ; (2) zoom sémantique, contrôles, compteur (R3). **Pas de minicarte** (R4 abandonné tant qu'un appareil n'a pas montré qu'elle manque). | R4 contredit sa propre minicarte ; aucun précédent. |
| Q4 | Groupes-nœuds | Admin, membre, invitations reçues (pointillé). Demandes envoyées : liste Groupes seulement. | `GET /api/groups` ne rend pas les demandes ; registre local = graphe différent par appareil. |
| Q5 | Demandes d'ami | Les demandes **reçues** sont dans le graphe : arête vous ↔ ami en pointillé, Accepter / Refuser dans la carte. Les envoyées non. | Choix d'Olivier. Le badge Réseau a désormais une contrepartie dans Tout. |
| Q5b | Nœud demandeur | Graph / Friend gagne un état `Requested` : contour d'avatar en pointillé `foregroundTinted` (grammaire de Invited) + arête pointillée [4,4]. Nom seul, pas de détail. | Même grammaire que l'invitation de groupe. |
| Q6 | Amis sans groupe commun | Dessinés près de Vous, reliés par leur arête vous ↔ ami, **gardée en vue d'ensemble pour eux seuls** (pleine, ou pointillée pour un demandeur). | Un ami ne disparaît pas de Tout ; sans arête il flotte. |
| Q7 | Arêtes ami ↔ groupe | Admins et membres (`memberIds`) seulement. | by-id ne rend que ceux-là ; le pointillé reste réservé à ce qui me concerne. |
| Q8 | Membres non amis | Jamais dessinés ; comptés dans « N membres ». | Explosion du nombre de nœuds. |
| Q9 | Détail carte groupe | Format R1 partout : « Admin · N membres », « N membres », « Invitation de X ». | Clés existantes ; R4 « 9 membres · 6 amis » écarté. |
| Q10 | Compteur | Effectifs : amis acceptés · groupes admin/membre. Demandes et invitations exclues. | Le compteur dit ce que j'ai. |
| Q11 | Persistance des groupes | **SwiftData** (renverse la décision « en mémoire » de 0028). | Choix d'Olivier. Précédent : 3 `@Model` ont gagné des propriétés depuis 1.1.0 en migration légère sans `VersionedSchema` ; ajouter une entité est aussi léger. Risque : `fatalError` de `ReCIT.swift:86` si la migration échoue. |
| Q11b | Forme du modèle | `@Model ReaderGroup` (`_id` unique, `_rev`, nom, picture, slug…) qui garde les tableaux d'ids par rôle ; `init(dto:)` + `update(from:)` + `upsert` (ADR 0001). Pas de relation SwiftData vers `User`. | Arêtes = ids ∩ `User` amis ; purge et upsert simples. |
| Q11c | Ordre de synchro | relations → **groupes** → mon inventaire → inventaires des amis. | Graphe complet en quelques secondes au premier lancement. |
| Q12 | Segment par défaut | Tout au premier lancement, puis dernier segment retenu (`@AppStorage`). | R1 ; respecte qui préfère les listes. |
| Q13 | Contrôle segmenté | `Picker` natif `.segmented`, 3 cas. Le composant `Chrome / Segmented Control · 3` est un stand-in système. | VoiceOver, Dynamic Type, Liquid Glass gratuits ; pas d'UIKit. |
| Q14 | Placement du contrôle | Bandeau fixe sous le titre (`safeAreaInset(edge: .top)`) sur les trois segments. Titre grand sur Tout ; repli sur les listes à vérifier sur appareil. | Le contrôle ne saute pas au changement de segment. |
| Q15 | « + » sur Tout | Menu : « Ajouter des amis » + « Créer un groupe ». Amis / Groupes inchangés. | Tout ne privilégie ni amis ni groupes ; chaînes existantes. |
| Q16 | Algorithme | Radial puis relaxation : groupes sur un anneau autour de Vous, amis au barycentre de leurs groupes poussés vers l'extérieur, amis isolés près de Vous, puis passe de forces à graine fixe (`DeterministicTilt`) pour les collisions. Fonction pure `nonisolated`, Swift Testing. | Reproduit R3 et la promesse de déterminisme. |
| Q17 | Données qui changent | Recalcul déterministe depuis les données triées par id ; transition animée ancienne → nouvelle position, coupée avec Réduire les animations. Aucune position persistée. | Mêmes données = même image. |
| Q18 | Ordre des groupes | Rôle (admin, membre, invitation) puis nom (`localizedStandardCompare`) ; premier en haut, sens horaire. | Stable, cohérent avec R1/R3. |
| Q19 | Collisions | Zéro chevauchement mesuré avec le texte réel ; noms sur une ligne tronquée ; z-order arêtes < amis < groupes < sélection < Vous ; arêtes droites sous les nœuds. | Dynamic Type rend les tailles Figma caduques. |
| Q20 | Initiales | Une lettre par mot si séparateurs (`_ . -` espace, changement de casse), sinon les deux premières lettres ; majuscules, accents gardés. Fonction pure testée. | Pseudonymes inventaire.io. |
| Q21 | Repli sans photo | Composant d'avatar partagé : initiales sur `backgroundTinted` (utilisateur, Vous compris), `person.2` (groupe). Sert au graphe, à la carte et aux listes R5/R6. | Un seul repli au lieu de trois. |
| Q22 | Point rouge 0033 | Oui, `PendingDot` après le nom de la carte groupe dans le graphe. | Tout est le segment par défaut ; il doit expliquer le badge. |
| Q23 | Ouverture | Graphe déjà posé ; seules sélection et changements de données s'animent. | « Ne bouge pas d'une ouverture à l'autre ». |
| Q24 | Résumé d'un nœud | **`.sheet` native** avec `presentationBackgroundInteraction(.enabled(upThrough:))` (et non la carte flottante de R2) : elle couvre la tab bar. | Choix d'Olivier. |
| Q24b | Hauteur / échange | Un seul detent `.height` mesuré au contenu, sans `.large`. Toucher un autre nœud remplace le contenu sans refermer ; toucher le vide ou glisser vers le bas ferme et efface la sélection. | |
| Q25 | Groupe sélectionné | Un seul état sélectionné pour tous les rôles : `backgroundTintedInverse` + `foregroundInverse`. | La feuille dit le rôle. |
| Q26 | Invitation / demande touchée | Feuille avec Accepter / Refuser (optimistes, ADR 0001) + « Ouvrir le groupe » ; pour un demandeur, Accepter / Refuser + « Voir le profil ». | Mêmes gestes que les rangées de liste. |
| Q27 | Ami touché | Feuille : avatar, pseudonyme, « Membre depuis … », « N groupes en commun : … », « Voir le profil ». Allumés : l'ami, ses arêtes vers ses groupes et vers Vous, ces groupes. | Pendant de la feuille groupe, sans compte de livres. |
| Q28 | Toucher « Vous » | Rien ; VoiceOver le lit comme un en-tête. | |
| Q29 | Texte feuille groupe | Au plus 3 pseudonymes puis « et N autres », au plus 5 avatars ; 0 ami → la phrase s'arrête au nombre de membres. Pluriels à substitution, `.list(type: .and)`, espace fine insécable avant « : ». | Deux lignes comme R2. |
| Q30 | Recadrage | Panoramique minimal animé si le nœud touché passe sous la feuille ; zoom inchangé. | |
| Q31 | Seuil de la vue d'ensemble | Échelle courante seule, avec hystérésis (proposé : bascule sous ≈ ×0,6, retour au-dessus de ≈ ×0,7, à régler sur appareil). Le nombre de nœuds ne fixe que l'échelle d'ouverture (cadrer tout). | R4 montre qu'on revient à R3 en dézoomant ; pas de clignotement. |
| Q32 | Styles d'arête | Deux jeux : vue pleine = R1, vue d'ensemble = R3. Un seul pointillé `[4,4]` (arêtes, carte invitée, anneau demandeur). | Les écarts R1/R4 sont des dérives de maquette. |
| Q33 | Plage de zoom | Min = tout le réseau cadré ; max ≈ ×2 ; + / − = ×1,5 animé autour du centre ; pincer zoome autour des doigts ; recentrer = cadrage d'ouverture (centré sur Vous) ; le réseau ne quitte pas l'écran. | Un seul geste de retour. `CoverZoom` (centré, sans bornes) est à étendre. |
| Q34 | Contrôles + compteur | Toujours visibles sur Tout. | Alternative au pincement, VoiceOver ; interface constante. |
| Q35 | Style des contrôles | Liquid Glass : `.buttonStyle(.glass)` dans un `GlassEffectContainer`, libellés + `.labelStyle(.iconOnly)`, compteur en `.glassEffect`. La capsule Figma est un stand-in. | Flottent sous une tab bar en verre ; Shadow/Light disparaît en sombre. |
| Q36 | Toucher en vue d'ensemble | Zone invisible de 44 pt, le centre le plus proche gagne ; sélection + feuille sans changer le zoom. | Minimum tactile ; même geste partout. |
| Q37 | Pastilles 24 pt | Pas d'initiales : photo, ou disque `backgroundTinted` uni. | 9 pt hors échelle et hors Dynamic Type. |
| Q38 | Repérage zoomé | Rien de plus en v1 (arêtes sortantes, recentrer, compteur). Réévalué après la revue sur appareil. | Pas de minicarte (Q3). |
| Q39 | État vide | « Vous » seul au centre, une phrase, « Ajouter des amis lecteurs » et « Trouver un groupe » (logique 0021/0022, chaînes existantes). Contrôles de zoom et compteur masqués dans ce seul cas. | Dire le premier pas. |
| Q40 | Chargement / synchro partielle | On dessine le store ; tant que relations ou groupes n'ont jamais répondu, une pilule « Synchronisation… » remplace le compteur. Arrivée des données = transition de Q17. | Ne concerne presque que le premier lancement (Q11, Q11c). |
| Q41 | Échec de synchro | Silence : on montre le store (dernière synchro réussie). Seul cas visible : premier lancement jamais synchronisé → la pilule de Q40 devient « Réessayer ». Pas de « Tirez vers le bas » sur Tout. | Le store couvre le hors-ligne ; `.refreshable` n'atteint pas un canvas. |
| Q42 | Sombre | Passe sombre Figma par mode de variables (R1 et R3 en Dark) avant le code ; correction éventuelle (bordure / fond de nœud) via tokens existants, documentée. | Défaut D9 : Shadow/Light disparaît en sombre. |
| Q43 | Dynamic Type | Les nœuds grandissent ; le graphe seul est plafonné à `.xxxLarge` (premier plafond du repo, documenté) ; feuilles et listes sans plafond. | Listes et VoiceOver donnent l'équivalent aux tailles accessibilité. |
| Q44 | VoiceOver | Vous (en-tête) → demandes et invitations reçues → chaque groupe (ordre Q18), libellé nommant ses amis → chaque ami une fois (alpha), libellé nommant ses groupes communs. Actions personnalisées : Ouvrir, Voir le profil, Accepter, Refuser. Contrôles de zoom libellés. | Pas de doublon pour un ami dans plusieurs groupes. |
| Q45 | Performance | Budget : 200 amis + 30 groupes à 60 i/s en panoramique. Placement `nonisolated` hors acteur principal, mis en cache par empreinte des données. Au-delà : pas de photos sur les pastilles de la vue d'ensemble. Mesure Instruments avant livraison. | Nuke : 100 images en mémoire ; cible MainActor par défaut. |
| Q46 | Tests | Swift Testing : placement, transformation de vue, constructeur nœuds/arêtes, initiales, texte de feuille, migration du store. Étape e2e minimale (`e2e.network.graph.*` : Réseau → Tout → toucher un groupe → « Ouvrir le groupe » → retour), lancée seulement sur demande. | L'e2e a attrapé 0065 et 0067. |
| Q47 | Livraison | Persistance + ordre de synchro + avatar partagé partent dès qu'ils sont prêts. Le cas `.all` de `NetworkSegment` n'existe qu'en `#if DEBUG` jusqu'à la revue sur appareil des deux tranches, puis sort en 1.4.0 avec ses notes de version. | Pas de feature flag dans l'app. |
| Q48 | Suite | Passe Figma (Claude) → validation Olivier → `olive-skills:to-prd` → `olive-skills:to-issues` (tranches verticales : persistance + synchro des groupes ; avatar partagé + listes ; segment Tout + constellation + feuilles ; demandes / invitations dans le graphe ; zoom sémantique + contrôles ; états + accessibilité ; e2e) → `implement-feature` → feature doc 0034, `figma-library.md` mis à jour, CLAUDE.md corrigé (`NetworkView` possède son path). | |

### Après la passe Figma (2026-10-13)

| # | Sujet | Décision | Pourquoi |
|---|-------|----------|----------|
| Q15 bis | Libellé du menu « + » | « Ajouter des amis lecteurs » (`network.add_friends`, chaîne existante) et « Créer un groupe » (`groups.create`). | Pas de nouvelle clé. |
| Q29 bis | « et 1 autre » | Jusqu'à 4 amis en commun, on les nomme tous ; au-delà, 3 pseudonymes puis « et N autres » (N ≥ 2). | « et 1 autre » coûte autant qu'un nom. |
| Q27 bis | Groupes en commun | Seuls les groupes admin/membre comptent (« 1 groupe en commun : Club de Belleville »). Un groupe où je suis seulement invité reste allumé dans le graphe, mais n'est pas compté. | Cohérent avec le compteur (Q10). |
| Q32 bis | Arête vous ↔ ami | `foregroundTinted` 1 pt à 30 % dans les deux apparences et aux deux niveaux de zoom ; plus de `borderDefault` pour les arêtes. | `borderDefault` fait 1,2:1 sur noir : le lien d'un ami isolé disparaissait en sombre. |
| Q15 ter | Menu « + » | Menu natif (`Menu { }` dans la toolbar) : panneau ancré sous le « + », sans voile ni flou sur l'écran. | iOS 26 ne voile pas l'écran pour un menu de barre. |
| Q21 bis | Taille du repli | `Avatar · Repli` existe en 44 pt (initiales `action300`) et 32 pt (initiales `action200`). | À 32 pt, `action300` remplit le disque. |
| Q5b bis | Pastille demandeur | `Graph / Friend · Dot` gagne un état `Requested` (contour pointillé `[4,4]`), au lieu d'un override d'instance. | La vue d'ensemble montre aussi les demandeurs. |

Chaînes sans clé à créer : « Synchronisation… », « Ouvrir le groupe », « Voir le profil », « dont N de vos amis »,
« et N autres », « N groupes en commun », la phrase de l'état vide (E1). La chaîne
`network.invitation.explanation` dit « ne le prévient pas » au masculin : existante, gardée.

Défauts du fichier Figma relevés, sans conséquence sur le code : glyphes absents d'`Icon` (minus, scope,
person.badge.plus, arrow.clockwise, checkmark, xmark — substituts en place) ; `Chrome / Tab Bar · Réseau` sans
variante sombre (override dans les écrans sombres) ; rayon de feuille 32 et padding de pilule 8/12 sans token.

## Hors périmètre

L'avatar caché de l'en-tête de profil (`UserHeaderView.swift:25-27`) ; Android (Q1) ; minicarte (Q3) ; demandes
d'adhésion envoyées dans le graphe (Q4).

## Conséquences notées sans question

- Après Refuser, le nœud disparaît (transition de Q17) et la feuille se ferme ; après Accepter, le pointillé devient
  plein et la feuille reste ouverte sur le nouvel état.
- « Ouvrir le groupe » / « Voir le profil » ferment la feuille puis poussent `.group(id:)` / `.user(user:)` sur le
  path de `NetworkView`.
- L'URL d'avatar utilisateur passe par `APIService.absoluteImageUrl` (aujourd'hui concaténation `baseUrl + picture`,
  `User.swift:136`), puisque les listes adoptent le composant partagé.
- La déconnexion (0025) et la suppression de compte (0017) vident aussi les groupes ; la liste Groupes passe en
  `@Query` (ADR 0001) ; `hasLoaded` / `syncFailed` de 0028 sont à revoir face au store.

## À dessiner dans Figma (passe Q2b)

- Graph / Friend : état `Requested` (contour d'avatar pointillé) + arête vous ↔ demandeur pointillée (Q5b).
- Carte demandeur : Accepter / Refuser (Q5).
- Carte ami (« Voir le profil »).
- R3 : amis sans groupe commun reliés à Vous par leur arête, gardée au dézoom (Q6).
- Retirer la minicarte de R4 / marquer R4 hors périmètre (Q3).
- Graph / Me sans photo (initiales) ; repli initiales / `person.2` dans les rangées R5/R6 (Q21).
- `PendingDot` après le nom dans Graph / Group (Q22).
- Menu du « + » sur Tout (Q15).
- Chrome / Segmented Control · 3 annoté « stand-in du Picker natif » (Q13).
- R2 redessiné en `.sheet` native couvrant la tab bar, poignée centrée système (Q24).
- Graph / Group : un seul état sélectionné pour Member et Invited (Q25), au lieu de Member/Invited · Highlighted.
- Feuilles : invitation de groupe (Accepter / Refuser / Ouvrir), demandeur (Accepter / Refuser / Voir le profil),
  ami (groupes en commun, Voir le profil) (Q26, Q27) ; variantes 0 / 1 / « et N autres » de la feuille groupe (Q29).
- Graph / Friend · Dot sans initiales (photo ou disque `backgroundTinted`) (Q37).
- Graph / Zoom Controls et compteur annotés « stand-in Liquid Glass » ; contrôles et compteur ajoutés à R1 (Q34, Q35).
- Pointillés unifiés `[4,4]` (Q32).
- État vide de Tout (Q39) ; pilule « Synchronisation… » / « Réessayer » à la place du compteur (Q40, Q41).
- R1 et R3 en mode de variables Dark (Q42).

## Déjà tranché par le code ou la maquette

Voir la sortie de synthèse : 30 points (couleur des arêtes vous ↔ groupe, « Vous » ×0,7, atténuation 30 % / 12 %,
groupes d'un ami hors des miens impossibles côté API, un nœud par ami, source `GroupModel.myGroups`, arêtes =
`memberIds` ∩ amis, « + » inchangé sur Amis/Groupes, `NetworkSegment` + cas `all`, fonds par segment, comptes de
livres R5/R6 non construits, écarts R5/R6 consignés et non corrigés, métriques hors tokens dans une struct de
feature, graine `DeterministicTilt`, placement en fonction pure `nonisolated`, pas de lib de graphe, nœuds à taille
constante sous le zoom, navigation via le path de `NetworkView`, iPhone seul, sombre suit le système, libellés des
boutons de zoom, artefacts R4 non reproduits, cadres 960 pt non littéraux, chaînes/pluriels existants, demandes
envoyées = registre local, docs sous `docs/`, e2e seulement sur demande).
