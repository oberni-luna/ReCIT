## Parent

`docs/prd/0028-edition-duplicates.md`

## What to build

« Ce ne sont pas les mêmes » écrit `wdt:P1889` sur l'édition `inv:` de la paire, de façon
optimiste (`optimistic` : `apply` ajoute l'uri à `differentFromUris`, `revert` la retire). La paire
quitte la revue et les étiquettes aussitôt ; un refus la ramène, avec un SnackBar.

## Acceptance criteria

- [ ] Corps `update-claim` vérifié sur MockURLProtocol
- [ ] Apply puis revert sur échec (test)
- [ ] Une `Note` dit que le refus est public

## Blocked by

- `docs/issues/0137-review-one-duplicate-at-a-time.md`
