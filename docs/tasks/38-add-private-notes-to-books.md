---
issue: 38
status: todo
wiki: [[book-and-editions]], [[architecture]], [[design-system/figma-library]]
note: Figma — field `notes` 953:8367 (file S7IvC6GvlcUFe5IgbtvQq6)
created: 2026-11-06
---

## Context / Decisions

> pouvoir modifier les notes "privées" sur les livres (inventory items), via un nouveau champ dans la section "Dans mon inventaire" que j'ai designé ici : (https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=953-8367)

- **What**: a second text field in « Dans mon inventaire » (`BookMyCopySection`) on the Fiche livre: the Note privée.
- **Two fields, two inventaire.io attributes**:
  - « Ce que j'en pense » (existing) writes `details`: the Commentaire, seen by whoever can see the book. Unchanged.
  - « Ce que je garde pour moi » (new) writes `notes`: the Note privée. inventaire.io lists `notes` as private: only the owner receives it, it is never indexed, and it is reset when the book changes owner.
- **Mockup**: Figma `notes` instance `953:8367` — label « Ce que je garde pour moi » (caption, secondary), body in `content300`.
- **Place**: under « Ce que j'en pense », above the row with the date and the mode d'échange.
- **Copy**:
  - Label: « Ce que je garde pour moi » / « What I keep to myself ».
  - Placeholder: « Écrire une note » / « Write a note ».
- **Saving**: the same as « Ce que j'en pense » — after 1 s without typing, on focus loss, on leaving the screen; only when the text changed.
  Optimistic (ADR 0001): local first, `PUT /api/items/bulk-update` `attribute: notes` in the background, revert + SnackBar on failure; a stale failure never clobbers a newer note.
- **Data**:
  - `InventoryItem` gets `notes: String`, default `""` — lightweight migration, like the properties added since 1.1.0; `ModelContainerMigrationTests` must still pass.
  - `ItemsDTO` decodes `notes`; `update(from:)` merges it non-nil-guarded (a friend's item or a sparse payload never wipes my note).
- **Never shown elsewhere**: not on a Ligne livre, not on a friend's copy (`UserItemCellView` shows `details` only), not in search.
- **iOS only.** Android later.

## Acceptance criteria

- Fiche livre of a book I own: « Dans mon inventaire » shows « Ce que j'en pense », then « Ce que je garde pour moi », then the date and the mode d'échange.
- The new field is empty with the placeholder « Écrire une note » when the book has no note.
- Type a note, wait 1 s → `PUT /api/items/bulk-update` with `attribute: notes` and the text; « Ce que j'en pense » untouched.
- Type a note and leave the screen at once → the note is saved; reopen the Fiche livre → it is there.
- A note written on inventaire.io's website shows in the field after a sync, and the reverse.
- Server refusal or network down → SnackBar, the field goes back to the previous note.
- The book seen by a friend (their Profil d'un ami, or a book on inventaire.io's site) shows the Commentaire, never the Note privée.
- App updated over a store from the previous version: launches, books and their Commentaires intact, notes empty until the next sync.
- Book I don't own: no « Dans mon inventaire » section, as today.

## Implementation

## Review

## Verification

## Feedback
