# A friend's profile: their picture at the head, their étagères, Inventaire | Listes

Shipped on 2026-10-30, on the branch `android-1.7.0`, in an autopilot run: three slices (PRD 0031, issues 0152
to 0154, deleted since). It reshapes the profile of [0018](0018-reader-network.md) and
[0019](0019-a-friends-shared-shelves.md), and opens the lists of [0060](0060-list-cover-flow.md) to friends.
Mock-ups: Figma `S7IvC6GvlcUFe5IgbtvQq6`, section « Détail d'un amis » (`865:17783`), frames F1 to F5.

## What it does

The profile no longer opens under a navigation title that repeats the name. It is shaped like the **Contacts card
of Messages**:

- **a header held just under the navigation bar** — their picture at 96 pt (the person glyph on a
  grey disc when they have none), their name large (`title200`), how many books they hold, and **two tabs,
  Inventaire | Listes**: two words, the selected one in a glass capsule (a material one before iOS 26) that slides
  to the other. The bar keeps the way back and « … » (remove from the network, report) and shows no title;
- **as the page scrolls, the header folds**: the picture shrinks to 48 pt and rises into the bar's row, centred between the back button and « … », the name to
  the size of an inline navigation bar's title (`title50`), 8 pt under the picture and 16 pt over the tab labels,
  the count fades out; the tabs stay. It **never rests half folded** — a scroll that ends
  inside the fold is carried to the nearer end. Once folded, the page passes under it, behind the bars' material
  (`.bar`), which stops dead on a hairline at the header's foot. A pull past the top — or the bounce of a fling back
  up — takes the header down with the page, so no gap opens under it;
- **their bio and their étagères** (the carousel of 0019, absent when they share none, F4) scroll away under it,
  as the Contacts card's call buttons do; the tab's content follows.

The first build pinned a segmented control under a plain header, on a grey band; seen on a phone, the band read as a
second bar, and the whole head was redone after Contacts. The mock-ups F1 to F5 still show the first version.

**Inventaire** is the list the profile always showed: the first-sync bar while the books arrive, the books as they
come, « Emprunter à … » on a long press. Its header « Inventaire de X » went: the tab says it.

**Listes** shows the lists the friend lets me see, with the rows of my own Lists tab — covers fanned out, name,
what it is for, how many works or authors — and a chevron. Nothing writes: no « + », no swipe to delete, no
search. With no list it says « X n'a pas encore de liste » (F5); with none stored and the fetch failed, that the
lists could not be loaded; while the first fetch runs, a spinner.

**A friend's list opens on the same cover flow, read-only**: no « Modifier » in the bar, no add bar (the tab bar
stays in its place), no « Déplacer », no « Retirer de la liste ». Their comment, when they wrote one, reads as text
under « Commentaire », above the day the element was added.

On my own profile (reached from a transaction, say) the same screen shows my lists, which open editable.

## Technical surface

**A list knows its creator** (issue 0152). `EntityList` had no owner, and every list in the store was mine because
only mine were ever synced. It now carries `creatorId: String?`, from the listing's `creator`. A new optional
attribute: SwiftData migrates it lightly, with no plan. A list stored before has none, and **counts as mine** —
`EntityList.isCreated(byMe:)` — until my next sync stamps it.

- `ListModel.syncLists(forUser:)` still syncs mine; `syncFriendLists(of:)` syncs a friend's. Both go through one
  private sync whose **deletion pass is scoped** to the creator asked for (`upsert(scope:)`, the parameter 0019
  added for étagères): opening a friend's profile could otherwise have deleted every list of mine. Only my sync
  claims the unstamped lists. An answer without `creator` is stamped with the creator requested.
- **Mine only, wherever the app writes**: the Lists tab, the « … » menus (`EntityListMenu`), « Déplacer »
  (`ListMoveRow`) and the account-deletion count filter on `isCreated(byMe:)`.
- **Unfriending** deletes their lists at `reconcile`, next to their étagères, for the same reason: nothing syncs
  them again once the relation is gone.
- **The server decides what is visible.** `/api/lists/by-creators` answers with the lists I may see; nothing is
  filtered in the app.

`FriendListsTests` holds the five rules: the creator is stored, a friend's sync keeps mine (stamped or not) and
prunes theirs, my sync claims and prunes the unstamped, `isCreated(byMe:)`, and unfriending.

**The screen** (issue 0153). `UserDetailView` is an inset grouped `List` — the system's own sections, corners and
separators — whose first row is an empty frame as tall as the unfolded header, `UserProfileStickyHeader`, an overlay laid out in the safe area — just under the
navigation bar. A bar's principal item cannot hold a 96 pt picture, hence the overlay. The empty row rather than a
content margin keeps the scroll's insets the bars' alone, so the offset counts from the page at rest. The list
puts room of its own above its first section; the first row gives it back, measured at rest as the gap between the
header's top and the row's. The bar is made
transparent (`toolbarBackgroundVisibility(.hidden)`, and from iOS 26 the top scroll-edge blur turned off), so that
once folded the header's backdrop, which reaches up under the bar, is the only one.

