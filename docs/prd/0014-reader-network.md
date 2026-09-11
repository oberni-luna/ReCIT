# PRD 0014 — Se faire un réseau de lecteurs

La section `Réseau` du Profil liste des amis sans jamais permettre d'en ajouter un, et rien dans
l'app ne dit qu'une invitation est arrivée. Tout le reste de l'app en dépend pourtant : la
recherche unifiée montre « mes livres et ceux de mes amis », une transaction se demande à un ami,
un livre se voit chez quelqu'un. Le réseau se constitue aujourd'hui sur le site web, et l'app
n'en est que le spectateur.

Cette feature ajoute les deux sens du geste : demander, et répondre.

## Ce que le serveur sait faire

Vérifié le 2026-09-12 contre `https://inventaire.io/public/api_specs.json`.

| Besoin | Endpoint | Paramètres |
|---|---|---|
| Les quatre états, en un appel | `GET /api/relations` | — ; renvoie `friends`, `userRequested`, `otherRequested`, `network` |
| Demander | `POST /api/relations/request` | `user` — **et rien d'autre** |
| Accepter · Refuser | `POST /api/relations/accept` · `/discard` | `user` |
| Annuler · Retirer | `POST /api/relations/cancel` · `/unfriend` | `user` |
| Chercher un lecteur | `GET /api/search?types=users&search=…&limit=…` | public ; renvoie `id`, `label`, `image`, `_score`, **pas d'`uri`** |

Deux conséquences de fond :

- **Une demande ne porte pas de message.** `request` ne prend qu'un identifiant. La feuille de
  demande avec champ de texte (frame `N5b`) est écartée : elle promettrait une fonction que le
  serveur refuse. `N5a` — la confirmation seule — est la maquette retenue.
- **Le serveur ne prévient personne.** Il n'y a pas de notification : une invitation ne se
  découvre qu'en ouvrant l'app. C'est pourquoi les invitations reçues remontent dans le Profil,
  et pas seulement dans un écran qu'il faudrait penser à ouvrir.

## La maquette

Section Figma `Réseau · Ajouter des amis lecteurs` (`407:10422`), page `Screens` —
[figma-library.md](../design-system/figma-library.md) porte la passe du 2026-09-12 et la table des
onze frames. Les deux arbitrages tranchés par la maquette après coup, et qui font foi ici :

- **Les invitations vivent dans le Profil *et* dans un écran dédié.** `N7` porte la section
  `Invitations` sous l'en-tête, terminée par « Toutes les invitations » qui pousse `N8`, lequel
  montre aussi les demandes envoyées.
- **« Annuler la demande » est un bouton destructif plein**, pas un lien discret (`N6`).

## Les quatre états

| État serveur | Dans une liste | Sur le profil du lecteur | Geste |
|---|---|---|---|
| Inconnu | rangée + « Ajouter » | « Ajouter au réseau » (primaire) | `request` |
| `userRequested` | rangée + « Envoyée » | bouton inerte + « Annuler la demande » | `cancel` |
| `otherRequested` | rangée + Accepter / Refuser | « Accepter la demande » + « Refuser » | `accept` / `discard` |
| `friends` | rangée nue | l'inventaire s'ouvre, « Retirer du réseau » dans le « … » | `unfriend` |

## Hors périmètre

- **Le badge d'onglet.** Sans notification serveur, un compteur sur `Réglages` serait le minimum,
  mais il n'est pas maquetté et touche à la barre d'onglets de toute l'app.
- **Les lecteurs à proximité** (`/api/users/nearby`) : demande une position, donc une permission
  et un écran de plus.
- **Le message de demande** : voir plus haut, le serveur n'en veut pas.

## Issues

- `docs/issues/0083-relations-four-states.md`
- `docs/issues/0084-search-readers.md`
- `docs/issues/0085-request-and-cancel.md`
- `docs/issues/0086-answer-an-invitation.md`
- `docs/issues/0087-all-invitations-screen.md`
- `docs/issues/0088-remove-from-network.md`
