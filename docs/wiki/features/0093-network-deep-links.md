# Links to a reader or a group, on link.exlibris.lunabee.ovh

Shipped on 2026-11-16, iOS and Android (issue #140, PR #147, second task of the « Deep links » sprint, after
[0092](0092-entity-deep-links.md)). `https://link.exlibris.lunabee.ovh/users/<username>` opens the reader's profile and
`/groups/<slug>` the group's screen, on the Réseau tab; without the app, the server's `302` lands on the same page on
inventaire.io. Tested on Olivier's iPhone; Android built and unit-tested, never run on an emulator.

## What it does

- **Which links.** inventaire.io's own paths, one segment each, whole-matched before any request:
  - username: `[\p{Letter}\p{Number}_]{2,20}`, inventaire.io's rule (`server/lib/regex.ts`), any script;
  - slug: `[\p{Letter}0-9-]+(?:\.[0-9]+)?`, what its `slugify` produces, `.1`, `.2`… on a collision.
- **Which screen.**
  - A reader, friend or not → `UserDetailView`, pushed alone above Réseau's root. Usernames are case-insensitive.
  - My own username → the Profil sheet, nothing pushed. Me is decided by id: `by-usernames` also answers a former
    name (`stableUsername`).
  - A group, member or not → `GroupDetailView`, which reads the group afresh.
  - Unknown name or slug, or no network → inventaire.io's page in the browser.
- **Books and authors** (0092) stay on Recherche: each kind of link has its tab.

## Technical surface

- **Server** — `scripts/deeplinks/apple-app-site-association` gains `/users/*` and `/groups/*`; `assetlinks.json` names
  no path. Deployed with `deploy.sh`.
- **iOS**
  - `DeepLink`: `.user(username:)`, `.group(slug:)`.
  - `UserModel+Username.swift`: `getOrFetchUser(username:)` → `by-usernames` for the id, then `getOrFetchUsers`
    (`by-ids`) to store it. `GroupModel+Slug.swift`: `groupId(slug:)` → `by-slug`, decoded with `GroupByIdDTO`.
  - `TabRouter`: `pendingLink: PendingLink?` (destination + tab), `open(_:on:)`, `consumePendingLink(for:)`,
    `open(linkedUser:myUserId:)`. Each tab root applies `.opensPendingLink(on:path:)` and takes only its own links.
- **Android** — `DeepLink` becomes a sealed type (`Entity`, `User`, `Group`) resolving to a `LinkTarget`
  (`Screen(tab, destination)` or `Profile`); `MainScaffold` pushes on that tab's stack.
  `UserRepository.getOrFetchUser(username)`, `GroupRepository.groupId(slug)`.
- **Tests** — `DeepLinkTests`, `TabRouterTests`; Android `DeepLinkTest`, `TabRouterTest`.

## Pitfalls

- **A new path in the AASA is not live for a while.** iOS reads the file through Apple's CDN, cached up to 6 h
  (`max-age=21600`), and keeps its own copy until a reinstall or a periodic refresh. Right after a deploy, a new path
  goes to Safari while `/entity/` keeps opening the app. To test at once: the developer-mode entitlement
  (`applinks:…?mode=developer`, added in #143), Réglages › Développeur › Associated Domains Development, delete and
  reinstall. The simulator's `swcd` can stay stuck on the old file even then.

## Known limits

- My own link on a cold launch, before `syncMyUser` returns, and a refused URL on the link domain: fixed in #143.
- A group's members, invitations or settings are not link targets.
