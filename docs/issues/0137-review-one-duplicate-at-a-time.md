## Parent

`docs/prd/0028-edition-duplicates.md`

## What to build

« Les comparer » pousse `NavigationDestination.editionDuplicates(workUri:)` → la revue
« Doublon k sur N » (C2) : les deux éditions en `EditionCell` Leading Off/On avec leur nombre
d'exemplaires, celle à garder cochée par `MergeChoice` (une édition Wikidata toujours gardée, avec
une `Note`), « Ce qui diffère » (`EditionComparison`) et la `Note` « Pareil : … », « Suivant »
dans la barre. Les deux boutons du bas sont posés, sans effet jusqu'à 0138 et 0139.

## Acceptance criteria

- [ ] Paires recalculées à l'arrivée ; « Suivant » passe à la suivante, la dernière revient à la liste
- [ ] La coche bascule entre deux éditions `inv:` ; une `wd:` ne peut pas être décochée
- [ ] `MergeChoice` et `EditionComparison` testés
- [ ] VoiceOver : la coche se lit « sélectionnée »

## Blocked by

- `docs/issues/0135-detect-duplicates-tags-and-banner.md`
