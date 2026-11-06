---
issue: 42
status: todo
wiki: [[android]], [[integrations/google-play]]
note: "Je veux publier Ex-Libris pour les tel Android qui n’ont pas le Play Store, en particulier ceux qui ont Murena."
created: 2026-11-06
---

## Context / Decisions

> Je veux publier Ex-Libris pour les tel Android qui n’ont pas le Play Store, en particulier ceux qui ont Murena.

- **Channel: App Lounge, through the existing Google Play listing.** Murena's App Lounge lists Google Play apps through anonymous access. The Ex-libris listing (`studio.lunabee.exlibris.android`, Lunabee Studio) is public, so App Lounge already offers it. Nothing new gets published.
  - Not chosen: an APK on GitHub Releases, the official F-Droid repository, or a Lunabee F-Droid repository. F-Droid would need a free licence on the repository and a replacement for ML Kit, which is proprietary.
- **What is left is proof that the app runs without Google Mobile Services (GMS).**
- **Device: an Android emulator on an AOSP `default` system image (arm64), with no Google service at all.** This Mac only has `google_apis` / `google_apis_playstore` images, so one must be downloaded with `sdkmanager`.
  - It has no microG, which makes it harder than /e/OS. Passing there means passing on Murena.
  - No real Murena device in this task.
- **Proof, part 1:** one run of `scripts/e2e-android.sh` on that AVD, with account `OlivierB_test4` and a single sign-in. inventaire.io rate-limits sign-ins (`429`): wait, never retry at once.
- **Proof, part 2: ML Kit decodes a real barcode on the same AVD.** The e2e scanner reads its barcodes through `E2EHooks`, so the e2e run does not exercise ML Kit.
  - The barcode is a real ISBN EAN-13 image, shown through the emulator's virtual camera scene or passed as a bitmap to ML Kit in an instrumented check.
  - `com.google.mlkit:barcode-scanning` 17.3.0 is the bundled model and is expected to work without GMS. That is not yet proven.
- **If something breaks without GMS:**
  - A fix of a few files is done in this task.
  - A larger change, such as replacing ML Kit with ZXing, becomes a separate `draft` task. This task then closes on the recorded finding.
- **Trackers: measure and record, change nothing.**
  - App Lounge shows a privacy score based on Exodus Privacy.
  - ML Kit's merged manifest brings Google's `datatransport` telemetry.
  - Read the Exodus Privacy report for `studio.lunabee.exlibris.android`, or request its analysis by package name. Record the score and the trackers it lists.
  - A tracker found becomes a separate `draft` task.
- **Wiki:** a new page, `docs/wiki/integrations/no-gms-phones.md`, holds the following:
  - the channel (App Lounge through Play);
  - how to create the AVD without GMS;
  - the result of the e2e run and of the ML Kit check;
  - the Exodus result.
  - The `integrations/` line in `docs/wiki/index.md` names it.
- **Base branch: `main`.** The checkout was on the local test branch `wa/autopilot-2026-11-06-test`, which is never forked from.

## Acceptance criteria

- [ ] An AVD on an AOSP `default` arm64 image exists. `adb shell pm list packages | grep -i gms` on it returns nothing.
- [ ] `scripts/e2e-android.sh` ran once on that AVD. Its report is linked here: every step OK, or each KO explained here and marked as GMS-related or not.
- [ ] On that AVD, the app's scanner (or an instrumented ML Kit call) turns a real ISBN EAN-13 barcode image into its 13 digits.
- [ ] Every GMS-related KO is fixed here, or recorded as a new `draft` task whose number is written here.
- [ ] The Exodus Privacy score and tracker list for `studio.lunabee.exlibris.android` are recorded in the wiki page. Any tracker found has its own `draft` task.
- [ ] `docs/wiki/integrations/no-gms-phones.md` exists, and `docs/wiki/index.md` names it under `integrations/`.
- [ ] Nothing is uploaded to Google Play and nothing is published elsewhere.

## Implementation

## Review

## Verification

## Feedback
