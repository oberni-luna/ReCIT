# Inviting a friend, or someone into a group, by email

Shipped on 2026-11-18, iOS only (issue #162). A reader not found by « Ajouter des ami·es lecteur·ices », or a friend
missing from a group's « Inviter des ami·es », can now be invited by email. inventaire.io already had the endpoint;
the app never called it. Mockups: Figma, page Réseau, section « Réseau · Inviter par e-mail » (`1118:5596`, I1 to I5
and the spec card). Android is #163.

## What it does

- A section « Pas encore sur inventaire.io ? » closes the list of both searches as soon as one character (not a
  space) is typed: under the results, or under the empty state when there are none. It holds one tinted row,
  « Inviter par e-mail », and a note saying what happens once the person signs up. At rest it is not there.
- In a group's « Inviter des ami·es », a query matching none of my friends now says « Aucun·e ami·e de ce nom »
  instead of « Aucun·e ami·e à inviter », which stays for the reader who has no friend at all.
- The row opens the sheet « Inviter par e-mail »: « Adresses e-mail » (several, separated by commas, semicolons,
  spaces or new lines), « Message (facultatif) », and « Envoyer l'invitation » pinned at the foot. A search holding an
  @ opens the sheet with that address filled in.
- Before sending, the addresses are read on the phone: lowercased, deduplicated, my own address dropped. A malformed
  one is named under the field in red, more than 50 says « 50 adresses au plus par envoi. », and either keeps the
  button disabled. Otherwise the footer says the addresses go to inventaire.io, which writes to each one.
- Sending is server-first, not optimistic: nothing in the store changes before the answer. The button spins; on
  success the sheet closes and a SnackBar says what left, built from the answer `{ users, emails }`: « Invitation
  envoyée à 2 adresses », « camille.b est déjà sur inventaire.io : demande envoyée », or both in one sentence. From a
  group, the request carries `group` and the sentences speak of the group invitation.
- An address that already belongs to an account gets a friend request (or the group invitation) and no email. When
  the answer names such accounts, the app resyncs: `syncRelations` for a friend, `GroupModel.fetchGroup` for a group,
  so the person shows « Envoyée » or « Invitée » at once. A failed resync is only logged.
- On failure the sheet stays open with what was typed. A `429` (inventaire.io's quota of 250 invitations per reader)
  says « Trop d'invitations envoyées. Réessayez plus tard. »; anything else is the usual error SnackBar.

## What inventaire.io does

Checked on 2026-11-18 against the live spec (v6.0.2) and the source on Codeberg (`server/controllers/invitations/`).

- `POST /api/invitations/by-emails`, `{ emails, message?, group? }`, signed in. 50 addresses per call (`400` above),
  250 per reader over time (`429`). For a group, being a member is enough (`403` otherwise), whatever the code comment
  says about admins.
- The email comes from inventaire.io and cannot be changed by the app. Its link opens `inventaire.io/users/<username>`
  or `/groups/<slug>` on the web, not `link.exlibris.lunabee.ovh`.
- On sign-up with that address, `convertInvitations` creates the friend request from me, or the group invitation. It
  works for the app's own sign-up (0011) as well as the web's.

## Technical surface

- `Model/Invitation/`, pure and `nonisolated`:
  - `EmailInvitationTarget`: `.friends` or `.group(id:)`, the one place friend versus group is decided; sheet,
    section, footer, outcome and request all take it.
  - `EmailInvitationList`: parses the field, `canSend`, `maximumCount = 50`, `malformedAddresses` as typed,
    `initialText(fromSearch:)` for the @ pre-fill.
  - `EmailInvitationOutcome`: the SnackBar sentence from `users` and `emails`, `hasExistingAccounts`.
  - `EmailInvitationFailure`: `429` → `.rateLimited`, else `.other(Error)`.
- `AppModels/User/`: `EmailInvitationPayload` (nil and blank message left out), `EmailInvitationDTO` and
  `EmailInvitationUserDTO` (username only; missing keys read as empty), and `UserModel+EmailInvitation`:
  `sendEmailInvitations(_:message:to:) async throws(EmailInvitationFailure)`. It lives in an extension because the
  SwiftLint baseline pins `UserModel.swift` at 416 lines.
- `Features/Network/EmailInvitation/`: `EmailInvitationSection`, `EmailInvitationSheet` (built like `CreateGroupView`:
  `DesignSystem.Form`, `formActionBar`, `AsyncButton`), `EmailInvitationAddressesFooter`.
  `Features/Network/Groups/InviteToGroupEmptyState` holds the two empty states of a group's friend search.
- Accessibility ids `e2e.emailInvitation.open`, `.addresses`, `.message`, `.send`, `.close`.
- Tests: `EmailInvitationListTests`, `EmailInvitationOutcomeTests`, `EmailInvitationFailureTests`,
  `UserModelEmailInvitationTests` (`MockAPIService`: method, path, body with `message` and `group` only when given).

## Not done

- No contact picker: one text field.
- Not in the end-to-end scenario: it would send real emails.
- The App Store privacy answers (third-party addresses sent to inventaire.io) are to check before the release.
- Installed on an iPhone; not seen on a simulator, iOS 18 unseen, e2e not run.
