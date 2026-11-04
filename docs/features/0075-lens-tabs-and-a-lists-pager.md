# Tabs picked up as a lens, and a list's pages turned by a swipe

Shipped on 2026-11-04, from a prototype on a reader's profile modelled on the tabs of Messages' Contacts card in
iOS 26, and on an article about UIKit's private `_UILiquidLensView`. That class draws exactly this lens, but it is
private API (App Review guideline 2.5.1), so the lens is rebuilt from public SwiftUI. PRD 0143 and issues
0143–0144, deleted with this write-up.

## What it does

- **On a reader's profile and on a list's screen, the tabs' capsule can be picked up.** A touch lifts it: it grows
  by 15 % and the words under it are magnified by 20 %. It follows the finger across the words. A word under its
  edge is half dark, half grey, as in Messages. Let go, it settles on the nearest word, or on the next one if
  flung, springs a little past it and comes back. The pager turns to that page.
- **Past the first or last word** the capsule follows less and less, like a scroll view's rubber band, up to 36 pt.
  It also stretches towards the finger: the far edge follows the finger fully, the near one by half, and the
  capsule flattens a little. Let go, it springs back.
- **A tick each time the held capsule reaches another word**, as a segmented control's thumb does: the
  selection haptic, on a tap on another word, at each word crossed, and when a flick carries it one word
  further. Touching the selected word and swiping the pages give none.
- **A tap on a word** still picks it. VoiceOver still sees one button per tab, with its count.
- **A list's two pages, Livres and Présentation, are now side by side in a pager**, as a reader's profile is: a
  swipe turns from one to the other. On Livres, a swipe on the covers still scrolls the covers, and a swipe
  anywhere else turns the page. The capsule follows the swipe. Each page keeps its own scroll. « Ajouter un livre »
  belongs to Livres and slides away with it. The pager holds still while a comment is being written.

## Technical surface

- **`LensTabPicker<Tab, Label>`** (`Features/Components/`) — the picker, generic over a `CaseIterable` tab enum
  and a label builder. Its capsule follows `pagePosition` unless a finger holds it, and while it settles after a
  release. The words are drawn twice by **`LensTabLabels`**:
  - in grey, holed where the capsule is (a `destinationOut` capsule in the mask);
  - in `foregroundDefault`, masked to the capsule and scaled about its centre while lifted.

  The gesture is a `DragGesture(minimumDistance: 0)`. A `@GestureState` catches a touch the system takes away.
  The animations are `spring(duration: 0.35, bounce: 0.4)` for the lift and `spring(duration: 0.5, bounce: 0.35)`
  for the settle, which carries the finger's speed past the word.
- **`LensTabTrack`** — the pure geometry:
  - the capsule's frame at a position;
  - the lifted and stretched lens frame;
  - the position whose capsule centre is under a finger;
  - the damped overshoot (`rubberBand`);
  - `releaseIndex`, which projects the finger 0.1 s ahead at its speed and moves at most one word from the
    nearest one.

  Tested by **`LensTabTrackTests`** (7 tests).
- **`TabPager<Tab, Page>`** (`Features/Components/`) — `UserProfilePager` made generic. It writes its position
  to a **`TabPagerPositionStore`**, adopted by `ProfileScrollOffset` on a profile and by the new
  **`TabPagerPosition`** on a list.
- **`UserProfileTabPicker`** and **`ListDetailTabPicker`** — thin wrappers that give the labels and the
  accessibility label. The list's picker reads the pager's position in its own body, so a swipe redraws only the
  tabs.
- **`ListCoverFlowScreen`** — a `ZStack` holds the pager (edge to edge, like the profile's) and the tabs laid
  over it, measured. It also keeps the selection, the add sheets, the scanner and the fetch of the entities.
- **`ListElementsPage`** (new) — the Livres page. It holds the comment's `@FocusState`, the keyboard's frame and
  its « OK », the room for the keyboard and the add bar. A focus held by the screen does not reach into a page's
  `UIHostingController`. The page reports `isWritingComment` back, and the screen freezes the pager with it.
- **`listDetailTabsBar()` / `listDetailTabsRoom(height:)`** — the tabs over the pages (on the bars' material
  before iOS 26), and the empty top bar each page leaves for them. From iOS 26 that bar is a `safeAreaBar` with
  the soft scroll edge, so the list fades out under the tabs.

## Notable decisions

- **Public API only.** The edge refraction that `_UILiquidLensView` draws is missing; the lift, the magnification,
  the follow, the rubber band and the bounce are there.
- **One picker and one pager for both screens.** Feature 0073 gave the list its own picker because nothing
  paged there; now that it pages, the profile's mechanism is shared rather than copied.
- **The covers keep their swipe.** A horizontal `ScrollView` inside a `UIPageViewController` page wins over the
  pager, so the cover flow and the page turn do not fight. Only the rest of Livres turns the page.
- **The pager takes no finger while a tab's name turns it.** A swipe that caught such a turn halfway left UIKit
  without ever reporting the turn's end. The pager then waited forever, and a tab chosen after did nothing. It
  showed on the list and the profile had the same race. The selection also follows the page on screen whenever a
  swipe ends.
- **The add bar moves into Livres**, since the add bar, the keyboard and the comment belong together. On a
  swipe it slides away with its page rather than vanishing when the tab changes.

## Not done, not verified

- **Seen on the iPhone 17 simulator, in a throwaway harness, signed out:** the profile's picker alone, in light
  and dark, and a made-up friend's list of four works in dark (read-only, so no add bar). Checked there:
  - lift, magnification, drag, rubber band at both ends, settle bounce;
  - a short flick moves one word only, and a tap picks a word;
  - a swipe on the list's lower half turns to Présentation, and a swipe on the covers scrolls them;
  - the turn-by-name race described above.
- **Not seen:**
  - a real reader's profile with the header folding;
  - one of my lists: add bar, comment focus, keyboard, the pager frozen while writing;
  - Présentation scrolled under the tabs;
  - iOS 18, a device, the iPhone Duo.
- **Android** not done: its profile and list keep their tabs as they were. e2e not run.
