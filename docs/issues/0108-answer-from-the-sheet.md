Title: Répondre depuis la feuille : invitation de groupe et demande d'ami
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0019-network-graph.md`

## What to build

Toucher un groupe qui m'invite, ou un lecteur qui m'a demandé en ami, ouvre une feuille qui me laisse
répondre sans quitter le graphe (Q5, Q26).

- Invitation de groupe : nom, « Invitation de Camille · 31 membres, dont 2 de vos amis : Camille et
  Nora. », avatars, Accepter / Refuser, « Ouvrir le groupe ».
- Demande d'ami : avatar, pseudonyme, « Membre depuis … », le texte existant
  `network.invitation.explanation`, Accepter / Refuser, « Voir le profil ».
- Accepter / Refuser appellent les gestes optimistes existants de `GroupModel` et `UserModel` (ADR 0001) :
  réaction immédiate, échec signalé par `AppErrorReporter` et défait.
- Après Accepter, le pointillé devient plein (transition) et la feuille reste ouverte sur le nouvel état ;
  après Refuser, le nœud disparaît et la feuille se ferme.

## Acceptance criteria

- [ ] Accepter une invitation de groupe depuis la feuille : la carte et l'arête passent en plein, la feuille montre le groupe comme membre.
- [ ] Refuser : le nœud disparaît, la feuille se ferme ; le badge de l'onglet baisse.
- [ ] Même chose pour une demande d'ami.
- [ ] Un échec serveur (mock) défait le geste et passe par `AppErrorReporter` (test au niveau des modèles s'il manque).
- [ ] Les boutons portent des identifiants `e2e.network.graph.*` ; la build compile ; la suite est verte.

## Blocked by

- `docs/issues/0107-viewport-and-sheets.md`
