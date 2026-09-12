Title: Les demandes en cours, dans l'écran où l'on en envoie
Labels: needs-triage, enhancement
Type: AFK

## Parent

`docs/features/0018-reader-network.md` — la moitié « Demander ».
Maquette : `node-id=417-11379` du fichier `Nouveau récits`
(`S7IvC6GvlcUFe5IgbtvQq6`), frame `N2` revisitée.

## What to build

« Ajouter des amis lecteurs » s'ouvre aujourd'hui sur une explication et rien d'autre, y compris
quand trois demandes attendent déjà une réponse. Pour savoir ce qu'on a lancé il faut ressortir,
descendre le Profil et ouvrir « Toutes les invitations » — pour une information qui a sa place
exactement là où on l'a produite.

Au repos, l'écran liste donc les demandes que j'ai envoyées et qui attendent, sous un en-tête
« Demandes en cours », avec la cellule de lecteur habituelle et son étiquette « Envoyée ».

Les bornes, tranchées avant d'écrire :

- **Envoyées seulement** (`relation == .requestSent`). Les invitations reçues restent sur l'écran
  « Toutes les invitations », qui les porte déjà avec les deux boutons qu'elles demandent ; les
  reprendre ici dupliquerait cet écran en entier et mettrait un « Accepter » dans un écran de
  recherche.
- **Au repos seulement.** Dès qu'un caractère est tapé, la section disparaît et les résultats
  prennent l'écran. Sans quoi un lecteur déjà sollicité qui ressort dans les résultats
  s'afficherait deux fois, avec la même étiquette, sur le même écran — deux cellules qu'on ne
  saurait pas distinguer.
- **L'explication cède la place.** Quand il y a des demandes en cours, l'état vide « Trouvez vos
  amis lecteurs » ne s'affiche pas : on ne relit pas le mode d'emploi d'une chose qu'on a déjà
  réussie. Sans demande en cours, il reste ce qu'il est.

Rien à appeler : `GET /api/relations` a déjà écrit les états dans le magasin. La section est un
`@Query` sur `User` filtré en Swift — `relation` est calculé et n'entre pas dans un `#Predicate`,
comme `InvitationsView` le fait déjà — trié par nom d'utilisateur, faute de date de demande côté
serveur.

L'étiquette suit la maquette : `network.request.sent` passe de « Demande envoyée » à
« Envoyée ». Sous un en-tête qui dit déjà « Demandes en cours » ou « Envoyées », le mot
« Demande » est redondant. Le bouton inerte de `RelationActionsView` porte la même clé et ne peut
pas se contenter d'un participe seul : il prend sa propre chaîne.

## Acceptance criteria

- [ ] Au repos, avec au moins une demande envoyée : l'en-tête « Demandes en cours » et une cellule
      par demande, avec l'étiquette « Envoyée »
- [ ] Au repos, sans demande en cours : l'écran est celui d'aujourd'hui, explication comprise
- [ ] Dès le premier caractère tapé, la section n'est plus là
- [ ] Toucher le nom d'une demande ouvre le profil du lecteur
- [ ] Annuler la demande depuis ce profil la retire de la section au retour, sans rechargement
- [ ] Le bouton inerte de `RelationActionsView` ne dit pas « Envoyée » tout seul

## Blocked by

—
