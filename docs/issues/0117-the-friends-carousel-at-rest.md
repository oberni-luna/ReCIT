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
- Au repos sans aucune recherche récente, l'état vide de 0073 et le carrousel coexistent : le
  carrousel ne disparaît plus derrière l'état vide.
- Pendant la sync des amis, le carrousel apparaît au premier livre reçu et se remplit.

## Acceptance criteria

- [ ] Sans ami, l'étiquette mène à l'onglet Réseau ; avec des amis sans livre, rien.
- [ ] Sans recherche récente, l'état vide et le carrousel s'affichent ensemble.
- [ ] « Tout voir » apparaît au-delà de dix livres et liste tous ceux de mes amis.
- [ ] VoiceOver annonce titre et propriétaire de chaque couverture.
- [ ] Tests `FriendsCarouselState` (invitation, masqué hors repos, masqué sans livre, dix plus récents et total).

## Blocked by

- `docs/issues/0115-friends-carousel-animation-spike.md`
- `docs/issues/0116-the-search-tab.md`
