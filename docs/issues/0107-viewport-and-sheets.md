Title: Pincer, glisser, toucher : la feuille d'un groupe et celle d'un ami
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Le graphe se pince autour des doigts et se glisse, dans ses bornes. Toucher un nœud allume ses liens, atténue
le reste et ouvre une feuille native qui le résume et mène à sa fiche.

- `GraphViewport`, pur : monde → écran, cadrage d'ouverture, échelle min = tout le réseau, max ≈ ×2
  (Q33), pincement ancré aux doigts, glissement borné, toucher = centre le plus proche dans 44 pt (Q36),
  panoramique minimal qui sort le nœud touché de sous la feuille (Q30). Testé comme `CoverZoomTests`.
- Sélection : nœuds non liés à 30 %, arêtes non allumées à 12 %, arêtes allumées 2,5 pt ; un seul aspect
  sélectionné pour un groupe, quel que soit le rôle (Q25) ; pour un ami : ses arêtes vers ses groupes et
  vers Vous, et ces groupes (Q27). Toucher « Vous » ne fait rien (Q28).
- Feuille : `.sheet` native, un detent `.height` mesuré, `presentationBackgroundInteraction` (Q24,
  Q24b) ; toucher un autre nœud remplace le contenu ; toucher le vide ou glisser vers le bas ferme et
  efface la sélection.
- Contenu groupe : nom, « Admin · 12 membres, dont 4 de vos amis : Inès, Léa, Rémi et Camille. » selon
  la règle des noms (jusqu'à 4 ; au-delà 3 + « et N autres » ; 0 ami → s'arrête au nombre de membres ;
  au plus 5 avatars qui se chevauchent) (Q29, Q29 bis), « Ouvrir le groupe ».
- Contenu ami : avatar, pseudonyme, « Membre depuis … », « N groupes en commun : … » (admin / membre
  seulement, Q27 bis), « Voir le profil ».
- « Ouvrir le groupe » / « Voir le profil » ferment la feuille puis poussent `.group(id:)` /
  `.user(user:)` sur le path de `NetworkView`.

## Acceptance criteria

- [ ] Tests `GraphViewport` : cadrage d'ouverture, bornes, point sous les doigts fixe pendant le pincement, toucher au plus proche dans 44 pt, panoramique minimal.
- [ ] Tests de la règle des noms et des phrases : 0, 1, 4, 5, 6 amis ; groupes communs sans les invitations.
- [ ] Toucher un groupe ouvre sa feuille et allume ses liens ; toucher un ami de même ; toucher un autre nœud change la feuille ; toucher le vide la ferme.
- [ ] « Ouvrir le groupe » mène à `GroupDetailView`, « Voir le profil » à `UserDetailView` ; le retour ramène au graphe.
- [ ] Le graphe reste pinçable et glissable feuille ouverte.
- [ ] Clés neuves avec substitutions plurielles en français et en anglais ; la build compile ; la suite est verte.

## Blocked by

- `docs/issues/0106-constellation.md`
