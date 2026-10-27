## Parent

`docs/prd/0028-edition-duplicates.md`

## What to build

L'écran « Éditions » d'une œuvre montre, pour chaque édition, ce qui la distingue : le titre, puis
« éditeur · collection · année », puis « ISBN … » ou « Sans ISBN ». C'est le nouveau composant
`EditionCell` (`Cell / Edition`, Leading None), qui remplace `SearchResultCell` dans
`WorkEditionPicker`.

`Edition` gagne `isbn`, `publisherUri`, `publisherName`, `collectionUri`, `collectionName`,
`publicationDate`, `invUri`, `differentFromUris`, remplis par `update(entityDto:)` sans jamais
effacer avec nil ; `EntityResultDTO` gagne `invId`. Les éditions en cache sont revalidées à
l'ouverture de l'écran, et les libellés d'éditeur et de collection lus en un appel groupé. La liste
lit `work.editions`.

## Acceptance criteria

- [ ] Chaque ligne montre l'ISBN-13, sinon l'ISBN-10, sinon « Sans ISBN »
- [ ] Éditeur, collection et année sous le titre quand ils sont connus
- [ ] Une réponse sans ces claims n'efface pas les valeurs connues (test)
- [ ] Les éditions déjà en cache gagnent leurs données à la visite suivante
- [ ] Textes FR/EN, iOS 18

## Blocked by

None - can start immediately
