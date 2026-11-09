---
issue: 98
status: todo
wiki: [[features/0081-a-friends-and-a-groups-photo-full-screen]], [[features/0085-author-photos-full-screen]], [[features/0029-full-screen-cover]], [[features/0052-android-cover-zoom-edition-editing-context-menu]]
note: Rattrapage iOS 1.10.0 (features 0081 and 0085). Android has FullScreenCoverDialog for covers only, on black.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0081](../wiki/features/0081-a-friends-and-a-groups-photo-full-screen.md) and [0085](../wiki/features/0085-author-photos-full-screen.md).

- **Three photos open the Plein écran**: a friend's profile header photo at rest (`ui/network/UserProfileHeader.kt`), a group's header photo (`GroupScreen.kt`), an author's round photo (`ui/book/AuthorScreen.kt`). Folded, a friend's photo does not open, as iOS. No photo (initials / glyph fallback) → not clickable.
- **Rows keep their tap**: Réseau rows open the profile or the group; an author row on the Fiche livre opens the author.
- **Reuse `FullScreenCoverDialog`** (`ui/book/FullScreenCover.kt`): it gains the content description to read (cover vs photo) and moves to `ui/common/` if it is no longer a book-only component. Same gestures as the cover: double-tap fit/fill, pinch, pan, swipe down past 15 % closes, « Fermer ». Opens with its current fade; no shared-element zoom.
- **Background, for every Plein écran (cover included): blur on Android 12+.** The window behind is blurred (`blurBehindRadius`, API 31+, when the window manager reports cross-window blur enabled) under a veil of the theme — light in light mode, dark in dark mode — fading in over 300 ms as the black did, and fading with the swipe. Below Android 12 or with blur disabled (battery saver…): an opaque veil of the theme, no blur. No longer forced dark; « Fermer » stays legible in both themes. The colour is a design-system token, not a literal.
- **First frame.** Each header loads its photo with a memory-cache key the dialog reuses as placeholder (as `HeaderCover` does with `coverMemoryCacheKey`), so the Plein écran never opens empty.
- **TalkBack**: each photo is a button « Agrandir la photo ».
- Out of scope: my own Profil's avatar.

## Acceptance criteria

- Friend's profile at rest: tap the photo → Plein écran with the photo fitted; swipe down or « Fermer » closes.
- Friend's profile scrolled so the header is folded: tapping the small photo opens nothing.
- A friend without a photo: the initials disc is not clickable.
- Group screen: tap the header photo → Plein écran; a group without a photo: nothing opens.
- Author screen: tap the round photo → Plein écran; an author without a photo shows none and nothing opens.
- On Android 12+ in light mode: the screen behind is visible blurred under a light veil; in dark mode, under a dark veil. « Fermer » legible in both.
- On Android 9–11 (emulator): an opaque light / dark background, no black in light mode.
- A book cover's Plein écran gets the same background.
- Double-tap, pinch and pan work on the three photos as on a cover.
- TalkBack reads « Agrandir la photo, bouton » on each photo.
- Réseau → Amis row tap opens the profile; Fiche livre → author row opens the author.
