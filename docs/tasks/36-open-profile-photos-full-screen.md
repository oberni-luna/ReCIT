---
issue: 36
status: todo
wiki: [[network]], [[features/0029-full-screen-cover]], [[features/0064-a-friends-profile-with-tabs]], [[features/0028-network-tab-and-groups]]
note: pouvoir ouvrir les photos des ami.e.s et des groupes en full screen, comme les covers des livres
created: 2026-11-06
---

## Context / Decisions

> pouvoir ouvrir les photos des ami.e.s et des groupes en full screen, comme les covers des livres

- **What**: a friend's photo and a group's photo open in the Plein écran (`FullScreenCoverView`), as a book's cover does on the Fiche livre (feature 0029).
- **Where**: the headers only.
  - Profil d'un ami (`UserDetailView`): the photo of `UserProfileStickyHeader`, at rest (96 pt) **and** folded (48 pt in the navigation bar).
  - Groupe screen (`GroupDetailView`): the photo of `GroupHeaderView`.
  - Rows (`UserCellView`, `ReaderRowView`, `GroupCellView`, …) keep their tap: it opens the profile or the group.
  - My own Profil (`ProfileAvatar`) out of scope.
- **No photo** (person glyph or group glyph on a grey disc): not a button, nothing opens.
- **Same viewer, same gestures**: reuse `FullScreenCoverView` as is — fit, double-tap fill/fit, pinch, drag, swipe down or « Fermer ».
  The photo opens zooming out of where it sits (`matchedTransitionSource` + `.navigationTransition(.zoom)`), like `EntityImageView`.
  The image shown full screen is the full-size photo, not the thumbnail size.
- **Accessibility**: the photo button gets its own label (« Agrandir la photo » / « Enlarge photo »), not the cover's `cover.action.enlarge`.
- **iOS only.** Android catches up in a later « Android catches up » task.

## Acceptance criteria

- Profil d'un ami with a photo, header at rest: tap the photo → it zooms out to the Plein écran, black backdrop, « Fermer » top right.
- Same profile, scrolled until the header folds: tap the 48 pt photo in the bar → the Plein écran opens from there.
- In the Plein écran: double-tap fills then fits; pinch zooms; swipe down or « Fermer » goes back to the profile, header in the state it was.
- Groupe screen with a photo: tap the header's photo → the Plein écran opens.
- Friend or group without a photo: tapping the grey disc does nothing; VoiceOver reads no button there.
- Réseau → Amis and Groupes lists: tapping a row's photo still opens the profile or the group, never the Plein écran.
- VoiceOver on a header photo reads « Agrandir la photo », button.

## Implementation

## Review

## Verification

## Feedback
