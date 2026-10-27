# Ex-libris on Google Play

What the Play Console asks for, and the answers the Android app's code supports. Read from
`Recit_Android/` on 2026-10-23, at 1.0.0 (versionCode 1). Re-read the code before answering again
for a later version: a new endpoint or SDK changes the form.

## The app

| Field | Value |
|---|---|
| Account | Lunabee Studio (organisation — no 12-tester closed test required) |
| Package name | `studio.lunabee.nouveaurecit.android` (permanent once uploaded) |
| Debug package | `studio.lunabee.nouveaurecit.android.dev` |
| Name | Ex-libris |
| Default language | en-US for the listing, with a fr-FR translation; the app itself exists only in French |
| Price | Free, no ads, no in-app purchase |
| Signing | Play App Signing; the upload key's path and passwords are read from `~/.gradle/gradle.properties` (`EXLIBRIS_UPLOAD_*`, see `app/build.gradle.kts`) |

The listing — texts, icon, feature graphic, screenshots — is under
[`metadata/play-store/`](../../metadata/play-store), in fastlane `supply`'s layout.

## Data safety

### What leaves the device

Everything the app sends goes to `https://inventaire.io`, over HTTPS (no cleartext config,
`minSdk 28`). An Ex-libris account *is* an inventaire.io account, as the welcome screen says.
Images are also fetched from `commons.wikimedia.org`, without cookies; nothing about the user is
sent there but the IP and the user agent.

| Play data type | What it is in the app | Required? | Purpose |
|---|---|---|---|
| Personal info › Email address | Sign-up (`POST /api/auth/signup`), password reset | Required | Account management |
| Personal info › User IDs | The username, at sign-up and sign-in | Required | Account management, app functionality |
| Photos and videos › Photos | A book's cover, photographed when creating a book inventaire.io lacks (`POST /api/images/upload`). Re-encoded JPEG, 1600 px max, EXIF (GPS included) dropped. Becomes a public image of the book | Optional | App functionality |
| App activity › Other user-generated content | Inventory items (book, transaction, visibility, free-text details), étagères, lists and their comments, created books and authors | Optional | App functionality |
| App activity › In-app search history | What the user types in Recherche, sent to `GET /api/search` | Optional | App functionality |
| App activity › Other actions | Friend requests, accepting, refusing, removing a friend (`/api/relations/*`) | Optional | App functionality |
| App info and performance › Diagnostics | Usage and error telemetry sent to Google by the bundled ML Kit barcode scanner (see below) | Required | Analytics (Google's own) |

Not collected: location (the app reads a friend's position from the server but never sends one,
and asks no location permission), contacts, financial info, device IDs, advertising ID. Passwords
are sent at sign-in and sign-up and are not a Play data type.

**Shared?** Play counts as *sharing* a transfer to a third party. inventaire.io is not Lunabee's
processor: it is the service the user signs up to, knowingly, from the welcome screen. That reads
as a user-initiated transfer, which Play exempts — but it is Lunabee's call, and the conservative
answer is to declare the rows above as shared with inventaire.io too.

**ML Kit.** `com.google.mlkit:barcode-scanning` is the bundled, on-device model: no camera image
leaves the device. Its merged manifest still brings Google's `datatransport` telemetry. Check
Google's current ML Kit data-disclosure page before submitting, and declare what it lists.

### Security practices

- Encrypted in transit: **yes**.
- Users can ask for their data to be deleted: **yes** — Profil › Supprimer mon compte calls
  `DELETE /api/user`, then wipes the local store. Play also wants a **web URL** where deletion can
  be requested without the app; the code has none.
- On the device: the session cookie is encrypted with AES-256-GCM under an Android Keystore key;
  the Room database is not encrypted; `allowBackup` is off.

### Permissions

`INTERNET`, `CAMERA` (asked at runtime when the scanner opens; `uses-feature camera` not required),
plus `ACCESS_NETWORK_STATE` from ML Kit. Cover photos go through the system camera app and the
Photo Picker, which need no permission.

## App content

| Form | Answer |
|---|---|
| Privacy policy | A real policy page is needed. `https://inventaire.io/`, the App Store's, is a home page, not a policy |
| Ads | No ads |
| App access | Every feature but the welcome screen needs an account: give the reviewers a dedicated test account's username and password |
| Content rating | Users interact and share content (friends, public inventories); no violence, no gambling |
| Target audience | Not designed for children |
| Account deletion | In the app (above), and the web URL still owed |
| Government, financial, health, news | No |
