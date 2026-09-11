Title: « Toutes les invitations » — un écran qui porte les deux sens
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-reader-network.md` — frame `N8` (`410:11240`), et le lien ajouté à `N7`

## What to build

La section `Invitations` du Profil se termine par « Toutes les invitations », qui pousse l'écran
dédié : `Reçues` en haut, avec les mêmes deux gestes qu'au Profil, `Envoyées` en dessous, chacune
marquée « Envoyée ». C'est ce que `GET /api/relations` renvoie déjà en un appel — les deux sens,
sans second aller-retour.

Une demande envoyée s'annule depuis le profil du lecteur (issue 0085) : la rangée d'ici pousse ce
profil, elle ne porte pas le geste.

## Acceptance criteria

- [ ] `NavigationDestination.invitations` pousse l'écran depuis le Profil
- [ ] Les deux sections sont alimentées par `relation`, pas par un second appel
- [ ] Une section vide ne s'affiche pas ; l'écran entièrement vide dit pourquoi
- [ ] Accepter ou refuser ici met à jour le Profil derrière, sans relance
- [ ] `xcodebuild … -scheme ReCIT_iOSTests test` passe

## Blocked by

- `docs/issues/0086-answer-an-invitation.md`
