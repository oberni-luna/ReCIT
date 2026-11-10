---
issue: 113
status: to-test
wiki: [[features/0055-profile-editing]]
note: Split from #111 (Android port of iOS 0055 profile editing), 2026-11-09
created: 2026-11-09
---

## Context / Decisions

Port of « Notifications par e-mail » from iOS [0055](../wiki/features/0055-profile-editing.md). Builds on #112 (`AccountSettings`, the Réglages section) and #111 (`RequestPacer`).

- **Entry.** Profil › Réglages › « Notifications par e-mail ».
- **Screen**: the general switch; the activity summary and its frequency (`summaryPeriodicity`); one switch per notification, grouped as friends, groups and exchanges — the ten keys of `settings.notifications` (`NotificationSetting`, as iOS). The general switch off greys the others.
- **Writes optimistic**, each reverting only its own value, through `RequestPacer`; refusal → SnackBar. Absent keys read as on.
- `group_join_request` read as someone asking to join a group I run (as iOS).
- Strings French only, copy as iOS.

## Acceptance criteria

- Profil › Réglages › « Notifications par e-mail » shows the general switch, the summary with its frequency, and the ten switches in three groups.
- General switch off: the others greyed and not editable.
- Flipping a notification: sent as its own attribute (unit test on the body), refusal flips it back with a SnackBar.
- Changing the summary frequency: sent, shown after relaunch.
- An account whose settings lack a key: that switch shows on.

## Implementation

stacked on: wa/112-add-android-account-settings @ a769ec22

- New `data/user/NotificationSetting.kt`: the 10 keys of `settings.notifications` (camel-case `group_acceptRequest` included), `attribute` = `settings.notifications.<key>`, `of(key)`.
- `AccountSettings`: `summaryPeriodicity` (default 20) and the notifications map; `isEnabled` (absent key = on), `with`, `canEdit(setting)` (only Global while Global is off), `canEditSummaryPeriodicity` (summary on too); unknown keys dropped. `AccountRepository.setNotification(setting, isOn)` / `setSummaryPeriodicity(days)` through the existing optimistic, paced `write(...)` (120 lines). `UserAttributeUpdate.of(attribute, Int)`; `UserDto.summaryPeriodicity`.
- New `ui/profile/account/NotificationSettingsScreen.kt` + `NotificationSettingsViewModel` (pure `periodicities(including:)`: 1, 7, 14, 20, 30 + the account's own value). Groups Ami·es / Groupes / Échanges. « Tous les jours » for 1, « Tous les %1$d jours » otherwise (iOS says « Tous les 1 jours »). `Destination.NotificationSettings`; Profil row below « Compte et connexion ». `SwitchRow` gains `enabled` (0.38 alpha, `DISABLED_ALPHA`). 21 strings in `strings_profile.xml`, « vous ».
- API contracts verified (Codeberg main + live `api_specs.json`): `PUT /api/user` `{attribute: "settings.notifications.<key>", value: bool}`; keys match `models/attributes/user.ts`; `summaryPeriodicity` integer ≥ 1, absent read as 20 (`design_docs/users.ts`); absent notification key = on (`check_user_notifications_settings.ts`, only `=== false` disables); `group_join_request` mails the group's admins (`lib/emails/email.ts`), as iOS reads it.
- Tests: `AccountRepositoryTest` (+4), `AccountSettingsTest` (+5), `NotificationSettingsViewModelTest` (2). Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest` ✅ 651 tests, 0 failures.
- Runtime not run: no inventaire.io credentials; nothing written. « Shown after relaunch » rests on the tested decoding.

## Review

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
