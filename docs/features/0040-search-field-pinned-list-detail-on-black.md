# 0040 — Recherche's field always there, a list's detail on black

Shipped on 2026-10-21, in one commit, on autopilot: no PRD, no issues, no mockup. The request was
the owner's, from two dark-mode screenshots taken on a device: selecting Recherche showed its title
and « Chez mes amis » but no field to type in; and a list's detail was still on `gray/800` while the
Listes tab it is pushed from is on black since 0039.

## What it does

**Recherche always shows its field.** On iOS 27 it sits under the title, in the navigation bar, from
the moment the tab is selected; the keyboard stays down until the field is tapped, as 0037 wants.
On iOS 26 nothing changes: the system still puts a search tab's field at the bottom, in place of the
tab bar.

**A list's detail is on black in dark**, like the Listes tab: its rows read as one card on the
screen's black instead of melting into grey. Its not-found state takes the same black. In light,
nothing changes (`gray/50`).

## Technical surface

- **`SearchTabView`** — `.searchable(text:isPresented:placement:)` with
  `.navigationBarDrawer(displayMode: .always)`. The field binding, `isSearchPresented` and
  `TabRouter`'s request to raise the field are unchanged.
- **`EntityListDetail`** — `.applyListBackground(.backgroundGrouped)` instead of the default
  `backgroundSecondary`.

## Notable decisions

- **Why the field went missing.** iOS 27 lays a `.search`-role tab out in the bar with the others,
  where iOS 26 put it apart at the bar's end and turned it into the field once selected. A
  `.searchable` left to the automatic placement draws nothing on iOS 27 until something activates
  it. Reproduced on an iOS 27.0 simulator with a throwaway app of the same shape (a `TabView` whose
  last tab has the search role, a `NavigationStack` with a large title, `.searchable` inside it):
  applying `.searchable` to the stack instead of its content changes nothing; the drawer placement
  shows the field.
- **One placement for every version, no `#available`.** iOS 26 ignores the placement for a search
  tab and keeps the field at the bottom, so the drawer only takes effect where it is needed. It is
  also the placement `ReaderSearchView`, `FindGroupsView` and `InviteToGroupView` already use.
- **Not `tabViewSearchActivation(.searchTabSelection)`.** It shows a field on iOS 27 too, but by
  raising the keyboard as soon as the tab is selected, which covers the recents and the carousel
  that 0037 keeps visible at rest.
- **The title goes inline on iOS 27.** With the field pinned in the drawer, iOS 27 draws
  « Recherche » small in the bar, even with `.navigationBarTitleDisplayMode(.large)`. Left as the
  system has it.
- **Only the list's detail among the pushed screens.** 0039 left every pushed screen on `gray/800`;
  the request named this one, pushed from a tab on black. The others — a group, a book,
  « Tout voir », a reader's profile — are unchanged, so going one level down still goes from black
  to grey everywhere else.

## Owed, and known

- **The real app was not seen on iOS 27.** The simulator could not be signed in there; the
  behaviour was checked on the throwaway app only. The owner's device is the first place where the
  fix runs signed in.
- **Recherche seen on the iPhone 17 simulator on iOS 26.4**, signed in, in dark: field at the bottom
  as before.
- **The list's detail not seen**: the test account holds no list, and making one would have written
  to inventaire.io. The change is the token 0039 already put under the Listes tab.
- **`scripts/e2e.sh` not run.** No accessibility identifier moved; the scenario finds the field as
  `app.searchFields.firstMatch`, which the placement does not change.
- **Figma** — D-R6 and D-R8 in `docs/design-system/figma-library.md` carry the field's placement on
  iOS 27 and the list's detail.
- **Android** (`Recit_Android/`) followed in [0041](0041-android-catches-up-with-ios.md): its field is always shown, and a list's detail is on black.
