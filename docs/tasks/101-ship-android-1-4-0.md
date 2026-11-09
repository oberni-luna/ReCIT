---
issue: 101
status: todo
wiki: [[integrations/google-play]], [[features/0065-android-end-to-end-scenario]], [[features/0077-android-catches-up-with-1-9-0]]
note: "Tu peux ajouter une dernière tâche à exécuter avec celles qu'on vient de créer pour Android, de pusher une version 1.4.0 sur le store"
created: 2026-11-09
---

## Context / Decisions

> Tu peux ajouter une dernière tâche à exécuter avec celles qu'on vient de créer pour Android, de pusher une version 1.4.0 sur le store

- **Version 1.4.0, versionCode 6**, Android's own numbering (1.3.0, code 5 at `7d37297`).
- **Sprint « Android 1.4.0 »**, branch `sprint/android-1-4-0` from `main`. It holds the iOS 1.10.0 catch-up: #94, #95, #96 (after #95), #97, #98, #99, #100, plus #47 (the `429` sentence), and profile editing #111 → #112 → #113 (iOS 0055, added 2026-11-09). This task ships them and is blocked by all eleven.
- **Out of 1.4.0:** #48 (Échanges tab: Android has no transaction sync yet), #49 (shadow styles, nothing visible).
- **Gate:** one run of `scripts/e2e-android.sh` on an emulator (account `OlivierB_test4`, one sign-in, mind the `429`). Any KO → no bundle: report it, Olivier decides.
- **Release steps,** as 1.3.0 (`7d37297`):
  - bump `versionName` / `versionCode` in `Recit_Android/app/build.gradle.kts`;
  - add `metadata/play-store/{fr-FR,en-US}/changelogs/6.txt`;
  - one commit « Version 1.4.0 of the Android app, versionCode 6 ».
- **Changelog:** against `docs/conventions/wording.md`, in the voice of `changelogs/5.txt`: what you can now do, ≤ 500 characters each, no feature numbers. Covers: an étagère in two tabs filled several books at once, « Dans les listes » on the Fiche livre, the Note privée, Nouveau livre from Recherche with or without ISBN, photos of friends, groups and authors full screen and a group's photo from its settings, the tab bar leaving pushed screens, editing one's profile, account and e-mail notifications.
- **Data safety:** #99 uploads group photos. Update the Photos row of `docs/wiki/integrations/google-play.md` (a group's photo, public, same re-encoding) and tell Olivier the Play form's Photos answer stays « Optional, App functionality » — no new data type.
- **Signing:** `./gradlew :app:bundleRelease` with the upload key from `~/.gradle/gradle.properties` (`EXLIBRIS_UPLOAD_*`). Missing → stop and say so; never an unsigned bundle passed off as ready.
- **The agent stops at the signed AAB.** Olivier uploads it to the Play Console. No Play API, no new dependency.
- **Tag:** `Android-1.4.0-#6` on the bump commit, pushed.
- **Landing:** `sprint/android-1-4-0` lands on `main` once this task closes.

## Acceptance criteria

- #47, #94, #95, #96, #97, #98, #99, #100, #111, #112 and #113 are done and merged into `sprint/android-1-4-0` before this task starts.
- `Recit_Android/app/build.gradle.kts` reads `versionCode = 6`, `versionName = "1.4.0"`; the Profil's foot on the emulator shows 1.4.0.
- `scripts/e2e-android.sh` report: every step OK, or each KO explained here and accepted by Olivier before the bundle.
- `metadata/play-store/fr-FR/changelogs/6.txt` and `en-US/changelogs/6.txt` exist, ≤ 500 characters each, no feature numbers.
- `docs/wiki/integrations/google-play.md` Photos row mentions a group's photo.
- `app-release.aab` built, `jarsigner -verify` says it is signed with the upload key; its path is in the report.
- Tag `Android-1.4.0-#6` on the bump commit, pushed.
- Nothing uploaded to Google Play by the agent.
