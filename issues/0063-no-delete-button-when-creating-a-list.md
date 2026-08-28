Title: The list form offers to delete a list that does not exist yet
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: docs/features/ — the lists feature has no doc; `ReCIT_iOS/Features/Lists/ListFormView.swift` is the source.

## What to build

Open « Créer une liste » and a red « Supprimer la liste » sits under « Envoyer », offering to
delete a list that has never existed. Pressing it calls the delete endpoint with an empty id.

The form already knows which mode it is in: `list._id.isEmpty` is what switches the title
between « Créer une liste » and « Modifier la liste », and what hides the type picker when
editing. The destructive button simply was not given the same test.

## Acceptance criteria

- [ ] No delete control while creating a list
- [ ] The delete control is unchanged while editing an existing one
- [ ] The mode is decided in one place — the form must not grow a second, independent way of
      asking "am I creating or editing?"
- [ ] Creating a list still works, and the layout does not leave a gap where the button was

## Blocked by

None - can start immediately
