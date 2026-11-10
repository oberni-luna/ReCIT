---
issue: 112
status: to-close
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

## Implementation

- New `data/user/`: `AccountSettings` (`email`, `isEmailValidated`, `language`, `isFediversable`, `anonymizesContributions`, `of(UserDto)`); `AccountRepository` (in-memory `StateFlow`, `take(dto)` / `forget()`; language and the two switches optimistic through `OptimisticRunner`, each one paced `PUT /api/user` via `ProfileRepository.updateUserAttribute`; `changeEmail` server first; `resendEmailConfirmation`; `changePassword`); `PasswordChangeFailure` (`WrongCurrentPassword` | `Other`, each its sentence); `AccountLanguage` (the 29 server codes named in the phone's locale). `UserAttributeUpdate.of(attribute, Boolean)`.
- `UserDto` gains `validEmail`, `fediversable`, `settings` (`UserSettingsDto` with `notifications` and `contributions`, ready for #113); `PasswordChangePayload` (`old-password` / `new-password`). `UserRepository.syncMyUser()` returns the dto; `SessionCoordinator` runs `account.take(...)`, `account.forget()` in `forgetSignedOutUser` (sign-out, 401) and `deleteAccount`. `AppContainer.account`. Settings live in `AccountRepository`, not `UserRepository` (dependency cycle, Room).
- New `ui/profile/account/`: `AccountSettingsScreen` (+ VM), `EmailConfirmationNotice`, `ChangeEmailScreen` (+ VM, UiState), `ChangePasswordScreen` (+ VM, UiState; « Mot de passe oublié ? » through `AuthRepository.requestPasswordReset`). `Destination.AccountSettings`, `ChangeEmail`, `ChangePassword`. Profil: « Réglages » section with « Compte et connexion » under « Modifier le profil ».
- Shared: `designsystem/Forms.kt` `SwitchRow` (was `GroupComponents`' private `AccessSwitch`, which now calls it); `FormTextRow` gains `visualTransformation`. Strings in `strings_profile.xml` (iOS copy, « vous »; « la langue du téléphone »).
- API contracts verified (live `api_specs.json`, Codeberg `update_password.ts`, `email_confirmation.ts`, `user/update.ts`, `lib/update_email.ts`, `models/user.ts`, `user_session.ts`): attributes `language`, `fediversable`, `settings.contributions.anonymize`; email via `PUT /api/user` (`400 this email is already used` / `invalid email` → under the field); resend `POST /api/auth/email-confirmation` (own 2 000 ms limit, not paced); password `PUT /api/auth/password` (`400 invalid old-password` → WrongCurrentPassword, `invalid new-password` → Other; 8–256 characters enforced on screen). Neither email nor password change rotates the session cookie (only login/signup call `serializeUserSession`): nothing in `auth/` touched (ADR 0008).
- Deviation from the task's wording: an absent `fediversable` reads as **off**, as the server (`!user.fediversable`) and iOS (`?? false`) do; absent `anonymize` reads on; absent `validEmail` reads unconfirmed.
- Tests: `AccountRepositoryTest` (10), `AccountSettingsTest` (3), `AccountLanguageTest` (2). Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest` ✅ 640 tests, 0 failures.
- Known edge (as iOS): a switch refused after a sign-out + sign-in to another account would revert that field on the new account.
- Runtime not run: no inventaire.io credentials; nothing written.

## Review

### Round validation — 2026-11-10

- Scope: from the stack point, `origin/wa/111-add-android-profile-editing...wa/112-add-android-account-settings`; rebased onto #111's reviewed tip (`3903d40`) first.
- Findings (all 🟡 minor), fixed by autofix in two rounds:
  - [correctness] A write refused after signing in to another account reverted onto it: `AccountSettings.userId` + `stillThere`; test `aRefusalArrivingAfterAnotherAccountSignedInLeavesItsSettingsAlone`. The generic SnackBar (« Une erreur s'est produite ») can still show there; it carries no value of the previous account.
  - [correctness] A sign-out during `GET /api/user` restored the signed-out account's settings: `SessionCoordinator.syncAccount()` takes the reply only if still signed in. No unit test (no `SessionCoordinator` harness).
  - [correctness] « Compte et connexion » spun forever when the first sync failed: it syncs on open and shows « inventaire.io ne répond pas » / « Vérifiez votre connexion, puis réessayez. » with « Réessayer » (round 2 rewrote the wording).
  - [structure] E-mail refusal parsing moved to `data/user/EmailChangeFailure`, on `FieldAvailability.Outcome.from` — checked against inventaire.io's `checkEmailAvailability` (`error_name: invalid_email`, « this email is already used »).
  - [elegance] `contributions` typed (`ContributionSettingsDto.anonymize`).
  - [elegance] `SwitchRow`: caller's `modifier` first, `contentPadding` inside the touch area.
- Final: all fixed; round 2's two strings checked by hand. Build ✅, 644 tests, 0 failures.
- ⚠️ Code changed since the user's test: « Compte et connexion » when offline, the e-mail error under the field, switch rows' touch area (also the group settings' two switches).
- Wiki: nothing task-specific; the sprint's feature doc is written with #101.
- Screenshots: none — `verify.platform: ios`, this task is Android.
- Landing — #111 merged; rebased onto `sprint/android-1-4-0` without conflict. Build ✅.

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
