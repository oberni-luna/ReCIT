# Asking a friend for a book, on Android

Shipped on 2026-11-01, on the branch `claude/practical-nash-2097bd`, without a PRD or issues. Until then Android
could not ask for a book at all: [0031](0031-android-app.md) left transactions out, and nothing called
`/api/transactions`. This ports the request alone — the form that asks — with the decisions taken the same day for
the iOS form: no « Type » picker, one sentence instead, and every word chosen by what the owner offers the copy for.

The rest of the transactions is still not ported: the list, a transaction's screen, its messages, accepting,
declining, returning. A request made from Android is answered on inventaire.io's website or in the iOS app.

## What it does

**An entry on a friend's copy.** Someone else's copy offered for lending, selling or giving gets a line of its own,
worded by that offer:

- « Emprunter à Anne » for a copy « À prêter »;
- « Acheter à Paul » for one « À vendre »;
- « Récupérer de Léa » for one « À donner » — a gift is « récupéré », not « reçu »;
- nothing for an inventoried copy, which the server refuses to put in a transaction.

The line appears in two places:

- **The book screen's « … » menu.** When I hold no copy, the requests head the menu, before « Liste » and « Ajouter
  à mon inventaire ». There is one line per owner, as iOS's `borrowableItems` does: their first copy on offer, five
  owners at most. A copy whose owner is not in the store has no name to word it with, and is left out. When I hold a
  copy, nobody else's is offered.
- **A book row's long press** (`InventoryItemRowWithActions`): a friend's profile, « Chez mes amis », search. The row
  offers its own copy only, not every friend's copy of the edition.

**A full-height form.** The line opens a sheet that rises to the top of the screen:

- the title « Emprunter Dune à Anne » / « Acheter Dune à Paul » / « Récupérer Dune de Léa »;
- one sentence where iOS had its picker: « Vous souhaitez l'emprunter à **Anne** » / « …l'acheter à **Paul** » /
  « …le récupérer de **Léa** » — iOS's `transaction.desc.requester.*` strings;
- « Votre message (obligatoire) », with a hint for the type under it:
  - lending: « Pour combien de temps, et comment vous le lui rendrez. »;
  - selling: « À quel prix, et comment vous pourriez vous retrouver. »;
  - giving: « Pourquoi il vous tente, et comment vous pourriez vous retrouver. »;
- the primary button pinned at the foot: « Demander à l'emprunter » / « l'acheter » / « le récupérer ». It is greyed
  while the message is blank.

The sheet reads the copy from the store by its id. If the copy disappears, or a sync makes it inventoried while the
sheet is open, the sheet closes.

**Sending.** The request is server-first, in the application scope, so closing the sheet stops the waiting, not the
request. On success the sheet closes and a snackbar says « Demande envoyée à Anne ». The three refusals the server
explains close the sheet with their reason:

- « Vous avez déjà fait une demande pour ce livre »;
- « Ce livre fait déjà l'objet d'une demande »;
- « Ce livre n'est plus proposé ».

Any other failure keeps the sheet open with the message typed, and says the error.

## The contract

Verified on 2026-11-01 against the live spec (`https://inventaire.io/public/api_specs.json`, API 5.1.1) and the
Codeberg source (`server/controllers/transactions/request.ts`, `lib/rights_verification.ts`,
`server/models/transaction.ts`):

- **`POST /api/transactions/request`** with **`{ item, message }`**, both required. The answer is `{ transaction }`.
  This is the canonical path. iOS still sends `POST /api/transactions` with `action: "request"` in the body, the
  legacy alias of the same controller.
- **The type is not sent.** `createTransactionDoc` copies `itemDoc.transaction` into the transaction. A copy that is
  `inventorying` gets `400 this item can't be requested`.
- **`403 item already busy`** when someone else's active request holds the copy. **`403 user already made a request
  on this item`** when I already asked. My own copy is refused too (`ownerAllowed: false`); the menu never offers
  it.
- The message is trimmed before it goes. Nothing is stored locally: Android keeps no transactions.

## Technical surface

| Piece | Where |
|---|---|
| Payload and answer | `network/dto/TransactionDtos.kt` — `TransactionRequestDto(item, message)` |
| The call | `data/TransactionRepository.kt`, `AppContainer.transactions` |
| Wording by type | `data/transactions/TransactionRequestWording.kt` — menu, title, sentence, hint, button; `canSubmit` |
| Which copies | `data/transactions/TransactionRequestTarget.kt` — `of(othersCopies)`; `BookActionsState.forCopy(row)` for a row |
| Refusals | `data/transactions/TransactionRequestFailure.kt` |
| Menu line | `BookMenuLine.Request` in `ui/book/BookActions.kt`, worded in `BookActionsHost` |
| The form | `ui/transactions/TransactionRequestSheet.kt` |
| Strings | `res/values/strings_transactions.xml` |

Test tags: `e2e.transactionRequest`, `.message`, `.submit`.

Tests, all JVM: `TransactionRequestRepositoryTest` runs over MockWebServer. It checks the method, the path, no query,
and a body of exactly `item` and `message`, then the `403` read as « already asked ». `TransactionRequestWordingTest`
checks the French of each type, read from the strings file: menu, title, sentence, button. It also checks that the
five fields differ by type, that the message is required, which copies become lines, the five-owner cap, the menu's
order on each side of the ownership line, a row's own copy, and the refusals.

## Not done, or not verified

- **Never sent for real.** No request was made to inventaire.io. The form was not seen on an emulator or a device.
- **No end-to-end step.** The Android scenario ([0065](0065-android-end-to-end-scenario.md)) does not request a
  book. A request would land in a real friend's inbox.
- **No transactions list.** A request sent cannot be followed from Android, and a request I already made is not
  known before the server says so.
- **iOS is not changed here.** Its form still shows the « Type » picker and sends the legacy `action: "request"`
  until its own rework lands.
