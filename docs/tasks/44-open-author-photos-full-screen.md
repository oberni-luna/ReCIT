---
issue: 44
status: to-test
wiki: [[network]], [[book-and-editions]]
note: les images des auteurs aussi doivent pouvoir être ouvertes en full screen. Et on va en profiter pour changer le background des images en full screen pour un Apple material regular.
created: 2026-11-06
---

## Context / Decisions

> les images des auteurs aussi doivent pouvoir être ouvertes en full screen
>
> Et on va en profiter pour changer le background des images en full screen pour un Apple material regular.

- Builds on #36 (merged): `View.enlargeablePhoto(_:opening:)` in `Features/Components/EnlargeablePhotoModifier.swift`
  and the Plein écran `FullScreenCoverView`.
- **Author photo**: only the large round photo at the top of the Auteur·ice screen (`AuthorDetailView`,
  `CellThumbnail(imageUrl:cornerRadius: .full, size: .large)`). It opens the Plein écran through `enlargeablePhoto`,
  `opening: .zoom(from: .full)`: the screen is a plain `List`, not over `TabPager`, so the zoom works as on the
  group's header.
- The URL opened is the same one the thumbnail loads (Wikimedia and inventaire.io paths resolved the same way).
- Author rows elsewhere (`EntityAuthorsView` on the Fiche livre) keep their tap: it opens the author.
- No photo → nothing changes, nothing to press.
- **Background**: the black behind the picture becomes the system Regular material, for every Plein écran: book
  covers, a friend's photo, a group's photo, an author's photo. One view, one background.
- The Plein écran follows the appearance: light material in light mode, dark in dark mode. The forced
  `.environment(\.colorScheme, .dark)` goes. The « Fermer » button and the picture must stay legible in both.
- The fade-in of the background stays: the material appears over 0.3 s, as the black did, so the zoom does not open
  on a card.
- Out of scope: my own Profil's avatar, Android.

## Acceptance criteria

1. Auteur·ice screen of an author with a photo: a tap on the round photo opens the Plein écran, zooming out of
   the circle, the photo fitted to the screen.
2. A swipe down or « Fermer » closes it, back into the circle.
3. Auteur·ice screen of an author without a photo: no photo, nothing opens.
4. VoiceOver on the author's photo reads « Agrandir la photo », button.
5. The Plein écran of a book cover, a friend's photo, a group's photo and an author's photo shows the Regular
   material, with the screen underneath blurred through it — no plain black.
6. In light mode the material is light; in dark mode it is dark. « Fermer » and the picture are legible in both.
7. On the Fiche livre, a tap on an author row still opens the Auteur·ice screen.

## Implementation

- `ReCIT_iOS/Features/Components/FullScreenCoverView.swift`: backdrop `.black.opacity(backdropOpacity)` → `Rectangle().fill(.regularMaterial).opacity(backdropOpacity).ignoresSafeArea()`; fade-in `easeOut(0.3)` and 0.2 s fade-out kept; `.presentationBackground(.clear)` kept; forced `.environment(\.colorScheme, .dark)` removed — the Plein écran follows the appearance. « Fermer » (`glassButtonStyle`) adapts on its own.
- Every caller gets the material with no call-site change: book cover (`EntityImageView`, zoom), friend's photo (`UserProfileStickyHeader`, slide-up), group's photo (`GroupHeaderView`, zoom).
- `ReCIT_iOS/Features/EntityBrowser/Author/AuthorDetailView.swift`: the round `CellThumbnail` gets `.enlargeablePhoto(URL(string: image), opening: .zoom(from: .full))` and identifier `e2e.author.photo`. No photo → nothing shown, nothing to press.
- `EnlargeablePhotoModifier.swift`: doc comment only. No new string (reuses `photo.action.enlarge`).
- Glossary « Plein écran » still reads "on black": proposed change in the run report, not written.
- Proof: build ✅ (SwiftLint in the build).
- Runtime fix (autopilot, PM check): the author photo was invisible at rest. Cause: `.zoom(from: .full)` handed `matchedTransitionSource` a `.rect(cornerRadius: 360)` clip on a 64 pt photo, which leaves nothing visible. `EnlargeablePhotoModifier` now measures the source (`onGeometryChange`) and caps the clip radius at half its smaller side (`sourceCornerRadius(_:)`): 32 pt for the author circle; `.medium` (group photo) unchanged.

## Review

## Verification

PM on the simulator (iPhone 17, iOS 26.4, light, merged build + fix):
- ✅ Auteur·ice screen (John Steinbeck): round photo shown at rest (was blank before the fix).
- ✅ Tap → Plein écran, photo fitted, light Regular material, « Fermer » legible; « Fermer » → back on the Auteur·ice screen, photo shown.

Still yours: zoom out of / back into the author circle as an animation; material in light and dark, iOS 26 and iOS 18; screen underneath blurred, never plain black; author row on the Fiche livre still opens the author.

## Feedback
