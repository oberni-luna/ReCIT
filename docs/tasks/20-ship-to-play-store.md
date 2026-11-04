---
issue: 20
status: todo
wiki: [[android]], [[testing]]
note: grilled with #19 (iOS 1.9.0); split into #21, #22, #23 on 2026-11-04
created: 2026-11-04
---

## Context / Decisions

> rattraper le retard de la version Android en préparant une nouvelle version avec : les forms des data bibliographic, le nouvel écran des users et le nouvel écran des listes.

- **Version 1.3.0, versionCode 5**, following Android's own numbering (1.2.0, code 4 at `b9aaa2d`), independent of iOS.
- **Sprint « Android 1.3.0 »** holds the work, split in three:
  - #21 Add friend profile tabs: iOS 0064, 0066, 0067. It also brings in the list creator model, scoped sync and the read-only list.
  - #22 Add network lists and Présentation: iOS 0068, 0073, 0075's pager. Blocked by #21.
  - #23 Add work and author editing: iOS 0057 + 0054.
  - This task ships them and is blocked by all three.
- **Scope decided in the grill:**
  - No Wikidata (0070) in this version: iOS never linked an account or saved for real.
  - The tabs use a simple sliding capsule, not 0075's `LensTabPicker`. The lens is a later task.
- **Gate:** one run of `scripts/e2e-android.sh` on an emulator (account `OlivierB_test4`, one sign-in, mind the `429`). Any KO → no bundle: report it, Olivier decides.
- **Release steps** follow `b9aaa2d` and `993d86b`:
  - bump `versionName` / `versionCode` in `Recit_Android/app/build.gradle.kts`;
  - add `metadata/play-store/{fr-FR,en-US}/changelogs/5.txt`;
  - one commit « Version 1.3.0 of the Android app, versionCode 5 ».
- **Changelog:** written against `docs/conventions/wording.md`, in the voice of `changelogs/4.txt`: what you can now do, ≤ 500 characters (Play's limit).
- **Signing:** `./gradlew :app:bundleRelease` with the upload key from `~/.gradle/gradle.properties` (`EXLIBRIS_UPLOAD_*`). Missing → stop and say so; never an unsigned bundle passed off as ready.
- **The agent stops at the signed AAB.** Olivier uploads it to the Play Console. No Play API, no new dependency.
- **Tag:** `Android-1.3.0-#5` on the bump commit. This is new: no Android tag exists yet, the name mirrors iOS's `Version-1.9.0-#20`.
- **Landing:** the sprint branch `sprint/android-1-3-0` lands on `main` once this task closes.

## Acceptance criteria

- [ ] #21, #22 and #23 are done and merged into `sprint/android-1-3-0` before this task starts
- [ ] `Recit_Android/app/build.gradle.kts` reads `versionCode = 5`, `versionName = "1.3.0"`; the Profil's foot on the emulator shows 1.3.0
- [ ] `scripts/e2e-android.sh` report: every step OK, or each KO explained here and accepted by Olivier before the bundle
- [ ] `metadata/play-store/fr-FR/changelogs/5.txt` and `en-US/changelogs/5.txt` exist, ≤ 500 characters each, no feature numbers
- [ ] `app-release.aab` built, `jarsigner -verify` says it is signed with the upload key; its path is in the report
- [ ] Tag `Android-1.3.0-#5` on the bump commit, pushed
- [ ] Nothing uploaded to Google Play by the agent

## Implementation

## Review

## Verification

## Feedback
