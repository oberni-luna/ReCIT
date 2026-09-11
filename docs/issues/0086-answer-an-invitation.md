Title: Répondre à une invitation, depuis le Profil ou depuis le profil du lecteur
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-reader-network.md` — frames `N7` (`410:11046`) et `N9` (`410:10971`)

## What to build

L'autre sens. Le serveur ne prévient personne : une invitation ne se découvre qu'en ouvrant
l'app, donc elle remonte là où on arrive.

- **Dans le Profil**, une section `Invitations` **sous l'en-tête** — avant les transactions —
  visible seulement s'il y en a. Une rangée par demandeur : son nom, son nombre de livres, puis
  « Accepter » et « Refuser » côte à côte. Accepter est le bouton plein, Refuser le teinté :
  jamais du rouge, refuser une invitation ne détruit rien et l'expéditeur n'est pas une menace.
- **Sur le profil du lecteur**, les mêmes deux gestes en pleine largeur (`N9`), et l'état vide qui
  dit que l'inventaire s'ouvrira une fois la demande acceptée.
- `UserModel.acceptRelation(with:)` / `discardRelation(with:)`, optimistes comme 0085. Accepter
  fait passer à `.friend` ; l'inventaire du nouvel ami est synchronisé dans la foulée, sinon la
  section reste vide jusqu'au prochain lancement.

## Acceptance criteria

- [ ] La section n'existe que s'il y a au moins une invitation
- [ ] « Accepter » poste `/api/relations/accept`, « Refuser » `/api/relations/discard`
- [ ] Accepter fait basculer la rangée du bloc Invitations vers le bloc Réseau, sans relance
- [ ] Accepter déclenche la synchronisation de l'inventaire du nouvel ami
- [ ] Un échec revient en arrière et se voit, des deux côtés
- [ ] `xcodebuild … -scheme ReCIT_iOSTests test` passe

## Blocked by

- `docs/issues/0083-relations-four-states.md`
