---
issue: 140
status: to-test
wiki: [[features/0092-entity-deep-links]], [[network]], [[features/0038-profile-behind-the-avatar]]
note: Second task of the « Deep links » sprint, on the pattern of #138 (feature 0092). Split from #65 with #141 (lists), #142 (items, étagères), #143 (signed out, open sheets), #144 (Partager).
created: 2026-11-16
---

## Context / Decisions

> Lien link.exlibris.lunabee.ovh/users/<username> et /groups/<slug> → profil du lecteur, écran du groupe ; sinon redirection vers la même page inventaire.io. Sur le modèle de #138 (DeepLink iOS/Android, AASA, assetlinks, manifest). À trancher au grill : l'app doit retrouver un compte par username (by-usernames, absent aujourd'hui) et un groupe par slug ; ouvrir dans l'onglet Réseau plutôt que Recherche (#138 ouvre tout sur Recherche). Issu du découpage de #65.

A link to a reader or a group opens their screen in Ex-libris, on the Réseau tab. Without the app, the link lands on the same page on inventaire.io.

1. **Two new paths, inventaire.io's own**:
   - `https://link.exlibris.lunabee.ovh/users/<username>` → the reader's profile;
   - `https://link.exlibris.lunabee.ovh/groups/<slug>` → the group's screen.
   - The server's catch-all `302` already sends both to inventaire.io: only the app side and the verification files change.
2. **Strict match, as in #138.** A decoded path segment reaches a query string, so each segment is a whole match or the URL is not a link:
   - username: inventaire.io's username characters only (`[A-Za-z0-9_]`, check the exact rule and length in inventaire.io's code before fixing it);
   - slug: `[a-z0-9-]+`.
3. **Looking the reader up.** `GET /api/users/by-usernames?usernames=<username>` gives the id, then the existing `UserModel.getOrFetchUsers` (`by-ids`) puts the `User` in the store, so `UserDetailView` gets the same object as everywhere else. Match the answer's key case-insensitively: inventaire.io usernames are case-insensitive.
4. **Looking the group up.** `GET /api/groups/by-slug?slug=<slug>` gives the group's `_id` → `NavigationDestination.group(id:)`. `GroupDetailView` reads the group afresh on arrival, as for a group found by name.
5. **Where it opens: the Réseau tab**, pushed alone above its root, the profile sheet closed. `TabRouter` learns to push on a tab other than Recherche: the pending link carries its tab, and each tab root consumes its own. #141 and #142 reuse it for Listes and Inventaire. Books and authors (#138) stay on Recherche.
6. **My own username → the Profil sheet** (`TabRouter.openProfile()`), as the avatar opens it (feature 0038). Nothing is pushed.
7. **Any reader or group**, friend or not, member or not: `UserDetailView` and `GroupDetailView` already show a stranger and a group found by name, with their relation and join actions.
8. **Fallback**: unknown username or slug, or no network → the same page on inventaire.io in the browser, as in #138.
9. **Server**: `scripts/deeplinks/apple-app-site-association` gains `/users/*` and `/groups/*`, then `scripts/deeplinks/deploy.sh`. `assetlinks.json` names no path: unchanged.
10. **Android**: same rules. The manifest's `intent-filter` gains `pathPrefix` `/users/` and `/groups/`; `MainScaffold` pushes on `AppTab.Network`'s stack, or calls `TabRouter.openProfile()` for my own username.
11. **Where it lives**: `DeepLink` (iOS `Model/DeepLink/`, Android `ui/navigation/DeepLink.kt`) gains a case per path; the lookups go in `UserModel` / `GroupModel` (iOS) and `UserRepository` / `GroupRepository` (Android); the mapping to a screen stays in `Features/EntityBrowser/NavigationDestination+DeepLink.swift` and `DeepLinkHandling`.

### Out of scope

- A link opened signed out, or under an open sheet: #143.
- « Partager » on a profile or a group: #144.
- A group's members, invitations or settings as link targets.

## Acceptance criteria

