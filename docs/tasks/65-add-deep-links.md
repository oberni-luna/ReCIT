---
issue: 65
status: todo
wiki: [[architecture]], [[features/0012-end-to-end-scenario]], [[features/0031-android-app]]
note: Part of #62 (Ex-libris backend umbrella). Blocked by #74 (backend lists — the last object type linked) and #76 (entity pages read through the relay). The public domain comes with the hosting (#62): every URL here is built from a setting.
created: 2026-11-07
---

## Context / Decisions

> links to books, readers, shelves, lists, works, authors
>
> Je veux pouvoir faire des deeplinks pour les items, les users, les étagères, les listes, les "entities" (oeuvre et auteur).

A web link to a book copy, a reader, an étagère, a list, a work or an author opens the right screen in Ex-libris, on iOS and Android, and can be shared from the app.

1. **Universal web links**: `https://<public domain>/<path>`, opened by the app when installed (iOS Universal Links, Android App Links), else served by the backend as a small page. The domain is `PUBLIC_BASE_URL` (#70) on the backend and a build setting in each app; until the hosting is chosen, a placeholder domain and the local backend.
2. **inventaire.io's paths**, so an inventaire.io link pasted as is also opens for works and authors:
   - `/items/<id>` — a reader's copy → the Fiche livre anchored on that copy;
   - `/users/<username>` — a reader's profile (mine → my Profil);
   - `/shelves/<id>` — an étagère;
   - `/lists/<id>` — a list;
   - `/entity/<uri>` — a work or an author (an edition opens the Fiche livre of that edition), `wd:` or `inv:` URIs.
3. **Without the app**: the backend serves `GET` on those paths as one minimal HTML page — title, cover or picture, one sentence, App Store and Google Play buttons, Open Graph tags for link previews. Only for what an anonymous visitor may see (`public` copies, étagères and lists, every reader's public profile, every entity); anything else answers the same page saying « Ouvrez ce lien dans Ex-libris », revealing nothing. Pages are in the visitor's `Accept-Language` (French or English), wording per `wording.md`.
4. **Verification files**: the backend serves `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` for those paths; the app identifiers and signing fingerprints come from configuration.
5. **In the app**: a link routes through one parser to a `NavigationDestination` (iOS) / Navigation 3 key (Android), pushed on the right tab's stack (books and entities → Recherche, readers → Réseau, lists → Listes, étagères → Inventaire, or the owner's profile for someone else's). Signed out, the link is kept, the welcome / sign-in flow runs, then the screen opens. An object the reader may not see, or that no longer exists → a screen « Ce contenu n'est pas visible pour vous » with a way back.
6. **Sharing**: « Partager » in the « … » menus of the Fiche livre (shares the copy when it is mine or a friend's, else the edition), the work, the author, a reader's profile, an étagère and a list opens the system share sheet with the link and the object's name.
7. **Both apps** in this task: iOS (`Features/DeepLinks/`, `onOpenURL` + associated domains entitlement) and Android (`deeplinks` package, intent filters with `autoVerify`). Backend: a `links` package for the pages and well-known files.

### Out of scope

- Links to Échanges, groups, search results.
- Short links, QR codes, analytics.
- A full web reader of Ex-libris.

## Acceptance criteria

- `GET /items/<id>` of a public copy, no session → 200 HTML with the book's title, cover, store buttons and `og:title` / `og:image`; of a friends-only copy → 200 HTML with « Ouvrez ce lien dans Ex-libris » and no title.
- `GET /users/<username>`, `/shelves/<id>`, `/lists/<id>`, `/entity/wd:Q190192` answer their page; an unknown id → the same neutral page, status 404.
- `GET /.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` → JSON listing the five paths and the configured app identifiers.
- iOS simulator, `xcrun simctl openurl booted <link>` for each of the five kinds → the app opens on the right screen; signed out → after signing in, the same screen opens.
- Android emulator, `adb shell am start -a android.intent.action.VIEW -d <link>` for each of the five kinds → the right screen.
- A link to a friends-only copy opened by a stranger → « Ce contenu n'est pas visible pour vous ».
- « Partager » on a Fiche livre, a profile, an étagère and a list opens the share sheet with a link whose path matches the object.
- An inventaire.io work link (`https://inventaire.io/entity/wd:Q190192`) parsed by the app's link parser → the work screen (unit test).
- Each backend route and each parser case has a test.
