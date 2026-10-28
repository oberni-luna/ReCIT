# Supprimer un groupe, quand on en est le seul admin

Shipped on 2026-10-28. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

An admin's « … » menu on a group's screen ends with **« Supprimer le groupe »**, in red, apart from the other
entries. It asks first — « Supprimer « Club » ? », with a message that counts the members who will be removed and
says it cannot be undone. Once confirmed, the menu gives way to a spinner and the back button hides. A success shows
« Groupe « Club » supprimé » in the SnackBar and goes back to the list of groups. A failure shows the error in the
SnackBar and stays on the screen.

When another admin is in the group, the entry is greyed, with « Un autre admin est dans le groupe : seul l'unique
admin peut le supprimer. » under it.

## How inventaire.io deletes a group

**It has no endpoint for it** — not in the live spec (v5.1.1), not in the controllers on Codeberg. The server drops a
group in one case only: `deleteGroupIfEmpty`, run on `group:leave`, marks it deleted when it has no admin left. And
the last admin may only leave once there are no members (`userCanLeaveGroup`). So the app empties the group, then
leaves it:

1. `GET /api/groups/by-id`, so that someone who joined since the screen opened is counted, and an admin named meanwhile
   stops it.
2. `PUT /api/groups/kick` for each member, one after the other.
3. `PUT /api/groups/leave`.

Another admin cannot be removed — `kick` answers `target user is also a group admin` (403) — which is why only the
sole admin can delete. Invitations and requests still pending do not stop the deletion.

## Technical surface

- **`ReaderGroup.canDelete(_:)`** (`Model/Groups/`) — true when the admins are exactly me. Covered in
  `ReaderGroupTests`.
- **`GroupTransitionError.otherAdmins`** — thrown when the fresh read finds another admin.
- **`GroupModel.deleteGroup(id:modelContext:)`** — the three steps above, then the `StoredGroup` and any copy in
  `visitedGroups` forgotten. Covered in `GroupModelTests`: the order of the calls and who each `kick` names, nothing
  sent with another admin, a refused `kick` that stops before `leave` and reads the group again.
- **`GroupDetailView`** — the menu's last section, the confirmation dialog, the spinner, `dismiss()` on success.
  Identifier `e2e.group.delete`.
- Strings `groups.delete`, `groups.delete.confirm %@`, `groups.delete.confirm.message %lld` (plural, with a zero
  case), `groups.delete.other_admins`, `groups.deleted %@`, fr and en.

## Notable decisions

- **Remove the members, then leave** — chosen by the user over offering the deletion only to an admin alone in the
  group, which would have been a single, safe `leave`.
- **Not optimistic**, like `createGroup` and the account's deletion: it cannot be taken back and takes one call per
  member. A refusal halfway stops there; the members already removed stay removed, and the group is read again so
  the screen shows who is left. There is no undo.
- **Greyed, not hidden, with another admin**, so that an admin who looks for the entry finds why it is not there.
- **The back button hides while it runs**: `dismiss()` arriving after a manual back would close whatever is on
  screen by then.
- **No pacing between the `kick`s.** The server documents no limit on them, unlike `PUT /api/user`.

## Not done, not verified

- Built and unit suite green. **Never run against inventaire.io**: no group has been deleted for real, and whether
  each `kick` sends the removed member an e-mail is not checked.
- Installed on a device as a debug build, never tried there nor on a simulator; the menu's subtitle under a disabled
  destructive entry is unchecked by eye.
- The end-to-end scenario was not run, and does not cover it.
- Android has no deletion.
- No Figma frame.
