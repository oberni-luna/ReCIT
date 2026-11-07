---
issue: 63
status: todo
wiki: [[lists]], [[network]], [[features/0028-network-tab-and-groups]], [[features/0060-list-cover-flow]], [[features/0068-lists-in-my-network]], [[features/0074-a-lists-visibility-in-its-form]]
note: Part of #62 (Ex-libris backend umbrella). Blocked by #74 (backend lists) and #72 (backend groups). Ex-libris only — inventaire.io has no group lists. Android catches up in its own task.
created: 2026-11-07
---

## Context / Decisions

> a list every group member can edit
>
> Je veux ajouter la possibilité d'avoir des listes qui appartiennent à un groupe (et donc éditables par tout le groupe).

A list can belong to a group: every member edits it together. Backend + iOS here; Android later.

1. **A list attached to a group.** `lists` gains a nullable `group` (a group id) beside `creator`. An ordinary list behaves exactly as today. On a group list, **any member** (admin or member role, not invited / requested / declined) may rename it, change its description, add, comment and remove elements.
2. **Deleting or detaching** a group list (changing or clearing its `group`) is reserved to its **creator and the group's admins**. Attaching a list to a group: its creator, who must be a member of that group.
3. **Leaving the group** (leave, kick, account deletion): the person loses edit rights; the elements and comments they added stay. A creator who leaves keeps the right to nothing on that list; it stays the group's.
4. **When the group ends** (last member leaves, « Supprimer le groupe » of 0056): each of its lists is detached and becomes its creator's personal list with visibility `[]` (Moi seul·e); a list whose creator's account is gone is deleted.
5. **Visibility of a group list**: always readable by the group's members. Its « Visible par » offers **Le groupe** (default, stored `group:<id>`) or **Tout le monde** (`public`); the personal modes don't apply. Writes are checked on membership, not on visibility.
6. **Who added it**: each element keeps the user who added it (`list_elements.added_by`, Ex-libris field `addedBy` in the answer, absent on old elements). On a group list the line « Ajouté le 7 novembre 2026 » reads « Ajouté par Camille le 7 novembre 2026 ». The element's comment stays a single field any member can edit (discussions are #66).
7. **API** (Ex-libris additions, inventaire.io's routes otherwise unchanged): `POST /api/lists` and `PUT /api/lists` accept `group`; list documents carry `group` when set; `GET /api/lists/by-groups?groups=<id>|<id>&with-elements=true` lists the groups' lists the viewer may see, most recently updated first. Refusals in #74's shapes (`wrong user` 403, `not_found: missing`).
8. **iOS**:
   - the group screen (`GroupDetailView`) gets a « Listes » section with the group's lists and « Créer une liste » (attached to that group);
   - the Lists tab gets « Dans mes groupes » between « Mes listes » and « Dans mon réseau », each row headed by the group's name and picture;
   - the list form gains a « Groupe » picker (Aucun, then my groups) and, on a group list, « Visible par » offers Le groupe / Tout le monde;
   - a group list opens editable for every member (the read-only friend's-list mode only for non-members); « Supprimer la liste » shows only to its creator and the group's admins.
9. **Where it lives**: backend `lists` package (repository, service, rules) + a `GroupsService` hook for leave/kick/end; migration V8. iOS `Features/Lists/` and `Features/Network/Groups/`, `EntityList` gains `groupId`, `EntityListItem` gains `addedBy`.

### Out of scope

- Android (its own catch-up task).
- Element discussions (#66), notifications to the group.
- Lists shared with arbitrary co-editors outside a group.

## Acceptance criteria

- `POST /api/lists` with `group` by a member → 201, the list carries `group`; by a non-member → 403.
- A plain member adds, comments and removes elements on a group list and renames it → 200 each; a non-member → 403 `wrong user`.
- `POST /api/lists/delete` (and `PUT` clearing `group`) by a plain member who isn't the creator → 403; by the creator or a group admin → 200.
- A member kicked from the group → their next write on the group's list → 403; the elements they added are still there.
- The group ends (last member leaves) → its list now has no `group`, visibility `[]`, creator unchanged; a list whose creator was deleted is gone.
- `GET /api/lists/by-groups?groups=<id>` returns the group's lists to a member, and only `public` ones to a non-member.
- An element added to a group list carries `addedBy`; an element added before this task has none and still decodes.
- iOS, local backend: on a group's screen « Créer une liste » creates a list shown under « Listes » and in the Lists tab under « Dans mes groupes »; a second member of the group opens it editable, adds a book by search and sees « Ajouté par … »; that member does not see « Supprimer la liste »; the creator does and deletes it.
- iOS: the list form's « Groupe » picker attaches an existing list to a group and detaches it; « Visible par » on a group list offers only Le groupe and Tout le monde.
- Each new route or field has a backend test; the existing #74 tests still pass.
