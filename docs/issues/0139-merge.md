## Parent

`docs/prd/0028-edition-duplicates.md`

## What to build

« Fusionner » envoie `PUT /api/entities/merge { from, to }` et attend. `.merged` : exemplaires
locaux rattachés à l'édition gardée, `preferredEditionUri` suivi, édition `from` supprimée, œuvre
et éditions resynchronisées. `.reported` : signalement noté sur `from`. Un `400` est classé par
`MergeFailure` et dit en une phrase ; le store n'est pas touché. De retour à la liste, un SnackBar
résume (`DuplicatesReviewSummary`).

## Acceptance criteria

- [ ] Requête, `.merged`, `.reported`, quatre `400` et `401` testés sur MockURLProtocol
- [ ] Aucune fusion réelle pendant le dev
- [ ] Boutons désactivés pendant l'envoi
- [ ] SnackBar pluralisé FR/EN

## Blocked by

- `docs/issues/0136-pending-reports-tag.md`
- `docs/issues/0137-review-one-duplicate-at-a-time.md`
