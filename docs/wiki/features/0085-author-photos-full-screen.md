# An author's photo full screen, over the Regular material

Shipped on 2026-11-06, iOS only (issue #44). A book's cover, a friend's photo and a group's photo already opened
the Plein écran ([0029](0029-full-screen-cover.md), [0081](0081-a-friends-and-a-groups-photo-full-screen.md)).
An author's photo could only be seen at its size on the Auteur·ice screen. It now opens too. On the way, the black
behind every Plein écran became the system Regular material, so the screen it opened from shows through, blurred.

## What it does

- Auteur·ice screen: tap the round photo at the top → the Plein écran zooms out of the circle, the photo fitted to
  the screen. A swipe down or « Fermer » closes it, back into the circle.
- An author without a photo shows no photo, and nothing opens.
- VoiceOver reads « Agrandir la photo », button, as on a friend's and a group's photo.
- Author rows elsewhere keep their tap: on the Fiche livre, an author row still opens the Auteur·ice screen.
- Every Plein écran — book cover, friend's photo, group's photo, author's photo — now sits over the Regular
  material instead of black. It still fades in over 0.3 s, so the zoom does not open on a card.
- The Plein écran follows the appearance: a light material in light mode, a dark one in dark mode. It is no longer
  forced dark. « Fermer » keeps its glass style and adapts on its own.

## Technical surface

- `Features/EntityBrowser/Author/AuthorDetailView.swift`: the round `CellThumbnail` (`cornerRadius: .full`,
  `size: .large`) gets `enlargeablePhoto(_:opening: .zoom(from: .full))`, with the same URL the thumbnail loads,
  and the identifier `e2e.author.photo`. The Auteur·ice screen is a plain `List`, not over `TabPager`, so the zoom
  works as on the group's header (see 0081 for why a friend's photo slides up instead).
- `Features/Components/EnlargeablePhotoModifier.swift`: `.zoom(from: .full)` first left the author's photo blank
  at rest. `.full` is 360 pt, and `matchedTransitionSource` clipped the 64 pt photo with that radius, which leaves
  nothing visible. The modifier now measures its source with `onGeometryChange` and caps the clip radius at half
  the source's smaller side (`sourceCornerRadius(_:)`): 32 pt for the author's circle, the group's `.medium`
  unchanged. No new string: it reuses `photo.action.enlarge`.
- `Features/Components/FullScreenCoverView.swift`: the backdrop is a `Rectangle` filled with `.regularMaterial`,
  ignoring the safe area, its opacity faded in as the black was (`easeOut` 0.3 s in, 0.2 s out).
  `presentationBackground(.clear)` stays, so the material blurs the screen underneath. The forced
  `.environment(\.colorScheme, .dark)` is gone. Every caller gets the material without a change at its call site.

## Not done / owed

- My own Profil's avatar, and Android.
- Seen by the agent on the simulator (iPhone 17, iOS 26.4, light): the round photo shows at rest, a tap opens the
  Plein écran over the light material with « Fermer » legible, and « Fermer » goes back.
- Not checked: the zoom out of and back into the circle as an animation; the material in dark mode and on iOS 18;
  the screen underneath blurred, never plain black; an author row on the Fiche livre still opening the author.
  e2e was not run.
