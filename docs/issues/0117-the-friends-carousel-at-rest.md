Title: « Chez mes amis » au repos — invitation, « Tout voir », absence
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0020-search-tab.md`

## What to build

Finir le carrousel que le spike 0115 a posé, dans l'onglet Recherche.

- `FriendsCarouselState`, pur : invitation (aucun ami), masqué (amis sans livre, ou toute phase
  autre que le repos), les dix plus récents et leur total. « Avoir un ami » se lit dans les
  utilisateurs du store à relation acceptée.
- Sans ami : une étiquette papier à la place du carrousel, qui sélectionne Réseau via `TabRouter`.
- « Tout voir » sur l'en-tête du carrousel quand mes amis ont plus de dix livres : une destination
  qui liste tous leurs livres, les plus récents d'abord.
- Au repos sans aucune recherche récente, le carrousel (ou l'invitation) ne disparaît plus
  derrière l'état vide : l'état vide de 0073 ne s'affiche que s'il n'y a rien du tout à montrer.
- Pendant la sync des amis, le carrousel apparaît au premier livre reçu et se remplit.

## Acceptance criteria

- [ ] Sans ami, l'étiquette mène à l'onglet Réseau ; avec des amis sans livre, rien.
- [x] Sans recherche récente, le carrousel s'affiche seul ; l'état vide ne vient que sans carrousel ni invitation.
- [x] « Tout voir » apparaît au-delà de dix livres et liste tous ceux de mes amis.
- [ ] VoiceOver annonce titre et propriétaire de chaque couverture.
- [x] Tests `FriendsCarouselState` (invitation, masqué hors repos, masqué sans livre, dix plus récents et total).

## Notes d'implémentation (2026-10-21)

- Vu sur simulateur iPhone 17 avec un compte qui a un ami et plus de dix livres chez lui :
  « Tout voir » et sa liste, l'effacement des récentes qui laisse le carrousel seul.
- **Pas vu** : l'invitation (le compte a un ami) — couverte par `FriendsCarouselStateTests` et
  `TabRouterTests` ; l'arrivée pendant la sync des amis ; VoiceOver (le libellé est posé, pas
  écouté).

## Blocked by

- `docs/issues/0115-friends-carousel-animation-spike.md`
- `docs/issues/0116-the-search-tab.md`
