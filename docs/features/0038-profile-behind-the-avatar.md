# 0038 — The Profil leaves the tab bar, behind my avatar

Shipped on 2026-10-21, in one commit, on autopilot: no PRD, no issues, no mockup. The request was the
owner's, in a sentence: take the Profil tab out of the bar, put a round avatar at the top left of
Inventaire, Listes and Réseau, open the profile as a sheet; the tab's icon in a round Liquid Glass
button when there is no picture, the picture when there is one.

## What it does

**The tab bar has three tabs and the search**: Inventaire, Listes, Réseau, then the magnifier in its
own pill. The Profil is no longer one of the places a reader goes back to; it is the account, reached
from wherever the books are.

**At the top left of Inventaire, Listes and Réseau**, a round button. With no picture on the account,
it is the Profil tab's old icon (`person`) in the navigation bar's own glass button, the same circle
as the « + » on the right. With a picture, the picture fills a circle of the same size, 44 pt.

**A tap opens the profile as a sheet**, at full height, with everything it had as a tab — the coffee
card, the account, the transactions, À propos, sign-out, account deletion, the version — and a
« Fermer » button at the top left. Swiping it down closes it too. Pushes inside it (a transaction,
À propos, account deletion) stay inside it.

Signing out or deleting the account from the sheet ends the session as before: `RootView` replaces
the tab view with the welcome screen, and the sheet goes with it.

## Technical surface

- **`MainTabView.TabConfig.profile`** — deleted, with its icon, title and view. `tab.profile` and
  `nav.settings` stay in the catalogue, unused.
- **`TabRouter.isProfilePresented`** and **`openProfile()`** — the sheet's flag lives in the router
  because three tabs raise it. Settable from outside, since the sheet's swipe-down writes it back
  through `$router.isProfilePresented`. `openSearch()` and `openNetwork()` lower it: a request for
  another tab never changes the tab behind the profile. Two tests in `TabRouterTests`, nine in all.
- **`ProfileToolbarItem`** (`Features/Profile/`) — a `ToolbarContent`, `.topBarLeading`, put in the
  toolbar of `ShelvesView`, `EntityListView` and `NetworkView`. Without a picture, a plain
  `Button("nav.profile", systemImage: "person")`. With one, a `.plain` button around `ProfileAvatar`,
  labelled `nav.profile` for VoiceOver, and `.sharedBackgroundVisibility(.hidden)` so the bar's glass
  does not ring the picture. Both carry `e2e.profile.open`.
- **`ProfileAvatar`** — the icon under the picture, in a `glassEffect(.regular.interactive(), in:
  .circle)` of its own: a picture loading slowly, or failing, falls back to the icon in glass rather
  than to an empty hole. `CachedAsyncImage` draws nothing at all on failure, which is why the icon is
  underneath rather than its placeholder.
- **`ThumbnailSize.toolbar`** — 44 pt, a glass button's diameter in an iOS 26 navigation bar. `.small`
  (36 pt) read as visibly smaller than the « + » beside it.
- **`ProfileSheet`** — `ProfileView` with a `ShelfFocusModel` and a `ShelfFocusOverlayView` of its own.
  A transaction leads to a reader and a reader to their étagères, which read the focus; the tab
  view's overlay would be drawn under the sheet. The sheet is attached inside `MainTabView`'s two
  `.environment` injections so it inherits the router.
- **`ProfileView`** — a `cancellationAction` « Fermer » (`action.close`, `xmark`,
  `e2e.profile.close`) on its root.
- **End-to-end** — `E2EDriver.Tab.settings` is gone. The sign-out step opens the inventory, taps
  `e2e.profile.open` until `e2e.profile.logout` is there, then signs out as before.

Nothing is persisted and nothing talks to the server.

## Notable decisions

- **The case is deleted, not hidden.** `isHidden` is how the transactions tab waits for its turn;
  the Profil is not waiting to come back.
- **No avatar on Recherche.** The request named three screens; the search tab's bar is the field
  itself once selected, and an avatar there would be the one thing on it not about searching.
- **The account's picture comes from `userModel.myUser?.avatarURLValue`**, already an absolute URL.
  No new request; a picture changed on inventaire.io shows at the next user sync.
- **The glass of the bar, not a hand-made one, for the icon face.** It is what the request calls a
  round Liquid Glass button, and it matches the trailing buttons exactly. Only the picture face
  draws its own glass, because it has to hide the bar's.

## Owed, and known

- **`scripts/e2e.sh` has not been run against this.** `ReCIT_iOSE2E` builds with the rewritten
  sign-out step.
- **Seen on the iPhone 17 simulator only**, signed in: the icon on Inventaire, the sheet, a
  transaction pushed inside it; the picture face on the three tabs, with a URL forced in the code for
  the occasion and taken out before the commit — the test account has no picture. Never with a real
  account picture, never in dark mode, never with VoiceOver.
- **The debug section's buttons that raise a full-screen flow** (onboarding, sorting) were written for
  a tab and have not been tried from the sheet; a cover raised under a sheet may not show. Debug
  builds only.
- **Figma** — D-R7 in `docs/design-system/figma-library.md`: the mocked tab bar still has a Profil
  tab, and no screen has the avatar.
- **Android** (`Recit_Android/`) followed in [0041](0041-android-catches-up-with-ios.md), with an overlay that cannot be swiped down.
