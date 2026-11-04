# 0055 — Modifier son profil, son compte et ses notifications

Shipped on 2026-10-28, in four commits, on autopilot from PRD 0029 and issues 0141 → 0144 (both
deleted with this write-up). Designed the same day in Figma: section `Edition de profil`
(`800:3908`, page `Profil`), frames `A1` → `A9`, panel `Spec · Édition de profil` (`811:1380`).

## What it does

**The Profil can change the account.** Under the account's header, « Modifier le profil »; under
it, a « Réglages » section with « Compte et connexion » and « Notifications par e-mail ».

- **Modifier le profil** — the picture (camera, Photos, the account's Gravatar, or none), the
  username, checked while it is typed as at sign-up, the bio, counted against 1 000 characters,
  and the position, placed on a map. One « Enregistrer », pinned at the foot.
- **Position** — pushed from the form: the pin stays in the middle while the map moves, a search
  moves the map to a place, « Valider » hands the centre back to the form, rounded to two
  decimals (about a kilometre), « Retirer ma position » takes it away.
- **Compte et connexion** — the address and the password, each on a screen of its own; the
  language of the account; « Visible sur le fédivers »; « Contributions anonymes ». While the
  address is not confirmed, a card says where the link went and sends it again.
- **Notifications par e-mail** — the general switch, the activity summary and its frequency, and
  one switch per notification, grouped as friends, groups and exchanges.

**The bio shows under the name** in every user header — mine in the Profil, a friend's on theirs.

## Technical surface

- **`UserDTO`** reads `bio`, `validEmail`, `fediversable`, `summaryPeriodicity` and `settings`
  (`UserSettingsDTO`). **`User.bio: String?`** — a lightweight migration, optional for the reason
  `created` is.
- **`AccountSettings`** — the owner's half of the account, a value held by `UserModel.account`,
  filled by `syncMyUser`, emptied by sign-out and account deletion, never stored. Absent switches
  read as the server reads them: on. **`NotificationSetting`** — the ten keys of
  `settings.notifications`.
- **`ProfileDraft`** (pure) — the form against what the server last agreed to: the changed
  attributes in order (`picture`, `username`, `bio`, `position`), the validation, the rounding,
  and `markLanded(_:)` after a partial failure. **`ProfileChange`**, **`ProfileSaveFailure`**.
- **`UserModel+Profile`** — `saveProfile(_:modelContext:)`: the picture uploaded to
  `container=users` first, then one `PUT /api/user` per change, each written onto `myUser` as it
  lands; `gravatarImage()`: `GET /api/images/gravatar`, then the picture downloaded through
  `URLSession.cookieless`, `nil` on its `404`.
- **`UserModel+Account`** — `setLanguage`, `setFediversable`, `setAnonymizesContributions`,
  `setSummaryPeriodicity`, `setNotification`, all optimistic through `optimistic(...)`, each
  reverting only its own value; `changeEmail(to:)`, `resendEmailConfirmation()`,
  `changePassword(current:new:)` (`PasswordChangeFailure`), server first.
- **`RequestPacer`** — every `PUT /api/user` waits for its slot, 1.1 s after the previous one.
- **`UserAttributeUpdate`** — the `{ attribute, value }` body, with an explicit `null`.
- **Screens** — `EditProfileView`, `ProfilePhotoPicker`, `ProfileBioField`,
  `ProfilePositionSection`, `ProfilePositionView` (`Features/Profile/EditProfile/`);
  `AccountSettingsView`, `EmailConfirmationNotice`, `ChangeEmailView`, `ChangePasswordView`,
  `NotificationSettingsView`, `AccountToggleLabel` (`Features/Profile/Account/`).
- **`NavigationDestination`** — `.editProfile(user:)`, `.accountSettings`, `.changeEmail`,
  `.changePassword`, `.notificationSettings`.

## Notable decisions

- **One attribute per request, so no atomic save.** `PUT /api/user` takes `{ attribute, value }`
  and nothing more. The form is server first, like « Modifier l'édition »: a refusal part of the
  way keeps what landed, a banner says which attribute was refused, and the next « Enregistrer »
  sends the rest.
- **A second between two writes.** The server's rate limit on `PUT /api/user` is
  `minTimeBetweenRequests: 1000` — read in its source, not in the spec. Without the pacer, the
  second of two switches flipped in a row came back `429` and flipped back.
- **The settings are not in SwiftData.** They are the owner's alone and read again at every launch;
  a dozen switches were not worth a migration. The bio is, because a friend's header shows it.
- **The Gravatar is downloaded, not converted.** It then previews like a photograph and is saved by
  the same upload, rather than through `POST /api/images/convert-url`.
- **The position is rounded to two decimals before it leaves the phone.** It is public; the server
  keeps five.
- **`group_join_request`** is read as someone asking to join a group I run. The server's
  documentation (« asked to be a member of a group ») could also mean an invitation.

## Owed, and known

- **Never seen running.** Built and unit-tested (Swift Testing, `MockAPIService`); no screen was
  looked at on a simulator, and nothing was written to inventaire.io.
- **The save bars use `formActionBar(_:)`**, introduced by the change to `FormActionBar.swift`
  that was uncommitted when this shipped: the four commits do not build without it.
- **« Utiliser ma position actuelle » not done** — it needs the location permission and its usage
  string in `project.pbxproj`. Nor the place's name under the map (reverse geocoding).
- **`customProperties` and `poolActivities`** are not offered.
- **`scripts/e2e.sh` not run**; the new controls carry `e2e.editProfile.*`, `e2e.account.*`,
  `e2e.changeEmail.*`, `e2e.changePassword.*`, `e2e.notifications.*` and `e2e.profilePosition.*`
  identifiers, none of them played.
- **Figma** — the save bar is the form's; the map preview has no place name; the email card is drawn
  as `Form / Notice` but coded on `backgroundTinted` without a dismiss cross.
- **Android** (`Recit_Android/`) not touched.
