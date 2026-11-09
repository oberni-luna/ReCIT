---
issue: 113
status: todo
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
