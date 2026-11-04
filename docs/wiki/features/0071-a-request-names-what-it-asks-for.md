# A request names what it asks for

Shipped on 2026-11-01, from a screenshot of the request sheet (« Demande pour What If? à Q2 », a « Type » picker
reading `lending`). No PRD and no issues: one slice, its questions settled in conversation before the code.

## What it does

The sheet that asks a friend for their copy no longer offers a « Type » picker. It says what is being asked for,
taken from the copy's status:

| Copy | Title | Sentence | Button |
|---|---|---|---|
| À prêter | Emprunter *What If?* à Q2 | Vous souhaitez l'emprunter à **Q2** | Demander à l'emprunter |
| À vendre | Acheter *What If?* à Q2 | Vous souhaitez l'acheter à **Q2** | Demander à l'acheter |
| À donner | Récupérer *What If?* de Q2 | Vous souhaitez le récupérer de **Q2** | Demander à le récupérer |

The message stays required; its label carries a hint by type — « Votre message (obligatoire) : quand et où
pourrais-je l'emprunter ? », « … à quel prix, et comment pourrais-je l'avoir ? », « … quand et où pourrais-je le
récupérer ? ».

The entries that open the sheet follow the same words: « Emprunter à Q2 », « Acheter à Q2 », « Récupérer de Q2 » in
a book row's context menu on the book screen and on a friend's profile. The book's « … » menu, which lists up to
five owners, is titled by the type when they all offer the same (« Acheter à »), and « Demander à » when they
differ, each owner's line then subtitled « À prêter », « À vendre » or « À donner ».

## Technical surface

- **`TransactionType+Request.swift`** (`Features/Transactions/`) — `requestTitle(book:owner:)`,
  `requestSentence(owner:)`, `requestButtonLabel`, `requestMessageLabel`, `requestMenuLabel(owner:)`,
  `requestMenuTitle`, each a `LocalizedStringResource`. `.inventorying` falls back to the generic wording; no entry
  offers it.
- **`TransactionFormView`** — `isRequest` (`_id` empty) picks the request wording; a message on an existing
  transaction (`transition == nil`) keeps « Demande pour … à … » and « Envoyer ». The picker is gone, and with it
  the `@Bindable` on the transaction, which nothing writes any more.
- **`BookActions`, `BookDetailView`, `UserInventoryTab`** — the entry labels.
- The sentence reuses `transaction.desc.requester.{lending,selling,giving}`, the line a transaction row already
  shows to its requester.
- Strings: `transaction.request.{title,button,message}.{lending,selling,giving}`, `action.{buy_from,take_from}`,
  `action.{buy_from_user,take_from_user} %@`, `action.ask_from`, fr and en.
- **`TransactionRequestWordingTests`** — the French title, sentence, button and menu words for each type, and the
  shape of the message label.

## Notable decisions

- **The picker was wrong as well as unclear.** `POST /api/transactions` sends only `item` and `message`;
  inventaire.io takes the type from the item. Picking « selling » on a copy to lend changed the local, optimistic
  transaction only, which then showed the wrong type until the next sync.
- **One sentence, not an explanation of the steps.** Of three options — the steps that follow, one sentence, the
  status tag alone — the sentence already shown on the transaction row was chosen.
- **« Récupérer » for a gift**, in the title, the button and the menus, to agree with that sentence.
- **Android has no request flow at all** (feature 0031 left transactions out); porting the request sheet with these
  same words was split off to its own session.

## Not done

- Not seen on a simulator: the one at hand was signed out, and signing in to inventaire.io is not something done on
  the user's behalf. Checked by a simulator build and the unit tests above.
- No request sent for real. e2e not run.
