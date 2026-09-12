Title: « Membre depuis », à la place d'un nombre d'éléments qu'on n'a presque jamais
Labels: needs-triage, enhancement
Type: AFK

## Parent

`docs/features/0018-reader-network.md` — la cellule de lecteur, `UserCellView`.

## What happened

Sous le nom d'un lecteur, la cellule affiche « %lld éléments », lu dans
`snapshot["…"]["items:count"]`. Pour un inconnu, ce nombre est presque toujours `0` : le snapshot
que `/api/users/by-ids` renvoie est celui de ce que *je* suis autorisé à voir, et je ne vois rien
de l'inventaire de quelqu'un qui n'est pas de mon réseau. La cellule annonce donc « 0 éléments »
à propos de lecteurs qui en ont trois cents — dans la recherche, dans les invitations reçues, et
dans la nouvelle section « Demandes en cours ». Ce n'est pas une donnée manquante, c'est une
donnée fausse.

## What to build

La deuxième ligne dit depuis quand le compte existe : « Membre depuis mars 2024 ».

`created` est là. Vérifié le 2026-09-12 sur la production :

```
$ curl -s "https://inventaire.io/api/users/by-ids?ids=7551c133d718b110e7ceb94b2cdae2c8"
{"users":{"7551…":{"_id":"7551…","username":"Olivier","created":1503076480453,
  "picture":"/img/users/…","position":[…],"snapshot":{"public":{…}}}}}
```

Un timestamp en millisecondes, servi sans authentification, sur le même appel que la cellule fait
déjà. Rien de nouveau à demander au serveur.

- `UserDTO.created: Double?`, `User.created: Double?`. **Optionnel, obligatoirement** : SwiftData
  n'écrit pas la valeur par défaut d'une propriété Swift dans les lignes déjà en base lors d'une
  migration légère — elles reçoivent NULL, et un type non-optionnel s'y casse. C'est exactement ce
  qui a fait planter chaque installation antérieure à l'issue 0083 (voir le commentaire de
  `User.relationRawValue`).
- `User.update(with:)` le fusionne **gardé sur `nil`**, comme `email` et `picture` : une charge
  utile creuse ne doit pas effacer une bonne donnée locale (ADR 0001).
- Format mois + année, par `Text(date, format: .dateTime.month(.wide).year())` — pas de chaîne de
  format à la C, et la localisation suit l'appareil.
- `created` absent : la ligne n'est pas dessinée. Le cas est quasi théorique, toute recherche
  repassant par `by-ids`, et une cellule à une ligne pendant un instant vaut mieux qu'un chiffre
  inventé ou qu'un « Membre d'inventaire.io » qui n'apprend rien.

**Périmètre : `UserCellView` seulement.** L'en-tête de profil (`UserHeaderView`) garde son
compte, qui lui est vrai : le mien est compté dans le magasin local par `OwnedItemCountText`,
celui d'un ami vient d'un snapshot que la relation me donne le droit de voir.

## Acceptance criteria

- [ ] Une cellule de lecteur affiche « Membre depuis <mois> <année> » sous le nom
- [ ] `user.item_count` n'est plus lu par `UserCellView`
- [ ] `UserHeaderView` est inchangé : mon compte et celui d'un ami affichent toujours leurs livres
- [ ] Une installation existante se lance sans planter après la migration
- [ ] Un `UserDTO` sans `created` décode, et sa cellule n'affiche qu'une ligne

## Blocked by

—
