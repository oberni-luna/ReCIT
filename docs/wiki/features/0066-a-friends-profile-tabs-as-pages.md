# A friend's profile: Inventaire and Listes as pages, changed by a swipe

Shipped on 2026-10-30, on the branch `android-1.7.0`: one slice in an autopilot run, no PRD, no issue, then the
pager redone in UIKit the same day after a pass on a phone. It reworks how the tabs of
[0064](0064-a-friends-profile-with-tabs.md) change; the header, the étagères, the lists and what they show are as
0064 left them. The model is the Contacts card of Messages: a header above a pager, each page scrolling on its own.

> Since [0086](0086-a-friends-transactions-tab.md), the pager holds four pages on a friend's profile (Inventaire,
> Listes, Échanges, Présentation) and three on mine, given to `TabPager` as a list rather than every case of the
> enum.

## What it does

Choosing Inventaire or Listes no longer redraws the page in place. Seen on a phone, the change looked broken: the
books' rows slid and faded under the header while the lists' rows took their place.

The two tabs are now **two pages side by side**:

- **a tab's name turns to its page**, the glass capsule gliding to it as the page turns;
- **the capsule follows the finger** during a swipe, between the two words by as much of each page as is on screen,
  as Messages' does; the word it is mostly under is drawn as the selected one;
- **a horizontal swipe anywhere on the page** turns to the other one, and selects its tab once it settles;
- **each page keeps its own scroll.** Deep in the books, a swipe to Listes finds the lists where they were left —
  at their top the first time — and the header **unfolds or folds along with the swipe**, by how much of each page
  is on screen. A swipe back to Inventaire finds the books where they were, the header folded again;
- the bio and the étagères head **both** pages, since what scrolls with a page has to be in it.

The page still freezes while a book is being picked off an étagère, the swipe included.

## Technical surface

- **`UserProfilePage`** (new) is one page: the inset grouped `List` that `UserDetailView` used to be — the
  header's room as its first row, the bio, the étagères, then the tab's content — with the snap of the fold, the
  scroll reporting and the freeze. The profile of someone whose books are closed to me is one such page, with no
  pager.
- **`UserProfilePager`** (new) is UIKit's pager, a `UIPageViewController` (`.scroll`, horizontal) in a
  `UIViewControllerRepresentable`, bound to the tab. Each page is a `UIHostingController` whose root view is
  given the screen's whole environment (`.environment(\.self, context.environment)`) — the app's models, the
  store, the `NavigationStack` that a list's `NavigationLink` pushes onto — and is replaced at every update of the
  screen, so the pages keep their state. The coordinator reads the pager's scroll view by KVO on `contentOffset` and
  writes `ProfileScrollOffset.pagePosition` (0 on Inventaire, 1 on Listes) as the finger moves; a tab chosen by
  its name is turned to with `setViewControllers(_:direction:animated:)` and the header animated to it; a swipe
  that turns the page selects its tab in `didFinishAnimating`. A tab chosen by its name while a swipe is still
  settling is kept and turned to once it has, instead of being lost under the page the swipe lands on. Frozen
  through the scroll view's `isScrollEnabled`.
- **`UserProfileTabPicker`** draws its capsule from `pagePosition` rather than from the selection: each word's frame
  is measured in the picker, and the capsule is laid between the two the pager stands between. Turned to by name,
  `pagePosition` is animated (`.snappy`), and the capsule glides with it; the `matchedGeometryEffect` goes.
- **`ProfileScrollOffset`** keeps one offset per page, which pages are scrolling, and the pager's position. The
  header reads the fold, the pull and whether content is under it from there: the fold is blended between the two
  pages — **the fold, not the offsets**, so halfway from a page 2 000 pt down to one at rest is half folded —
  through `ProfileHeaderCollapse.progress(between:and:pagePosition:)`, the one new rule with a test.
- **Measures.** A page's first row is read whenever *that page* is still and at rest (`isAtRest`), whatever the
  pager is doing: a page first drawn mid-swipe has to be measured then, since nothing moves it again once the
  swipe ends — read only with the pager settled, the Listes page sat 40 pt low. The header is read only once the
  pager has settled on the page on screen (`isSettled`).
- **Edge to edge.** The pager ignores the safe area, so the pages pass under the navigation and tab bars as the
  `List` did. UIKit hands each hosted page the safe area itself, so each list keeps its last rows clear of the tab
  bar with nothing measured.

## Decisions

- **`UIPageViewController`, after two SwiftUI pagers.** A paging horizontal `ScrollView` shipped first: on a
  phone, a finger's slant scrolled the page up or down while it turned — no direction lock against the lists
  inside — and the pager fell back to the first page in one frame. `TabView(.page)`, tried on the phone after it,
  turned well by a swipe but not when a tab's name was chosen, and on the simulator its pages slid down by up to
  40 pt once made to ignore the safe area. UIKit's pager locks the swipe to one direction, turns when asked, and
  gives its pages the safe area.
- **Not Fitness Park's `SessionDetailView`**, looked at as a model: it is one vertical `ScrollView` whose pinned
  section header holds the tabs and whose content is swapped without animation — no pager, no swipe.
- **Each page keeps its own scroll; the incoming page is not aligned on the header.** Aligning it — scrolling the
  other page to the fold, as some apps do — would move a page the reader is not looking at, and lose where it was.
- **The étagères are drawn twice**, once per page. A carousel shared above both pages would not scroll with
  either.

## Not done, not verified

- **The UIKit pager is seen only in a throwaway harness**, on the iPhone 17 simulator in dark: a made-up friend with
  thirty books and three lists, no étagère, no tab bar. Checked there: a tab's name turns the page, a swipe turns
  it and selects the tab, the header folds and unfolds with the page on screen, a list opens through its
  `NavigationLink`, the swipe back from the left edge pops the screen, the end of the books clears the home
  indicator, the capsule straddles the two words halfway through a held swipe and glides after a tap. Installed on a phone for a pass with a real finger, not yet reported on.
- A finger put on a list still decelerating stops it, as anywhere in UIKit, and that touch does not turn the page.
- **Not checked:** a swipe started on the étagères' carousel (the carousel should win), pressing a book on an
  étagère inside a hosted page (the focus overlay reads global frames), the profile inside the Profil sheet, light
  mode, the largest text sizes, VoiceOver, iOS 18, iPhone Duo.
- e2e not run (it does not play this screen anyway). Android: not ported.
