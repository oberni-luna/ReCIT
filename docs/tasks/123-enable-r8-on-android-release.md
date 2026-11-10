---
issue: 123
status: todo
wiki: [[features/0031-android-app]], [[features/0065-android-end-to-end-scenario]]
note: Play Console on the production release — « L'optimisation du code DEX est inférieure à notre seuil … Obscurcissement (0 %) »
created: 2026-11-10
---

## Context / Decisions

> La console Play Store affiche ce message à propos de la version de prod : « L'optimisation du code
> DEX est inférieure à notre seuil. Améliorez vos pourcentages dans les catégories suivantes :
> Obscurcissement (0 %) ». Comment on peut le corriger ?

- **Cause**: `Recit_Android/app/build.gradle.kts` sets `isMinifyEnabled = false` on `release`, so
  R8 never runs: the DEX ships unshrunk, unoptimised and unobfuscated.
- **Fix**: on `release` only, `isMinifyEnabled = true`, `isShrinkResources = true`,
  `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`.
  `debug` stays unminified — the e2e module (`Recit_Android/e2e/`) targets the debug app.
- **`proguard-rules.pro`** created in `Recit_Android/app/`. Start empty of keep rules: the app code
  has no reflection of its own (only `AppDatabase::class.java` for Room), and every library ships
  its consumer rules (kotlinx.serialization, Room, OkHttp, Coil, CameraX, ML Kit, Navigation 3).
  Add a rule only for a break actually seen in the minified build, each with a comment saying why.
  No blanket `-keep class studio.lunabee.** { *; }` — it would bring obfuscation back to 0 %.
- **Mapping file**: nothing to do. AGP bundles `mapping.txt` into the AAB and the Play Console
  de-obfuscates crash reports with it.
- **Version**: 1.4.0 → **1.4.1**, `versionCode` 6 → 7. The 1.4.0 sprint (`sprint/android-1-4-0`)
  is already merged into `main`, so this branch starts from `main`, not from `branch.base: current`.
- **Proof**: a manual pass on the minified release installed on the emulator, by the implementer.
  R8 breaks JSON decoding silently, without a compile error, so the pass walks every screen that
  decodes a server answer. `scripts/e2e-android.sh` is not run against release (it drives debug).
  The upload key is in `~/.gradle/gradle.properties` on this Mac; without it, sign the APK with the
  debug key for the pass.

## Acceptance criteria

- `./gradlew :app:bundleRelease` succeeds and writes
  `app/build/outputs/mapping/release/mapping.txt`.
- In the release DEX, app classes under `studio.lunabee.nouveaurecit` are renamed (checked with
  `apkanalyzer dex packages` or the mapping file).
- `./gradlew :app:assembleDebug` and the unit tests still pass; the debug build is not minified.
- `versionName` is `1.4.1` and `versionCode` is `7`.
- On the emulator, the minified release: signs in, restarts and stays signed in, syncs the
  inventory and shows its books, searches inventaire.io and opens a book's screen, scans an ISBN
  from the scanner, opens the Lists tab and a list, opens Réseau with friends and groups, opens
  a friend's profile. No crash and no empty screen where the debug build shows data.

## Implementation

## Review

## Verification

## Feedback
