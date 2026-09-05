# Le mur se souvient

## Parent

`docs/prd/0011-welcome-cover-wall.md`

## What to build

Deuxième lancement dans un train sans réseau : le mur revient à l'identique, immédiatement. Les
chemins de couverture du dernier appel réussi sont persistés (quelques ko dans `UserDefaults`) et
affichés **avant** toute requête ; les données d'image, elles, sont déjà en cache disque via le
chargeur d'images.

Les couvertures peintes ne servent alors plus qu'au tout premier lancement, et de repli définitif
si l'API reste injoignable.

Un échec réseau ne vide jamais la liste persistée : le mur d'hier vaut mieux qu'un mur peint.

## Acceptance criteria

- [ ] Les chemins du dernier appel réussi sont persistés, et relus au lancement suivant avant tout
      réseau — le mur réel est visible à la première frame, sans transition depuis le mur peint.
- [ ] Hors ligne, le mur affiché est celui de la dernière session, avec les images servies par le
      cache disque.
- [ ] Un appel qui échoue (transport, 4xx, 5xx, payload illisible) laisse la liste persistée et le
      mur affiché intacts.
- [ ] Un appel qui réussit remplace la liste persistée, et les couvertures apparaissent en fondu
      comme dans l'issue 0070.
- [ ] La persistance est bornée : au plus le nombre de couvertures demandé, pas de croissance
      indéfinie.
- [ ] Tests : écriture puis relecture du cache, priorité du cache sur le mur peint au démarrage,
      et non-régression du cache sur échec réseau (via `MockURLProtocol`).
- [ ] Le projet compile et la cible de test passe sur `iPhone 17`.

## Blocked by

- `docs/issues/0070-real-covers-from-recent-public.md`
