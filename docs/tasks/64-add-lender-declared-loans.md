---
issue: 64
status: todo
wiki: [[network]], [[features/0071-a-request-names-what-it-asks-for]], [[features/0086-a-friends-transactions-tab]]
note: Part of #62 (Ex-libris backend umbrella). Blocked by #75 (backend transactions). Ex-libris only — inventaire.io has no lender-declared loans. iOS only; Android lists no Échanges yet.
created: 2026-11-07
---

## Context / Decisions

> lender records a loan, friend confirms or refuses
>
> Je veux pouvoir "suggérer une transaction" : le prêteur peut déclarer qu'il a prêté un livre à un ami, l'ami peut ensuite confirmer ou infirmer (annule dans transaction), le prêteur peut ensuite confirmer le bon de retour du livre (comme dans les transactions actuelles).

The owner of a book records a loan already made; the borrower confirms or refuses it; the owner later marks it returned. Backend + iOS.

1. **A new starting state, `offered`.** Created by the owner on one of their own books, typed `lending`. From `offered`:
   - the borrower **confirms** → `confirmed` directly (the book has already changed hands);
   - the borrower **refuses** → `declined`;
   - the owner **cancels** → `cancelled`.
   After `confirmed`, the end is a loan's as today: the owner marks it `returned`, either side may cancel (#75's state machine).
2. **Lending only.** A declared gift or sale would move the book on a single confirmation: not now.
3. **To my network**: the borrower is a friend or a member of one of my groups (`RelationsService.networkIds`). Anyone else → 403.
4. **Any of my books**, whatever its transaction mode (Inventorié, À prêter…); the mode isn't changed. Refused when the book is already busy (`item already busy`), or when an open Échange already exists between the same two people on it.
5. **Busy from `offered`**: the book is busy as soon as the loan is declared (it is physically gone), free again on `declined` or `cancelled`. `holdsItem()` gains `offered`.
6. **Message optional** at declaration (unlike a request, where it is required); messages work as on any Échange.
7. **Roles stay as in #75**: the owner is `owner`, the borrower `requester`, so read flags, snapshot, the friend's Échanges tab and account deletion (an open `offered` is cancelled) work unchanged. The first action recorded is `offered`, carrying `actor: owner`.
8. **API** (Ex-libris addition): `POST /api/transactions/offer` with `{ item, user, message? }` → 200 `{ transaction }`; `PUT /api/transactions/update-state` accepts `confirmed` / `declined` from the requester on an `offered` Échange, `cancelled` from the owner.
9. **iOS**:
   - in the « … » of one of my books (book screen and a row's long press): « Je l'ai prêté à… » → a sheet listing my network (friends, then group members), a message field (facultatif), « Enregistrer »;
   - on the borrower's side the Échange appears in « Toutes les transactions » and the friend's Échanges tab, with « Confirmer » and « Refuser »;
   - on the owner's side, while `offered`: « En attente de confirmation » and « Annuler »; once confirmed, « Marquer comme rendu » as for any loan;
   - `UserTransaction.TransactionState` and `TransactionStateMachine` gain `offered` and its transitions.

### Out of scope

- Declared gifts and sales.
- Android (it lists no Échanges yet; its catch-up task will take this too).
- Reminders, due dates, notifications.

## Acceptance criteria

- `POST /api/transactions/offer` on my book to a friend, no message → 200, state `offered`, `actions[0]` = `offered` with `actor: owner`; `by-ids` shows the book `busy: true`.
- The same to someone outside my network → 403; on a book that isn't mine → 403; on a busy book → 403 `item already busy`.
- The borrower `confirmed` → state `confirmed`, the book stays busy; then the owner `returned` → book free.
- The borrower `declined` on an `offered` Échange → `declined`, book free; the owner `cancelled` instead → `cancelled`, book free.
- The owner trying `confirmed` on their own offer → 403 `wrong user`.
- Deleting the owner's account with an open `offered` Échange → it becomes `cancelled` for the borrower.
- iOS, local backend: as `exlibris_ios_70`, a book's « … » › « Je l'ai prêté à… » › `exlibris_friend_71` › Enregistrer → the Échange shows « En attente de confirmation »; as `exlibris_friend_71`, « Toutes les transactions » shows it with « Confirmer » / « Refuser », Confirmer → as ios_70, « Marquer comme rendu » closes it.
- Each new route and transition has a backend test; #75's tests still pass.
