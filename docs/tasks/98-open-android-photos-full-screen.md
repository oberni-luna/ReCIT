---
issue: 98
status: to-test
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

## Implementation

- `ui/book/FullScreenCover.kt` and `CoverZoom.kt` moved to `ui/common/` (+ `CoverZoomTest`). `FullScreenCoverDialog(url, contentDescription, onDismiss)`; the black backdrop is `FullScreenBackdrop.veil(...)`, still faded in 300 ms and with the swipe. API 31+: window blur (`FLAG_BLUR_BEHIND` + `blurBehindRadius`, 30 dp at full) follows the same level through a `snapshotFlow`, `addCrossWindowBlurEnabledListener` while open; navigation-bar icons follow the theme; « Fermer » `backgroundSecondary` / `foregroundDefault`. `coverMemoryCacheKey` → `fullScreenMemoryCacheKey` (`full-screen:$url`).
- `ui/common/FullScreenBackdrop.kt`: pure `Blurred` / `Opaque`, `of(sdkInt, isCrossWindowBlurEnabled)`, `veil(colors)` → `backgroundMaterial` or `backgroundDefault`.
- `ui/common/EnlargeablePhoto.kt` (port of iOS `enlargeablePhoto`): url + enabled → clickable, semantics « Agrandir la photo », role Button, opens the dialog; null url or disabled → unchanged. Cache key independent of `isEnabled`.
- Design system: `RecitColors.backgroundMaterial` (Gray0 70 % light, Gray900 70 % dark — new Android token, no Figma counterpart yet); `CellThumbnail` and `GroupThumbnail` gain `memoryCacheKey`; `rememberImageModel(url, memoryCacheKey)` shared with `HeaderCover`.
- Headers: `GroupScreen` GroupHeader, `AuthorScreen` AuthorHeader, `UserProfileHeader` (`isEnabled = fold == 0f`: at rest only) wrap their photo in `EnlargeablePhoto`.
- `res/values/strings_photo.xml`: `photo_action_enlarge` « Agrandir la photo », `photo_accessibility_label` « Photo ».
- Tests: `FullScreenBackdropTest` (5). Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest` ✅ 605 tests, 0 failures. Android lint (NewApi) not run; API 31 calls behind `SDK_INT >= S` / `@RequiresApi(S)`.
- Side effect to check: the friend's photo at rest now takes touches, so a scroll or page swipe starting on it does not move the page (letting it through would also leak capsule-tab taps to the pages).
- Runtime not run: no inventaire.io credentials for the agent. Blur radius and 70 % alpha are unseen guesses.

## Review

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
