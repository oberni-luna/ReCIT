# A friend's profile: a Présentation tab, counts in the tabs, étagères under Inventaire

Shipped on 2026-10-30, on the branch `android-1.7.0`, in an autopilot run: two slices (PRD 0032, issues 0155
and 0156, deleted since). It reshapes the header and the pages of [0064](0064-a-friends-profile-with-tabs.md)
and [0066](0066-a-friends-profile-tabs-as-pages.md). Mock-ups: Figma `S7IvC6GvlcUFe5IgbtvQq6`, section
« Détail d'un amis » (`865:17783`), frames F1 to F6, redrawn the same day.

## What it does

- **Three tabs: « Inventaire • 540 » | « Listes • 4 » | « Présentation »** (« Inventory • 540 », « Lists • 4 »,
  « Bio » in English). Each count follows its word after a « • »; the line « 540 éléments » under the name is
  gone, and the header is shorter by it, folded or not.
- **Présentation holds the bio**, which no longer opens every page: the text in one card, left-aligned,
  selectable. Without a bio, « X n'a pas encore écrit de présentation ».
- **The étagères show under Inventaire only.** Listes and Présentation open on their content, right under the
  header.
- Someone whose books are closed to me still has no tabs: their single page keeps the bio at its top, centred,
  since there is no Présentation tab to hold it.

## Technical surface

- `UserProfileTab` gains `.presentation`; `UserPresentationTab` is its page.
- **The labels**: `UserProfileTabLabel` picks the count per tab. Inventaire counts like `UserItemCountText` —
  the store for me once synced (`OwnedInventoryTabTitle`, a `@Query`), the server's snapshot for anyone else.
  Listes counts what the Listes tab shows, filtered the same way (`UserListsTabTitle`); while the first fetch
  runs with nothing stored, it says « Listes » alone rather than a wrong 0, so the screen hands its
  `UserListsTab.Load` down through the header to the picker. VoiceOver reads « Inventaire, 540 éléments »
  and « Listes, 4 » instead of the bullet.
- **The picker**: labels in `action200` (Open Sans SemiBold 12, after a first build in `action300`, 17), capsules
  at `.sMedium` (12 pt) of horizontal padding and `.zero` between them, as the Figma draws them — three labels
  with a three-figure count make 291 pt. The labels keep to one line and may shrink to 70 % rather than wrap.
- **The fold over three pages**: `ProfileHeaderCollapse.progress(of:pagePosition:)` takes one offset per page and
  blends the two the pager stands between, through `ProfileHeaderCollapse.blend(_:at:)`, which
  `ProfileScrollOffset.pull` uses too. The pager itself already went by `UserProfileTab.allCases`. The fold's
  distance loses the count's line.
- `UserProfilePage` takes `showsBio` (the no-tabs page only); `UserDetailView` passes
  `showsShelves: page == .inventory`.
- Six strings: `user.tab.inventory %lld`, `user.tab.inventory.accessibility %lld`, `user.tab.lists %lld`,
  `user.tab.lists.accessibility %lld`, `user.tab.presentation`, `user.presentation.empty %@`.

## Tests

`ProfileHeaderCollapseTests`: the two-page blend rewritten on the array, a three-page case and `blend` itself.

## Not done, not verified

- **Built and installed on a phone, not looked at on a screen by this run**: the three capsules' fit, the
  capsule sliding over three pages, Présentation with and without a bio, the largest text sizes, VoiceOver.
- A tab chosen two pages away (Inventaire → Présentation) turns straight to it; the capsule glides across
  Listes on the way.
- **The e2e scenario** does not play this screen (one account, no friend).
- **Android**: not ported.
- `user.segment`'s comment in the string catalog still says « Inventory | Lists ».
