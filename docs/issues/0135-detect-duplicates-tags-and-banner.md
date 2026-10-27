## Parent

`docs/prd/0028-edition-duplicates.md`

## What to build

L'écran « Éditions » compare lui-même les éditions de l'œuvre (`IsbnNormalization`,
`EditionDuplicateDetector`, `MergeChoice` pour le regroupement), marque les lignes « Même ISBN »
ou « Doublon probable », et pose en tête de liste un bandeau « N doublons probables » avec une
phrase par raison, le lien « Les comparer » (inactif jusqu'à 0137) et une croix qui le ferme
jusqu'à ce que les paires changent.

## Acceptance criteria

- [ ] Règles 1 à 5 et 7 du PRD, testées une à une
- [ ] ISBN-10 et ISBN-13 du même livre reconnus
- [ ] Bandeau absent sans doublon ; revient si les paires changent après fermeture
- [ ] Textes FR/EN

## Blocked by

- `docs/issues/0134-edition-rows-show-isbn-publisher-year.md`
