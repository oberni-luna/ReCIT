# A book's cover, full screen

Shipped on 2026-10-01. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

The cover at the top of a book's screen was only a picture. A tap on it now opens the cover alone, on black,
fitted to the whole screen — under the Dynamic Island and the home indicator too — zooming out of the header and
back into it when closed.

- **Double-tap** a fitted cover to make it fill the screen; double-tap a filled one, or one pinched to any other
  size, to fit it again.
- **Pinch** to magnify, from fitted to ×4 — or further, up to filled, for a cover much narrower than the screen.
- **Drag** moves a magnified cover around. A cover back at its fitted size is centred again.
- **Swipe down** (the zoom transition's own gesture) or **« Fermer »**, top right, to go back. Swiping down is
  off while the cover is magnified, where it would fight the drag.

The same header is used by the work's edition picker and by the screen shown while a scanned or searched book is
resolved, so their covers open the same way. A header with no image has nothing to tap.

## Technical surface

- **`EntityImageView`** (`Features/EntityBrowser/`) — the foreground cover becomes a plain `Button` (VoiceOver
  label « Agrandir la couverture », identifier `e2e.entityCover`), the source of a `.matchedTransitionSource`, and
  presents a `fullScreenCover` with `.navigationTransition(.zoom(sourceID:in:))`. The blurred copy behind the
  header stays decoration.
- **`FullScreenCoverView`** (`Features/Components/`) — `FullScreenCoverImage` fitted to the screen ignoring the safe
  area, its fitted size and the screen's read with `onGeometryChange` (before `scaleEffect`), `MagnifyGesture`,
  a `DragGesture` enabled only when magnified, a double tap; a `.glass` icon-only « Fermer » button; dark scheme,
  status bar hidden. Identifier `e2e.fullScreenCover`, read by VoiceOver as one image, « Couverture ».
- **`CoverZoom`** (`Features/Components/`) — the value type holding the scale and the offset between gestures.
  Scale 1 is fitted; `measure(fitted:in:)` derives `fillScale`, the larger of the screen-to-cover ratios on each
  axis. `pinching(by:)` / `panning(by:)` for a gesture in flight, `endPinch(by:)` / `endPan(by:)` when it ends,
  `toggle()` for the double tap. Covered by `CoverZoomTests`.

## Notable decisions

- **In `EntityImageView`, not only in `BookDetailView`.** The three screens share one header; a cover tappable on
  one and inert on the others would be a surprise.
- **`fullScreenCover` with a zoom transition, not a pushed screen.** The cover is a look, not a place: nothing in
  the navigation path, and the swipe-down to close comes for free.
- **No new dependency, no UIKit `UIScrollView`.** SwiftUI gestures and a tested value type are enough for a still
  image.
- **The cover is drawn on the first frame, then sharpened.** `FullScreenCoverImage` reads the header's image
  from Nuke's memory cache before the first frame, so the zoom grows a cover and not an empty card, and loads the
  original in the background — never resized to a frame — fading it in over the first. Through `CachedAsyncImage`
  it used to be resized to the frame its placeholder had, a `ProgressView`'s, which is why it opened blurred.
  `FullScreenImageURL` raises a Wikimedia `width` to 2048; an inventaire.io `/img/entities/<hash>` with no size
  already is the original. A cover that is small at the source — 306 × 500 for some — stays soft: there is no
  larger one.
- **No black on the first frame.** The presentation background is clear and the black behind the cover fades in
  over 0.3 s (and out when « Fermer » is tapped). A black present at once was the dark flash the screen opened
  with.
- **The double tap goes between fit and fill, not to a fixed factor.** A fixed ×2.5 overshot a wide cover and
  fell short of a narrow one; fill is the size that means something for any cover. Anything that is not fitted
  goes back to fit, so the gesture always has a known way home.
- **No offset bounds.** A magnified cover can be dragged past its edges; a double tap or a pinch back to fit
  recentres it.

## Not done, not verified

- Built and unit suite green. **Never seen on a simulator or a device**: the zoom
  transition, the gestures and the « Fermer » button are unchecked by eye.
- Not in the end-to-end scenario, which was not run.
- No Figma frame for this screen.