- `curl -s https://link.exlibris.lunabee.ovh/.well-known/apple-app-site-association` lists `/entity/*`, `/users/*` and `/groups/*`.
- `curl -i https://link.exlibris.lunabee.ovh/groups/le-club-de-lecture` → `302` to `https://inventaire.io/groups/le-club-de-lecture`.
- iOS, signed in, link touched from another app:
  - `/users/<a friend's username>` → Réseau, the friend's profile with their Inventaire;
  - `/users/<a stranger's username>` → Réseau, their profile with the « demander » action;
  - the same username in another case → the same profile;
  - `/users/<my username>` → the Profil sheet, nothing pushed;
  - `/groups/le-club-de-lecture` → Réseau, the group's screen;
  - `/users/nobody_here_xyz` and `/groups/no-such-group-xyz` → inventaire.io in Safari;
  - `/users/a%7Cb` and `/groups/a%26b` → not opened by the app.
- Android emulator, `adb shell am start -a android.intent.action.VIEW -d <link>` with the same links → the same results.
- Unit tests: the parser accepts each shape and refuses the decoded `|` / `&` cases, on both platforms; `TabRouter` pushes a pending link on the tab it names and the Profil sheet opens for my username.

## Implementation

Autopilot round 1, 2026-11-16, base `sprint/deep-links`.

- iOS
  - `Model/DeepLink/DeepLink.swift`: `.user(username:)`, `.group(slug:)`, whole-match regexes, `webURL` per case.
  - `Features/MainNavigation/PendingLink.swift` (new): destination + tab. `TabRouter`: `pendingLink: PendingLink?`, `open(_:on:)`, `consumePendingLink(for:)`, `open(linkedUser:myUserId:)` (mine → Profil sheet, compared by id).
  - `Features/MainNavigation/View+opensPendingLink.swift` (new): consume on appear + on change, used by `SearchTabView` (`.search`) and `NetworkView` (`.community`).
  - `DeepLinkHandling`: user → `UserModel.getOrFetchUser(username:)`, group → `GroupModel.groupId(slug:)`, not found → `webURL` in Safari.
  - `AppModels/User/UserModel+Username.swift`, `AppModels/Group/GroupModel+Slug.swift` (new; baseline pins both models' length). `by-usernames` reuses `UsersDTO`, key matched lowercased; `by-slug` reuses `GroupByIdDTO`.
- Android
  - `ui/navigation/DeepLink.kt`: sealed `Entity` / `User` / `Group`, `parse`, `webUrl`, `target`, `userTarget`. `LinkTarget.kt` (new): `Screen(tab, destination)` or `Profile`.
  - `TabRouter.openLink(tab)`; `MainScaffold` pushes on `stacks.getValue(target.tab)`, or opens the Profil sheet.
  - `UserRepository.getOrFetchUser(username)`, `GroupRepository.groupId(slug)`. Manifest: `pathPrefix` `/users/`, `/groups/`.
- Server: `scripts/deeplinks/apple-app-site-association` gains `/users/*`, `/groups/*`. **`deploy.sh` not run**: deploy refused to the agent, owed by the user.
- Decisions
  - Username rule from inventaire.io `server/lib/regex.ts`: `[\p{Letter}\p{Number}_]{2,20}` (any script, not ASCII); iOS matches by Unicode scalar like JS.
  - Slug rule: server `slugify` keeps letters of any script and `-`, adds `.1`, `.2` on collision → `[\p{Letter}0-9-]+(?:\.[0-9]+)?`.
  - `by-usernames` also answers a former name (`stableUsername`): "is it me" compares ids.
  - Lookup = `by-usernames` then `by-ids` (`getOrFetchUsers`), as the spec says; one request could be saved by storing the `by-usernames` answer.
  - Android keeps no pending link: every tab stack exists up front.
- Proof
  - iOS build green (SwiftLint on); DeepLinkTests + TabRouterTests 21/21.
  - Android `assembleDebug` green; DeepLinkTest 8/8, TabRouterTest 9/9.

## Review

## Verification

Agent, iPhone 17 simulator, signed in:
- ✅ launch signed in.
- ✅ `/entity/isbn:9782070360024` → Fiche livre on Recherche (router change keeps entity links there).
- ✅ `/entity/wd:Q535` → Auteur·ice on Recherche (first try fell back to Safari: `by-uris` failed once, retry fine; path unchanged by this task).
- ❌ `/users/…`, `/groups/…` not opened on screen: AASA not deployed, Safari. Covered by unit tests.
- ❌ Réseau / Profil sheet not tapped through (no UI automation). Covered by TabRouter tests.
- Android: no emulator, build + unit tests only.

## Feedback
