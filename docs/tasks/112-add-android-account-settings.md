---
issue: 112
status: todo
wiki: [[features/0055-profile-editing]], [[features/0083-rate-limited-sign-in-message]]
note: Split from #111 (Android port of iOS 0055 profile editing), 2026-11-09
created: 2026-11-09
---

## Context / Decisions

Port of « Compte et connexion » from iOS [0055](../wiki/features/0055-profile-editing.md). Builds on #111 (`RequestPacer`, `UserAttributeUpdate`, the `PUT /api/user` path).

- **Entry.** The Profil gets a « Réglages » section with « Compte et connexion » (and #113's « Notifications par e-mail »).
- **Screen**: the address and the password, each on a screen of its own; the account's language; « Visible sur le fédivers »; « Contributions anonymes ». While the address is not confirmed (`validEmail: false`), a card says where the link went and « Renvoyer » sends it again.
- **`AccountSettings`**: the owner's half of the account (`validEmail`, `fediversable`, `settings`, language…), read from my user at sync, held in memory by the user repository, emptied at sign-out and account deletion, **not in Room**. Absent switches read as the server does: on. `UserDto` gains the fields it needs.
- **Switches and language: optimistic**, each reverting only its own value, through `RequestPacer`; refusal → SnackBar.
- **Address and password: server first**, on their own screens; password change failures (wrong current password, too short…) each have their sentence, as iOS `PasswordChangeFailure`; email confirmation resend as iOS.
- Endpoints and bodies as iOS `UserModel+Account`, checked against inventaire.io's live OpenAPI or Codeberg sources.
- Strings French only, copy as iOS. Out of scope: Wikidata linking (0070), `customProperties`, `poolActivities`.

## Acceptance criteria

- Profil › Réglages › « Compte et connexion » opens the screen with address, password, language, fédivers, contributions anonymes.
- Unconfirmed address: the card names the address; « Renvoyer » sends the confirmation (unit test on the request).
- Flipping « Visible sur le fédivers »: the switch moves at once; refusal flips it back with a SnackBar (unit test).
- Two switches flipped in a row: two PUTs ≥ 1 s apart, no `429` (unit test with the pacer).
- Changing the language: sent, kept after relaunch (read back from the server).
- Address screen: a new address is sent server first; refusal says why, the old address stays.
- Password screen: wrong current password → its sentence; success → back to the screen with a confirmation.
- Sign-out then another account: no setting of the previous account shows.
