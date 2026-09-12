Title: Le lecteur qui résout une œuvre en une édition, sans rien écrire
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-search-results-are-editions.md` — [ADR 0002, Move 3](../adr/0002-unified-book-detail.md)

## What to build

Ce qui va chercher les éditions d'une œuvre et rend **une** uri, en dépensant le moins possible et
en n'écrivant rien dans le store.

Deux appels, tous deux déjà connus de l'app :

1. `/api/entities/reverse-claims?property=wdt:P629&value=<workUri>&refresh=false` → les uris
2. `/api/entities/by-uris?uris=<…>&attributes=info|labels|claims|image&lang=fr` → par lots de 50

`attributes` est réduit à ce que le classement lit : le titre (`wdt:P1476`), la couverture
(`image` / `invp:P2`), la langue et l'uri. **`info` est indispensable** : la langue de l'édition se
lit sur `originalLang`, qui est son code ISO (`"fr"` pour une édition française — vérifié), et ce
champ n'est renvoyé que sous `info`. Le seul attribut qu'on économise par rapport à
`EntityModel.fetchEntities` est `descriptions` ; le vrai gain de ce lecteur n'est pas le poids de la
réponse, **c'est qu'il n'écrit rien**. Un DTO dédié décode le tout, sur le modèle de
`PagesEntitiesDTO` dans `AppModels/Common/EditionPagesLoader.swift`.

**Il ne passe pas par `EntityModel.getWorkEditions`.** Celle-ci insère toutes les éditions,
recalcule les œuvres de chacune et appelle `save()` sur le main actor : 127 objets pour *1984*, sur
un simple tap. Ce lecteur-ci classe en mémoire sur les DTO et rend une uri ; c'est l'appelant qui
persistera la gagnante, plus tard, via `refreshEdition`.

Le drapeau `isHeld` des candidats vient d'une lecture locale des `InventoryItem` — les miens et ceux
de mes amis sont déjà en SwiftData. Le lecteur reçoit l'ensemble des uris possédées en paramètre
plutôt que d'aller les chercher : il ne doit pas connaître le `ModelContext`.

Mesures de référence, à ne pas dégrader : ~750 ms et ~60 KB par œuvre. `reverse-claims` **ignore
`limit`** (`unexpected parameter`), donc la liste complète revient toujours — inutile de chercher à
la borner côté serveur.

## Acceptance criteria

- [ ] Le lecteur rend l'uri de l'édition retenue, ou `nil`, et n'écrit jamais dans le `ModelContext`
- [ ] Il utilise `EditionRelevance` et ne réimplémente aucune partie de l'échelle
- [ ] Les uris possédées entrent par paramètre, pas par une lecture du store
- [ ] Les lots de `by-uris` sont de 50, comme `EntityModel.fetchEntities`
- [ ] `attributes` demande `info|labels|claims|image` — `info` pour `originalLang` — et pas
      `descriptions`
- [ ] Une œuvre dont `reverse-claims` rend `[]` donne `nil` sans lever
- [ ] Tests sous `MockURLProtocol` : réponse vide, réponse en deux lots, `by-uris` partiel
      (une uri demandée qui ne revient pas), erreur réseau
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0083-edition-relevance-rule.md`