The first build drew the header *into* the bar's row of buttons, the picture between the back button and « … »,
reading the bars' height from a `GeometryReader` that ignored the top safe area. That reader reported no inset at
all: on the phone the picture sat against the top of the screen and the page started a bar's height too low. The
picture now sits under the bar at rest, as asked after seeing it. Folded, the whole header rises by `barRise`
(58 pt: the Figma F3 as adjusted by hand, then 8 pt higher once the folded picture went from 40 to 48 pt on the
phone), so the picture sits a little above the middle of the bar's row; the rise is part of the fold's length, so the
page stays glued to the header's foot until it is folded. The back button and « … » stay the system's, which keeps the swipe back; hiding
the bar to draw our own would have lost it. Only the tabs take touches; the rest of the header lets them through.

The fold is read with `onScrollGeometryChange` (offset counted from rest) into `ProfileScrollOffset`, an
`@Observable` object read by the header alone: as `@State` of the screen, every frame of a scroll re-evaluated the
whole page, books included, and the header stuttered as it unfolded. It is computed by `ProfileHeaderCollapse`,
pure and tested: the progress, when the page is under the header, and where a scroll left inside the fold comes to
rest, which `ProfileHeaderSnapBehavior` (a `ScrollTargetBehavior`) applies. The fold's length is known before it
happens, from the header's own metrics: the picture's 56 pt, the bar rise, and the line heights of the name and
the count read off the fonts at the screen's text size (`Metrics(dynamicTypeSize:)`). The name is scaled as a
whole from `title200` down to `title50` in a frame exactly as tall as its scaled line — an earlier frame sized from
a guess was shorter than the line, so `minimumScaleFactor` shrank the name a second time and the gaps around it
opened. The backdrop was first `VariableBlurView`, fading out
24 pt below the header; on the phone a backdrop that stops on its hairline read better, and it is now the system
`.bar` material.

The tabs are `UserProfileTabPicker`, Buttons over a `matchedGeometryEffect` capsule; the glass is
`View.glassCapsule()` and the edge effect `View.topScrollEdgeEffectHidden()`, both in `View+glass.swift`. The rows are the forms' and the book screen's,
`backgroundFormCell` on `backgroundForm`. The pieces:
`UserProfileStickyHeader`, `UserItemCountText` (lifted out of `UserHeaderView`, which my Profil keeps),
`UserShelvesSection` (now a plain view, no longer a `List` section), `UserProfileTabPicker` over `UserProfileTab`,
`UserInventoryTab`, `UserListsTab`.

The title is set and then removed from the bar (`.toolbar(removing: .title)`), so the back button's long-press
menu still names the screen.

**A friend's lists are fetched each time their profile opens**, not in the launch's loop over friends: every
friend's lists would be fetched there, for a tab most profiles are never switched to. The store shows what it
holds in the meantime.

**Read-only** (issue 0154). `EntityListDetail` and `ListCoverFlowScreen` derive it from `isCreated(byMe:)`, as
`ShelfDetailView` derives it from the étagère's owner: a flag can be passed wrongly by a later caller, a list cannot
lie about whose it is. `ListReadOnlyCommentRow` shows their comment.

Five strings: `user.segment`, `user.lists.empty.title %@`, `user.lists.empty.message`, `user.lists.failed %@`,
`list.detail.comment.other`. `user.inventory.header %@` is no longer read.

## Decisions

- The lists live in the store, with a creator, like étagères — not in memory: the cover flow is built on
  `EntityList` and its `@Query`.
- An unstamped list is mine, rather than a migration that would have to guess.
- No name in the bar once the header has scrolled away: the request removed the title. The mock-up's spec leaves
  it as an open question.
- A `List`, not a `ScrollView` with drawn cards: a `ScrollView` was tried first, for its pinned section headers,
  and its cards' corners were not the system's. With the header an overlay, nothing needs a pinned header any more.
- Rows on `backgroundFormCell` over `backgroundForm`, as on the book screen, not the system cell grey.
- A non-friend's profile keeps its relation actions and « Inventaire privé », under the new header, with no tabs.

## Not done, not verified

- **The folding header has been seen at rest only**, in its first, wrong placement; the fold, the snap and the
  backdrop are unchecked. The first version (plain header, pinned segmented control) was seen on a phone, briefly.
  The Listes tab, a friend's list read-only and the pressing of a book on an étagère inside the list still
  want a pass — in light and dark, with VoiceOver and the largest text sizes.
- **The Figma mock-ups F1 to F5 show the first version**, to be redrawn once the header is approved.
- **The e2e scenario** does not play this screen: it signs in to one account, and a friend's lists need two.
- **Android**: not ported; the Android app was being worked on in another session.
- The mock-up's avatar is a 48 px asset blown up to 96 pt.
