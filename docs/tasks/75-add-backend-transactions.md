---
issue: 75
status: to-test
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

## Implementation

stacked on: wa/74-add-backend-lists @ 6afbe45

- **Migration `V7__transactions.sql`:** `transactions` (no FK to `users` or `items`, so an Échange outlives the book and either account; snapshot stored in columns), `transaction_actions`, `transaction_messages` (cascade with their Échange; `user_id` without FK, so a deleted reader's messages stay). `TransactionsTable.holdsItem()` is inventaire.io's `byBusyItem`: `accepted`, or a loan `confirmed`.
- **Package `transactions`:** routes, `TransactionsService`, `TransactionMessagesService`, repositories, `TransactionRules`, `TransactionMoves` (the state machine, every from/to pair and actor tested), answer documents.
- **Effects on the book:** `by-ids` now answers the real `busy`; a confirmed gift or sale moves the book to the requester (`visibility: []`, `shelves: []`, `transaction: inventorying`, `details` dropped) and moves `items:count`.
- **Account deletion:** `transactions.cancelOpen` runs before the books cascade, as inventaire.io orders it; finished Échanges stay readable by the other side; when both accounts are gone the Échange goes with its messages.
- **Apps unchanged.** iOS posts `/api/transactions` with the action in the body, `PUT update-state`, `POST messages`; Android posts `/transactions/request` and its error matching hits the backend's wording. `?action=` forms, legacy `get-messages` / `message` and the deprecated `transaction` key accepted.
- **Differences from inventaire.io:** requesting a book one may not see → 403 for every visibility (inventaire.io lets a stranger through on `friends`/`groups` books), and visibility is checked before « already busy » so a stranger can't learn the book is lent; `GET messages` only for the Échange's two readers (inventaire.io answers any signed-in reader); no `history` on a moved book; list oldest first; `by-item` and `mark-as-read` not served; an unknown body action → 400; concurrent writes → 409; no e-mails, `warnings` or per-route limits.
- **The state machine follows Codeberg where the spec's list was silent:** `confirmed` → `cancelled` allowed for either side; `accepted` already makes the book busy; only `cancelled` actions carry `actor`; the request answers 200, not 201.
- **App notes, not backend bugs:** neither app marks an Échange read (iOS `readMessage` is an empty TODO), so a side's `read` turns true only when it acts or writes; iOS `isRead(by:)` is inverted (decision 5, left as is); iOS `syncTransactions` skips an Échange whose book isn't in the local store or whose other reader can't be fetched, so Échanges with a deleted reader or a given-away book disappear from iOS lists though the API returns them.

## Verification

- `./gradlew build`: 235 tests green, ktlint and detekt clean. iOS build + `ReCIT_iOSTests` (1327) green; Android build + 607 unit tests green.
- Every backend criterion replayed by curl on the local backend (request with message and snapshot; refusals on an `inventorying` book, one's own book, a stranger on a `friends` book, nothing created; list on both sides with read flags; `accepted` by the wrong side refused; loan busy after accepted and confirmed, free after returned; gift confirmed moving the book and the counts; cancel by the requester; messages flipping `read`; owner's account deleted with the requester still seeing all four Échanges and the given book). ~7 anonymous inventaire.io GETs, no 429.
- **On-screen journey NOT run.** Seed ready (friend_71's request on ios_70's « 1984 », id `7fdcdb682c954cee910baa7ae9da0145`; « L'étranger » to ask for). The iOS app launched on the local backend but sent no request, then the simulator stopped answering screenshots: the Mac's load stayed at 80–300 (92 system `SetStoreUpdateService` processes, plus another session's `xcodebuild` on a second iPhone 17 simulator). To do on the test branch: as `exlibris_ios_70`, « Toutes les transactions » › accept and write; as `exlibris_friend_71`, confirm « 1984 » and accept the request on « L'étranger »; back as ios_70, mark « 1984 » returned.
