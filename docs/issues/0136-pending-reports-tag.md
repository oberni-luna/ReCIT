## Parent

`docs/prd/0028-edition-duplicates.md`

## What to build

L'écran lit les signalements en attente (`GET /api/tasks/by-uris`, public, par lots, sur les
`invUri`) et les enregistre sur les éditions. Une paire signalée — par moi ou par un autre —
porte « Doublon signalé » sur ses deux lignes et n'est plus proposée. Une réponse réussie fait foi
pour les uris demandées ; un échec laisse l'état connu.

## Acceptance criteria

- [ ] Réponse `{ tasks: { uri: [Task] } }` décodée et appliquée (test sur MockURLProtocol)
- [ ] Étiquette « Doublon signalé » en `secondary` avec une horloge
- [ ] Une tâche close efface l'étiquette à la visite suivante

## Blocked by

- `docs/issues/0135-detect-duplicates-tags-and-banner.md`
