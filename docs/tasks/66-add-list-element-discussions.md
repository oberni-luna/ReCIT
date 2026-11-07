---
issue: 66
status: todo
wiki: [[lists]], [[features/0060-list-cover-flow]], [[features/0061-move-to-another-list]], [[features/0068-lists-in-my-network]], [[features/0017-report-user-generated-content]]
note: Part of #62 (Ex-libris backend umbrella). Blocked by #74 (backend lists); group-list moderation by group admins needs #63 when it lands (else creator only). Push notifications split to #92. Ex-libris only — inventaire.io has no element discussions. iOS only; Android catches up later.
created: 2026-11-07
---

## Context / Decisions

> a thread per list element, if the list allows
>
> Je veux pouvoir ouvrir une discussion sur un item de liste, plutot qu'un commentaire (les listes sont ouvertes ou non aux commentaires).

Each element of a list gets a discussion: readers who can see the list write messages under a book. Backend + iOS.

1. **The comment stays, the discussion is added.** « Mon commentaire » keeps being the list keeper's note on why the book is there (inventaire.io parity, nothing migrated). Below it, a thread of messages.
2. **Who writes**: anyone allowed to see the list (#74's visibility), when the list is open to discussions. On a public open list, any signed-in reader.
3. **Open by default.** Lists gain `discussions` (boolean, default `true`, existing lists included). The list form gets « Ouverte aux discussions ». A closed list keeps its messages readable and refuses new ones.
4. **Moderation**: an author edits or deletes their own messages; the list's creator (and, once #63 lands, the group's admins on a group list) deletes any message. « Signaler » on a message opens the existing report mail (0017), pre-filled with the list, the book and the message.
5. **Unread badge, no push.** Each reader has a last-read mark per element. The creator and anyone who has written in a thread see an unread count on the element in the list's cover flow and on the list's row in the Lists tab; opening the thread marks it read. Push notifications are #92.
6. **API** (Ex-libris additions): `GET /api/lists/element-messages?element=<id>` → `{ messages: [{ _id, user, text, created, edited? }] }` oldest first, marks read; `POST /api/lists/element-messages` `{ element, text }`; `PUT /api/lists/element-messages` `{ id, text }`; `POST /api/lists/element-messages/delete` `{ id }`. List documents carry `discussions`; elements carry `messagesCount` and, for the viewer, `unreadCount`. Text 1–5000 characters, trimmed. Refusals: 403 `wrong user`, 403 `discussions closed`, 404 `not_found: missing`.
7. **Deleting an element or a list** deletes its messages. **Account deletion** deletes the reader's messages (they are not anonymised).
8. **iOS**: under the selected element of the cover flow, below « Mon commentaire », « Discussion · N » opens a thread screen: messages with author picture, name and date, a field « Écrire un message… » pinned at the bottom with « Envoyer », a message's « … » with « Modifier » / « Supprimer » / « Signaler » as allowed. A closed list shows « Les discussions sont fermées sur cette liste ». Friends' lists (read-only) can be discussed too.
9. **Where it lives**: backend `lists` package (`ElementMessages*` service, repository, routes), migration after #63's; iOS `Features/Lists/` (thread screen, row), `EntityListItem` gains the counts.

### Out of scope

- Push and e-mail notifications (#92).
- Replies, reactions, mentions, pictures in messages.
- Android (its catch-up task).

## Acceptance criteria

- A friend who sees my `friends` list `POST`s a message on an element → 200; `GET element-messages` returns it with author and date; a stranger → 403.
- With « Ouverte aux discussions » off, a new message → 403 `discussions closed`; existing messages still returned.
- The author edits their message → `edited` set; another reader editing it → 403; the list's creator deletes it → 200.
- A new list and a list created before this task both answer `discussions: true`.
- A message from someone else raises my `unreadCount` on that element; my `GET` of the thread sets it back to 0.
- Removing the element from the list deletes its messages; deleting an account deletes that reader's messages.
- iOS, local backend: as `exlibris_friend_71`, on one of `exlibris_ios_70`'s lists they can see, « Discussion » › write « Tu l'as aimé ? » › Envoyer; as `exlibris_ios_70`, the list shows an unread count, the thread shows the message, answering works; « Supprimer » on friend_71's message is offered to ios_70 as the creator.
- iOS: switching « Ouverte aux discussions » off hides the field and shows « Les discussions sont fermées sur cette liste ».
- Each new route has a backend test; #74's tests still pass.
