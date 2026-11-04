# Signaler un membre ou un échange

Shipped on 2026-09-12, without a PRD: the ask arrived whole, and the design tree was walked in a
single grilling session rather than written down first. One commit, `08e3bef`.

## What it does

The app carries user-generated content — usernames, avatars, and the free messages two people
exchange around a book — and carried no way to say that one of them is a problem. It does now, on
both surfaces that show someone else's words.

Someone else's profile and a transaction's detail screen each gain a « … » in the navigation bar
holding one line: **Report** in English, **Signalement** in French. Touching it opens the user's
mail client on a message already addressed to `ex-libris@lunabee.com`, subject
« Signalement : alice » — with « — tx_abc123 » appended when the report is about an exchange.

The body opens on the sentence that invites the description, then two blank lines, then a rule and
the facts nobody would copy by hand: the reported member and their id, the exchange id, who is
reporting, the app version. The cursor lands where the writing happens.

**Nothing leaves the device on its own.** The app fills a draft; the person still presses send. A
report is someone's word, and the app must not put one in their mouth.

My own profile shows no menu — there is nobody to report there.

## Technical surface

- **`Model/Report/ReportMailDraft`** — a pure value type: who is reported, in which exchange, by
  whom, on which version, and how that becomes a `mailto:` URL. No SwiftUI, no `UIApplication`, so
  the subject, the body and the escaping are testable without a simulator.
- **`Features/Report/ReportButton`** — the menu line. `@Environment(\.openURL)` with its completion
  handler; `MFMailComposeViewController` was not used because it is UIKit.
- **`UserDetailView` and `TransactionDetailView`** each gain a `toolbarContent` holding the menu,
  on the shape `BookDetailView` already uses — `ToolbarItem(placement: .confirmationAction)`, a
  `Menu` labelled `action.more`, content tinted `.foregroundDefault`.
- **Nine strings**, `report.*`, English and French.
- **`Tests/ReportMailDraftTests`** — seven tests, all on the draft.

## Notable decisions

- **The transaction menu is in the toolbar, not in `TransactionActionsBar`.** The bar already owns
  a « … », but it disappears once `state.isFinished` and its overflow is a confirmation dialog of
  destructive transitions. An exchange stays readable after it ends, and so must stay reportable.
- **Mail, not an API call.** inventaire.io has no report endpoint; the mailbox is the moderation
  queue. This is the whole reason the feature is a URL and not a model.
- **The escaping is hand-rolled.** `URLComponents.percentEncodedQueryItems` is fed values escaped
  against `.urlQueryAllowed` minus `& = + ? # ;`: the standard `queryItems` path leaves `&` and `+`
  raw inside a value, and a username or a description can perfectly well contain either — which
  would truncate the report at the first ampersand. One test spends a username of `a&b=c+d?e#f` on
  exactly that.
- **The reported party on a transaction is `transaction.otherUser(for: me)`**, not the owner and not
  the requester — the method already existed for the message list.
- **No mail client is not a dead end.** `openURL`'s completion returning `false` shows a SnackBar
  carrying the address. The address is not copied to the pasteboard: `UIPasteboard` is UIKit.
- **The subject is localized**, like the button. A French button producing an English subject was
  never on the table.
- **The app version goes in the body** — a report about a bug-shaped behaviour is worth reading
  against a build.

## Known

- **This is the reporting half of App Store guideline 1.2.** The guideline also wants a way to
  **block** an abusive member — hiding their inventory, refusing transactions with them — and a
  stated commitment to act on reports within 24 hours. Neither is built. That is the next piece of
  work on this surface, and it is a real gap for review, not a nicety.
- **The end-to-end scenario is unmodified.** The identifiers are laid so it could be covered later:
  `e2e.user.menu` / `e2e.user.report`, `e2e.transaction.menu` / `e2e.transaction.report`. A scenario
  step would have to stop at the menu: pressing the line hands control to Mail, which the scenario
  cannot drive.
- **The reporting surface is limited to those two screens.** A user cell in the community list, a
  search result, an avatar in a message row — none of them carries the line. The two detail screens
  are where someone reads enough to want to report; adding the line further out is a judgement call
  left open.
- **The mailbox is hard-coded** in `ReportMailDraft.recipient`. There is no remote configuration in
  the app to hold it, and inventing one for a single address was not worth it.
