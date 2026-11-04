---
issue: 19
status: todo
wiki: [[architecture]], [[lists]], [[network]], [[testing]]
note: grilled with #20 (Android 1.3.0) from one request on 2026-11-04
created: 2026-11-04
---

## Context / Decisions

> envoyer une nouvelle version iOS (1.9.0) ; rattraper le retard Android en préparant une nouvelle version avec les forms des données bibliographiques, le nouvel écran des users et le nouvel écran des listes.

- **1.8.0 is live on the App Store** (build 19, commit `e1cfb4c`), but was never tagged. This task tags it `Version-1.8.0-#19` after the fact, in the style of `Version-1.7.0-#18`.
- **1.9.0 ships everything after `e1cfb4c`:** features 0068 (« Dans mon réseau »), 0069 (inventory row long-press card), 0070 (Wikidata account and editing), 0071 (a request names what it asks for), 0073 (a list's Présentation tab), 0074 (list visibility in its form), 0075 (lens tabs, a list's pager). Also the SwiftLint build plugin (no app change).
- **Build:** `MARKETING_VERSION = 1.9.0`, `CURRENT_PROJECT_VERSION = 20`. One commit « Version 1.9.0, build 20 », like `e1cfb4c`.
- **Gate before uploading:** one run of `scripts/e2e.sh` (account `OlivierB_test4` through `E2E_USERNAME`; one sign-in, mind the `429`), plus a simulator pass (iPhone 17, light and dark) on the screens never seen running: the Lists tab with « Dans mon réseau » (0068), a list's Livres | Présentation pages and lens tabs (0073, 0075), a friend's profile tabs. Any KO or visible defect → no upload: report it, Olivier decides.
- **0070 is not in the gate:** linking a Wikidata account cannot be tried without a real Wikimedia account. It ships as written, unproven, as its feature doc says.
- **The agent stops at the upload.** Archive, export, upload to App Store Connect app **6795534325** (Ex-libris; 6773353876 is another app). Olivier submits for review himself. Nothing submitted, no phased release touched.
- **« Nouveautés »:** `whatsNew` in `metadata/app-store/localizations/{fr-FR,en-US}.json`, written against `docs/conventions/wording.md`, in the style of the Play changelogs (`metadata/play-store/*/changelogs/4.txt`): what you can now do, no feature numbers.
- Out of scope: Android (#20), App Store screenshots, description and keywords.

## Acceptance criteria

- [ ] `xcodebuild -showBuildSettings` for `ReCIT_iOS` (Debug and Release) reads `MARKETING_VERSION = 1.9.0`, `CURRENT_PROJECT_VERSION = 20`; the Profil's foot shows « Version 1.9.0 (20) »
- [ ] `scripts/e2e.sh` report: every step OK, or each KO explained in this file and accepted by Olivier before the upload
- [ ] Simulator screenshots in the report, light and dark: Lists tab with a « Dans mon réseau » section; a list swiped from Livres to Présentation; a friend's profile on each tab
- [ ] `whatsNew` filled in `fr-FR.json` and `en-US.json`, ≤ 4 sentences each, no « 0068 »-style numbers
- [ ] Build 20 uploaded to App Store Connect app 6795534325 and shown in TestFlight (processing or ready)
- [ ] Tags `Version-1.8.0-#19` on `e1cfb4c` and `Version-1.9.0-#20` on the bump commit, pushed
- [ ] Nothing submitted for App Review

## Implementation

## Review

## Verification

## Feedback
