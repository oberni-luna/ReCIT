Title: `Work.preferredEditionUri` — le même geste ouvre le même livre
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-search-results-are-editions.md` — [ADR 0002, Move 3](../adr/0002-unified-book-detail.md)

## What to build

Je tape Dune, je reviens, je retape. Aujourd'hui : 750 ms de réseau, et rien ne garantit que le
classement rende la même édition qu'à la première fois. Après cette issue : instantané, et le même
livre.

**Un champ local additif** sur `Work` :

```swift
/// L'édition que le classement a retenue pour cette œuvre, `nil` tant qu'aucun tap ne l'a
/// résolue. Locale et dérivée : le serveur n'en sait rien, comme `genres` ou
/// `Edition.dominantColorHex`.
var preferredEditionUri: String?
```

Il est dans la même famille que `Work.genres` / `genresEnrichedAt` / `genresRevision` et
`Edition.dominantColorHex` / `numberOfPages` — tous locaux, tous absents du serveur, tous couverts
par la migration légère de SwiftData. Rien à écrire côté migration.

**Le moment de l'écriture n'est pas l'évident.** La recherche ne persiste rien, donc au moment du
tap il n'y a aucune ligne `Work` sur laquelle écrire la préférence. Le `Work` naît quand
`refreshEdition` résout le `wdt:P629` de l'édition gagnante, dans `resolveEditionWorks`. **C'est là
que la préférence s'écrit**, pas avant. Ajouter un `refreshWork` pour disposer du `Work` plus tôt
serait une troisième requête pour rien, et le PRD l'écarte explicitement.

**Le deuxième tap lit le cache, puis reclasse en fond.** On ouvre immédiatement sur
`preferredEditionUri`, et la résolution se rejoue en tâche de fond ; si elle rend une autre uri, le
champ est mis à jour. **L'écran déjà ouvert ne change pas de livre sous les yeux de l'utilisateur** —
c'est la visite suivante qui en bénéficie.

Attention au piège d'issue 0067 : ne pas écrire à travers une référence `Work` capturée avant un
`await`. Relire le `Work` par son uri au moment d'écrire.

## Acceptance criteria

- [ ] `Work.preferredEditionUri` existe, avec une valeur par défaut qui rend la migration légère
- [ ] Un premier tap l'écrit, une fois le `Work` matérialisé par `refreshEdition`
- [ ] Aucun `refreshWork` supplémentaire n'est ajouté au chemin du tap
- [ ] Un deuxième tap ouvre depuis le cache, sans attendre le réseau
- [ ] Le reclassement en fond met le champ à jour sans changer l'écran ouvert
- [ ] Le `Work` est relu par son uri au moment de l'écriture, jamais écrit via une référence
      capturée avant un `await` (issue 0067)
- [ ] Taper deux fois de suite la même recherche ouvre deux fois le même livre
- [ ] Le champ survit à un redémarrage de l'app
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0085-tapping-a-result-opens-a-book.md`
