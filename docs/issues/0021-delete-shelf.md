Title: Delete an étagère from its form
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0006-ai-auto-sort.md

## What to build

Étagères can be created and edited but not deleted. The server supports it; the app does not.

Add a destructive delete action at the foot of the étagère form, shown only when editing an
existing shelf — never when creating one. It asks for confirmation, then deletes.

**Deleting an étagère removes the shelf, never the books.** The items stay in the inventory
and keep their membership of any other étagères. The confirmation should say so, because
"supprimer l'étagère" is exactly the phrasing a user will read as "supprimer mes livres".

The write follows the same optimistic discipline as create and update: apply locally at once,
call in a model-owned background task, revert and surface the error through the shared
reporter on failure.

After a successful delete the form dismisses, and the user lands back wherever they came from
— which, once the "Modifier" action from issue 0008 exists, is the shelf's own detail screen.
That screen's shelf no longer resolves, so it must pop rather than sit on a dead id.

This is listed as a prerequisite of the AI auto-sort PRD — bulk shelf creation with no way to
undo it leaves users stuck — but it is independently useful and could ship on its own at any
time.

## Acceptance criteria

- [ ] The étagère form shows a delete action at its foot when editing an existing shelf.
- [ ] The action is absent when creating a shelf.
- [ ] The action is styled as destructive.
- [ ] Deleting asks for confirmation first.
- [ ] The confirmation makes clear the books are kept and only the shelf is removed.
- [ ] After deletion the books remain in the inventory.
- [ ] Books on other étagères keep that membership.
- [ ] The shelf disappears from the carousel immediately, before the network call returns.
- [ ] Deleting the last étagère shows the empty-state card.
- [ ] A failed delete restores the shelf and surfaces the error through the shared reporter.
- [ ] Deleting from a shelf's detail screen pops that screen rather than leaving it on a shelf that no longer resolves.

## Blocked by

None - can start immediately.
