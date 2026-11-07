---
issue: 75
status: todo
wiki: [[architecture]], [[features/0071-a-request-names-what-it-asks-for]], [[features/0086-a-friends-transactions-tab]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #73 (books, busy, ownership). Lender-declared loans (#64) build on it later.
created: 2026-11-07
---

## Context / Decisions

> requests, states, messages
>
> Part of #62. /api/transactions*, state machine, messages.

The backend serves Échanges (inventaire.io's transactions) between Ex-libris readers with inventaire.io's API, so asking a friend for a book, answering, confirming, returning and talking about it work unchanged on iOS and Android. Everything in #62 holds: same paths and JSON, ids in inventaire's shape, Exposed + Flyway, one package `transactions`.

1. **Five routes, the whole of inventaire.io's API for them.** These are every call the two apps make for Échanges:
   - `GET /api/transactions` (mine, as owner or requester);
   - `POST /api/transactions/request` (`{ item, message }`, feature 0071) and `POST /api/transactions` where the apps still send it;
   - `PUT /api/transactions/update-state`;
   - `GET /api/transactions/messages?id=` and `POST /api/transactions/messages`.
   Each accepts every parameter inventaire.io accepts for it, checked against its live OpenAPI spec when coded. `mark-as-read`, which neither app calls, is not served.
2. **inventaire.io's state machine, as it is on Codeberg when coded**: `requested` → `accepted` or `declined` by the owner, `cancelled` by either side; `accepted` → `confirmed` by the requester, `cancelled` by either side; a loan `confirmed` → `returned` by the owner. A transition not allowed, or by the wrong side, answers inventaire.io's error. Each change appends to `actions` with its timestamp.
3. **A request is allowed as on inventaire.io**: the book must be visible to the requester (#73's rules), not theirs, and offered (`giving`, `lending` or `selling`, not `inventorying`). The transaction's type is the book's `transaction` at the time of the request.
4. **State changes have inventaire.io's effects on the book**, verified on Codeberg when coded:
   - a loan `confirmed` sets the book `busy`; `returned`, `declined` and `cancelled` clear it;
   - a gift or sale `confirmed` moves the book to the requester: owner changed, visibility private, taken off the former owner's étagères; both owners' `items:count` (#73) follow.
5. **Read flags follow inventaire.io**: an action or a message sets the other side's `read` to `false` and the actor's to `true`. Feature 0086's suspicion that `isRead` is inverted is checked against inventaire.io's fixture when coded, not changed here.
6. **Each transaction stores a snapshot** of the book (title, authors, cover from #73's snapshot), the owner and the requester at request time, as inventaire.io does, so it stays readable when the book or an account goes.
7. **Account deletion** (#71): the reader's open Échanges become `cancelled`, with the effects above; finished ones stay for the other person, readable through their snapshot; the deleted reader's messages stay.
8. **No notifications**: inventaire.io's e-mails on Échanges and any push are out of scope (#62); the other side sees the change at its next sync.

## Acceptance criteria

- With two friends signed in on the local backend, `POST /api/transactions/request` by the friend with `{"item":<my lending book>,"message":"Je peux ?"}` answers the transaction in state `requested`, typed `lending`, and the message appears in `GET /api/transactions/messages?id=`.
- A request on a book with `transaction: "inventorying"`, on my own book, or on a book I may not see answers inventaire.io's error and creates nothing.
- `GET /api/transactions` answers it to both sides, with `read.owner` `false` and `read.requester` `true`.
- `PUT /api/transactions/update-state` with `accepted` by the owner succeeds; the same by the requester answers inventaire.io's error.
- A loan taken through `accepted`, `confirmed` and `returned` leaves the book `busy` after `confirmed` and not after `returned`; `actions` lists the three changes in order.
- A gift `confirmed` moves the book to the requester: `by-ids` shows the new owner, `visibility: []`, no étagère; the giver's `items:count` drops by one and the receiver's rises by one.
- A `cancelled` request on a loan leaves the book not `busy`.
- `POST /api/transactions/messages` adds a message and sets the other side's `read` to `false`.
- After the owner deletes their account, the requester still sees the finished Échange with the book's title from its snapshot, and an open one as `cancelled`.
- Every route answers the JSON of its fixture captured on inventaire.io (keys, types, error codes).
- The iOS app launched with `-ExLibrisBackend http://localhost:8080` asks a friend for a book, and the friend's build accepts it; both see the Échange in « Toutes les transactions » and on each other's profile, with its messages.
