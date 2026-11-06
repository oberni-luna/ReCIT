# A friend's photo and a group's photo, full screen

Shipped on 2026-11-06, iOS only (issue #36). A book's cover already opened full screen from the Fiche livre
([0029](0029-full-screen-cover.md)). A reader's photo and a group's photo could only be seen at header size.

## What it does

- Profil d'un ami: tap the photo in the header at rest (96 pt) → the Plein écran slides up. Folded (48 pt), the
  photo sits in the navigation bar's row and the bar takes the tap: nothing opens. Olivier accepted this.
- Groupe screen: tap the header's photo → the Plein écran zooms out of it.
- The Plein écran is `FullScreenCoverView`: the picture fitted on black, double-tap between fit and fill, pinch,
  drag, swipe down or « Fermer ».
- No photo (the grey disc with a glyph) → no button, nothing opens.
- The rows of Réseau → Amis and Groupes keep their tap: it opens the profile or the group.
- VoiceOver reads « Agrandir la photo », button.

## Why the friend's photo does not zoom

The first version zoomed both photos out of their place, as the cover does. On a friend's profile the photo then
disappeared. The header is an overlay on top of `TabPager`, which is a `UIPageViewController`. Once the avatar is the
source of a `matchedTransitionSource`, SwiftUI no longer draws it there. Removing the source alone brought the photo
back. So the friend's photo opens with the plain slide-up of a full-screen cover. The group's header is not over
UIKit pages, so it keeps the zoom.

Swiping down to close was the zoom transition's own gesture. Without the zoom, `FullScreenCoverView` brings its
own: `closingOnSwipeDown()`, a vertical drag ignored during a pinch and while magnified, which closes past 120 pt.

A `ToolbarItem(placement: .principal)` was tried for the folded photo. It showed in the accessibility tree, but taps
on the simulator still opened nothing, so it was removed.

## Technical surface

- `Features/Components/EnlargeablePhotoModifier.swift`: `View.enlargeablePhoto(_ url: URL?, opening:)`.
  - A URL wraps the view in a plain button, its own accessibility element labelled `photo.action.enlarge`.
  - `opening: .slideUp`, the default → no transition source, and the Plein écran closes on a swipe down.
  - `opening: .zoom(from: radius)` → `matchedTransitionSource` + `.navigationTransition(.zoom)`.
  - No URL → the view is unchanged.
- `UserProfileStickyHeader`: `photoURL`, identifier `e2e.user.photo`. Only the name ignores touches now, not the
  whole identity stack.
- `GroupHeaderView`: `opening: .zoom(from: .medium)`, identifier `e2e.group.photo`.
- String `photo.action.enlarge`: « Agrandir la photo » / "Enlarge photo".

## Not done

- The folded photo does not open (see above).
- A group picture URL that fails to load still shows the glyph as a button, and opens an empty black Plein écran.
  Accepted: the URL is broken on the server's side, which is rare.
- My own Profil (`ProfileAvatar`) and the rows.
- Android.
- Seen on the simulator: the friend's photo shows, opens, closes with « Fermer » and with a swipe down; one
  « Agrandir la photo » button in the accessibility tree. The group's zoom and VoiceOver itself were not checked by
  the agent. e2e was not run.
