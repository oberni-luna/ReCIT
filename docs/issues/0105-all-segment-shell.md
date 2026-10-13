Title: Le segment « Tout » : bandeau fixe, segment retenu, menu « + », état vide
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

L'onglet Réseau gagne un segment « Tout », en premier, compilé **en `DEBUG` seulement** (Q47). Il montre
« Vous » au centre ; tant que le graphe n'existe pas, et quand je n'ai ni ami ni demande ni groupe, il montre
l'état vide de E1 (Q39).

- `NetworkSegment.all` sous `#if DEBUG`, déclaré en premier ; le segment choisi est retenu
  (`@AppStorage`), « Tout » au premier lancement ; une valeur retenue absente de la build retombe sur Amis
  (Q12).
- Le `Picker` natif sort de la `List` vers un bandeau fixe sous le titre (`safeAreaInset(edge: .top)`)
  pour les trois segments (Q13, Q14). Amis et Groupes gardent `applyListBackground()` ; Tout est sur
  `backgroundDefault`, barre de navigation comprise.
- Le « + » de Tout est un `Menu` natif : « Ajouter des amis lecteurs » (pousse `.addFriends`) et « Créer
  un groupe » (présente `CreateGroupView`) (Q15, Q15 bis, Q15 ter). Amis et Groupes inchangés.
- « Vous » : 72 pt, photo ou initiales (0104), anneau `backgroundTintedInverse`, pastille « Vous ».
- État vide (E1) : « Vous », la phrase « Vos amis lecteurs et vos groupes se placeront ici, autour de
  vous. », et les liens « Ajouter des amis lecteurs » / « Trouver un groupe ».

## Acceptance criteria

- [ ] En DEBUG, « Tout » est le premier segment ; en Release il n'existe pas (vérifié par compilation des deux configurations).
- [ ] Le segment choisi survit à un relancement ; une valeur `.all` retenue en Release retombe sur Amis.
- [ ] Le contrôle ne bouge pas quand je change de segment ; Amis et Groupes défilent comme avant.
- [ ] Sur Tout, le « + » ouvre un menu à deux entrées qui mènent aux bons écrans.
- [ ] Sans ami, demande ni groupe, Tout montre l'état vide avec ses deux liens.
- [ ] `e2e.network.segment`, `e2e.network.add`, `e2e.network.createGroup` et les autres identifiants existants survivent.
- [ ] Nouvelles clés dans `Localizable.xcstrings` (« Tout », « Vous », phrase vide), en français et en anglais ; la build compile ; la suite est verte.

## Blocked by

- `docs/issues/0104-shared-avatar-fallback.md`
