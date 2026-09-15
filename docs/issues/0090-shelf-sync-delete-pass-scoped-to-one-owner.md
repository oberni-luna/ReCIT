Title: Le passage de suppression de `syncShelves` ne doit regarder qu'un propriétaire
Labels: needs-triage, bug
Type: AFK

## Parent

`docs/prd/` — préalable à l'affichage des étagères d'un ami.

## What to build

`ShelfModel.syncShelves` appelle `modelContext.upsert(…, deleteMissing: true)`. Or
`ModelContext.upsert` commence par `try fetch(FetchDescriptor<M>())` : **toutes** les étagères du
store, tous propriétaires confondus. Tant que le seul propriétaire synchronisé est moi, personne ne
s'en aperçoit. À la première synchro des étagères d'un ami, la réponse ne contient que les siennes,
et le passage de suppression efface les miennes.

Ce n'est donc pas une précaution : c'est le bug que la fonctionnalité déclencherait, écrit avant
elle pour qu'il n'existe jamais.

**`upsert` gagne une portée.**

```swift
/// - scope: quels modèles locaux ce merge a le droit de supprimer. Par défaut tous, ce qui
///   est le comportement historique. Une synchro qui ne rapporte qu'une partie du store —
///   les étagères d'un propriétaire, et pas celles des autres — passe ici le prédicat qui
///   décrit sa part, sinon `deleteMissing` supprime ce dont elle n'avait pas la charge.
scope: (M) -> Bool = { _ in true }
```

La portée ne s'applique **qu'au passage de suppression**. La table de correspondance par id reste
globale : un document trouvé sous un `_id` existant doit être mis à jour sur place, quelle que soit
la portée, sinon `@Attribute(.unique)` refuse l'insertion d'un doublon.

`syncShelves` passe `{ $0.ownerId == forUser._id }`. Aucun autre appelant de `upsert` ne change.

## Acceptance criteria

- [ ] `ModelContext.upsert` accepte `scope`, avec une valeur par défaut qui préserve le
      comportement actuel
- [ ] `scope` ne filtre que la suppression, jamais la recherche par id
- [ ] `syncShelves` passe la portée du propriétaire qu'il synchronise
- [ ] Un test : deux propriétaires en base, une synchro qui ne rapporte que l'un des deux, les
      étagères de l'autre sont toujours là
- [ ] Un test : une étagère absente de la réponse **et** appartenant au propriétaire synchronisé
      est bien supprimée
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

- rien
