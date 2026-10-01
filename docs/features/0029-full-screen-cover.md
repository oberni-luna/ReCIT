# A book's cover, full screen

Shipped on 2026-10-01. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

The cover at the top of a book's screen was only a picture. A tap on it now opens the cover alone, on black, as
large as the screen allows, zooming out of the header and back into it when closed.

- **Pinch** to magnify, between ×1 and ×4; **double-tap** jumps to ×2.5, and a second double-tap fits it again.
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
- **`FullScreenCoverView`** (`Features/Components/`) — `CachedAsyncImage` fitted to the screen, `MagnifyGesture`,
  a `DragGesture` enabled only when magnified, a double tap; a `.glass` icon-only « Fermer » button; dark scheme,
  status bar hidden. Identifier `e2e.fullScreenCover`, read by VoiceOver as one image, « Couverture ».
- **`CoverZoom`** (`Features/Components/`) — the value type holding the scale and the offset between gestures:
  `pinching(by:)` / `panning(by:)` for a gesture in flight, `endPinch(by:)` / `endPan(by:)` when it ends,
  `toggle()` for the double tap. Covered by `CoverZoomTests`.

## Notable decisions

- **In `EntityImageView`, not only in `BookDetailView`.** The three screens share one header; a cover tappable on
  one and inert on the others would be a surprise.
- **`fullScreenCover` with a zoom transition, not a pushed screen.** The cover is a look, not a place: nothing in
  the navigation path, and the swipe-down to close comes for free.
- **No new dependency, no UIKit `UIScrollView`.** SwiftUI gestures and a tested value type are enough for a still
  image.
- **The full-screen image is loaded at screen size.** `CachedAsyncImage` resizes to its frame, so a cover
  magnified ×4 is upscaled from a screen-sized bitmap. Covers on inventaire.io are rarely larger than that; if it
  shows, load the original for this view.
- **No offset bounds.** A magnified cover can be dragged past its edges; a double tap or a pinch back to fit
  recentres it.

## Not done, not verified

- Built and unit suite green (718 passed, 1 skipped). **Never seen on a simulator or a device**: the zoom
  transition, the gestures and the « Fermer » button are unchecked by eye.
- Not in the end-to-end scenario, which was not run.
- No Figma frame for this screen.
