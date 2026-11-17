---
issue: 145
status: to-close
wiki: [[features/0092-entity-deep-links]], [[android]]
note: Last task of the « Deep links » sprint. Criterion left open by #138: assetlinks.json carries only the upload and debug keys.
created: 2026-11-16
---

## Context / Decisions

> Play Store build opens Ex-libris links. Criterion left open by #138: assetlinks.json carries only the upload and debug keys. Olivier reads the app signing key's SHA-256 in Play Console › Intégrité de l'app › Signature de l'app, it goes into scripts/deeplinks/assetlinks.json, then scripts/deeplinks/deploy.sh. Check: Google's statements API lists it; a Play-installed build opens a link.

Google re-signs every Play build with its app signing key, so a Play-installed Ex-libris is not verified for `link.exlibris.lunabee.ovh` until `assetlinks.json` names that key.

1. **The key** — app signing key certificate, SHA-256, from Play Console (given by Olivier on 2026-11-16):
   `4E:C2:D5:05:6C:C4:DD:32:56:02:3A:FE:33:38:E2:10:C4:F9:6A:D7:1F:C4:A0:94:CB:B3:EE:5D:FD:64:69:FD`.
2. **Added, not replacing** — `studio.lunabee.exlibris.android` lists it beside the upload key (`74:6B:…`), which still signs release builds installed outside Play. The `.dev` entry is unchanged.
3. **Deploy** — `scripts/deeplinks/deploy.sh` after the edit (run by Olivier: agent deploys are refused).
4. **Docs** — feature 0092's « Play build not verified » pitfall and CLAUDE.md's « Play signing key not yet in `assetlinks.json` (#145) » are updated.

### Out of scope

- Any app code: the manifest's `autoVerify` intent filter already covers every path.

## Acceptance criteria

- `scripts/deeplinks/assetlinks.json` is valid JSON and lists, for `studio.lunabee.exlibris.android`, both `4E:C2:…:69:FD` and `74:6B:…:0E:AC`.
- After `deploy.sh`: `curl -s https://link.exlibris.lunabee.ovh/.well-known/assetlinks.json` shows the new fingerprint.
- `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://link.exlibris.lunabee.ovh&relation=delegate_permission/common.handle_all_urls` lists the new fingerprint for `studio.lunabee.exlibris.android`.
- A Play-installed build (internal testing is enough): `adb shell pm get-app-links studio.lunabee.exlibris.android` reports `link.exlibris.lunabee.ovh: verified`, and a link touched in another app opens Ex-libris.

## Implementation

Round 1, 2026-11-16, base `sprint/deep-links`.

- `scripts/deeplinks/assetlinks.json`: `4E:C2:…:69:FD` (Play app signing key) appended to `studio.lunabee.exlibris.android`'s `sha256_cert_fingerprints`, after the upload key; `.dev` unchanged.
- Proof: `python3 -m json.tool` passes.
- Not deployed: `scripts/deeplinks/deploy.sh` is Olivier's. Docs (0092 pitfall, CLAUDE.md line) at close.

## Review

### Round validation — 2026-11-16

LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓. Clean: valid JSON, Digital Asset Links format, three uppercase 32-byte fingerprints, the new one byte for byte, upload key kept, `.dev` unchanged. The Play-build criterion deferred by agreement, not a finding.

## Verification

- ✅ Olivier ran `deploy.sh`; the live `assetlinks.json` holds `4E:C2…` (PM `curl`).
- ✅ Google's statements API lists `74:6B` and `4E:C2` for `studio.lunabee.exlibris.android`, `00:CE` for `.dev` (PM + Olivier).
- ⏸ Play-installed build: **deferred to the first Play release that ships the sprint.** Play's 1.4.0 on Olivier's Pixel 9 Pro (installer `com.android.vending`) declares no link domain: `pm get-app-links` answers nothing, the intent filter came with #138, unreleased.

## Feedback
