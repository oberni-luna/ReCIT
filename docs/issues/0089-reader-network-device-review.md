Title: Revue sur appareil du parcours réseau, et son étape end-to-end
Labels: needs-triage, chore
Type: HITL

## Parent

`docs/features/0018-reader-network.md`

## What to build

Les six écrans du réseau ont été écrits, testés unitairement et vérifiés à la compilation, mais
jamais regardés ailleurs que dans la maquette : ni en sombre, ni en VoiceOver, ni au plus grand
corps de texte, ni en anglais, ni sur un vrai compte.

La fiche de passage, sur appareil, avec deux comptes de test qui peuvent se demander l'un l'autre :

- La recherche : au repos, pendant la frappe, sans résultat, avec un résultat de chaque état.
- La demande : la feuille, l'envoi, le retour au profil, l'annulation.
- La réception : l'invitation dans le Profil, l'écran dédié, accepter (les livres arrivent-ils ?),
  refuser.
- Le retrait : la confirmation, et ce que devient l'inventaire du lecteur retiré dans la recherche
  de l'inventaire.
- Hors ligne : chacune des cinq écritures avec le Wi-Fi coupé — l'état revient-il en arrière, la
  SnackBar dit-elle pourquoi ?

Puis le scénario end-to-end : `UITests/E2EScenarioTests.swift` ne joue pas ce parcours. Les
identifiants `e2e.*` sont déjà posés (`e2e.profile.addFriends`, `e2e.profile.invitations`,
`e2e.reader.add`, `e2e.user.addToNetwork`, `e2e.user.cancelRequest`, `e2e.invitation.accept`,
`e2e.invitation.refuse`, `e2e.user.removeFromNetwork`). Une étape qui cherche le second compte,
lui demande, annule, et repart sans rien laisser derrière est la forme minimale — elle doit
nettoyer derrière elle comme le reste du scénario.

## Acceptance criteria

- [ ] Les six écrans sont vus en clair et en sombre, en français et en anglais
- [ ] VoiceOver lit chaque rangée à état, et les deux boutons d'une invitation sont atteignables
- [ ] Au plus grand corps de texte, aucune pilule ne tronque son libellé ni ne déborde
- [ ] Les cinq écritures sont jouées hors ligne : retour arrière visible, SnackBar explicite
- [ ] `scripts/e2e.sh` joue le parcours et ne laisse ni demande ni relation derrière lui
- [ ] `docs/features/0018-reader-network.md` perd sa ligne « Une passe sur appareil » une fois faite

## Blocked by

—
