# A friend's profile: Inventaire and Listes as pages, changed by a swipe

Shipped on 2026-10-30, on the branch `android-1.7.0`, in an autopilot run: one slice, no PRD, no issue. It reworks
how the tabs of [0064](0064-a-friends-profile-with-tabs.md) change; the header, the étagères, the lists and what
they show are as 0064 left them.

## What it does

Choosing Inventaire or Listes no longer redraws the page in place. Seen on a phone, the change looked broken: the
books' rows slid and faded under the header while the lists' rows took their place.

The two tabs are now **two pages side by side**:

- **a tab's name scrolls to its page**, the glass capsule sliding to it as before;
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
- **The pager** is a horizontal `ScrollView` of the two pages, `.scrollTargetBehavior(.paging)`, its
  `scrollPosition(id:)` bound to the tab, its offset written to `ProfileScrollOffset.pagePosition` (0 on
  Inventaire, 1 on Listes).
- **`ProfileScrollOffset`** keeps one offset per page, which pages are scrolling, and the pager's position. The
  header reads the fold, the pull and whether content is under it from there: the fold is blended between the two
  pages — **the fold, not the offsets**, so halfway from a page 2 000 pt down to one at rest is half folded —
  through `ProfileHeaderCollapse.progress(between:and:pagePosition:)`, the one new rule with a test.
- **Measures.** A page's first row is read whenever *that page* is still and at rest (`isAtRest`), whatever the
  pager is doing: a page first drawn mid-swipe has to be measured then, since nothing moves it again once the
  swipe ends — read only with the pager settled, the Listes page sat 40 pt low. The header is read only once the
  pager has settled on the page on screen (`isSettled`).
- **Edge to edge.** The pager ignores the safe area, so the pages pass under the navigation and tab bars as the
  `List` did. Inside it a page is told no safe area: it would be as tall as the safe area and stop at the tab bar's
  top. So the screen is laid out on a `Color.clear` that fills the safe area, the pager and the header are its
  overlays, and two frames are measured on it — its own and, through a background that ignores the safe area, the
  screen's. The pages are as tall as the screen, and the difference at the foot, the tab bar's room, is each page's
  bottom `contentMargins`.

## Decisions

- **A paging `ScrollView`, not `TabView(.page)`.** The `TabView` was tried first: inside the safe area it cut the
  pages at the tab bar's top; made to ignore the safe area, its pages slid down by up to 40 pt as the list scrolled,
  pushing the end of the list off the screen. A `ScrollView` exposes its offset, its position and `scrollDisabled`.
- **Each page keeps its own scroll; the incoming page is not aligned on the header.** Aligning it — scrolling the
  other page to the fold, as some apps do — would move a page the reader is not looking at, and lose where it was.
- **The étagères are drawn twice**, once per page. A carousel shared above both pages would not scroll with
  either.

## Not done, not verified

- **Seen only in a throwaway harness**, on the iPhone 17 simulator in dark: a made-up friend with six or thirty
  books and three lists, no étagère, no tab bar, no back stack. Never seen signed in against inventaire.io.
- **Not checked:** the swipe back from the screen's left edge while on Inventaire, a swipe started on the étagères'
  carousel (the carousel should win), the profile inside the Profil sheet, light mode, the largest text sizes,
  VoiceOver, iOS 18, iPhone Duo.
- The capsule moves when the tab changes, at the end of a swipe — it does not follow the finger.
- e2e not run (it does not play this screen anyway). Android: not ported.
