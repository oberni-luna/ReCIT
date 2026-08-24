//
//  ShelfFocusModel.swift
//  ReCIT_iOS
//
//  What the focus overlay needs to draw: which book is under the finger, where it sits, and
//  how far the press has come. `MainTabView` owns it, because the overlay has to reach over
//  the nav bar and the tab bar, which nothing inside the shelves screen can do.
//
//  Where it sits is kept as two halves — the book's frame inside its card, and the card's
//  own origin on screen — because they move for different reasons and at different times.
//
//  Only the pressed book crosses over — never the shelf. That is what makes this tractable:
//  one book is cheap to redraw sharp above a veil, a whole étagère was not. See ADR 0006.
//

import CoreGraphics
import Observation

@Observable @MainActor
final class ShelfFocusModel {

    /// How the shelf is drawing this book, so the copy matches it.
    enum Presentation: Equatable {
        case standing
        case lying
        /// A lone book, shown face-on with its cover.
        case cover

        var orientation: ShelfBookOrientation {
            self == .lying ? .lying : .standing
        }
    }

    struct Book: Equatable {
        let item: InventoryItem
        /// Where the book sits at rest, unscaled, **in its card's own coordinates** — exactly
        /// as the shelf draws it. It grows about this frame's centre.
        ///
        /// Deliberately not screen coordinates. This changes only when the finger moves to
        /// another book; where the card *is* changes whenever anything scrolls, and that is
        /// `cardOrigin`'s job. One field, one reason to change — see ADR 0006.
        let frameInCard: CGRect
        let presentation: Presentation
        /// The last standing book on a shelf leans; the copy has to lean with it.
        let leaning: Bool
    }

    /// The book under the finger. Nil between presses, and while the finger is off the shelf.
    var book: Book?
    /// Where the pressed book's card sits on screen, republished on every layout pass for as
    /// long as the press lasts. Added to `Book.frameInCard` this gives the copy's screen
    /// position — which is how the copy stays glued to the shelf while the page scrolls under
    /// it. Frozen at press time, the copy hung in mid-air the moment anything moved.
    var cardOrigin: CGPoint = .zero
    /// How far the press has come: 0 at touch-down, 1 by the time selection mode arms. The
    /// veil rides on this, so the screen recedes as the book grows.
    var progress: Double = 0
    /// How much the book has grown (1 = at rest).
    var growth: CGFloat = 1
    /// True once selection mode armed: the book's cell is shown and every scroll freezes.
    var isArmed: Bool = false

    /// True while a press is being drawn.
    var isPressing: Bool { book != nil }

    /// Drops everything at once, without animating. Used when a book detail screen is about to
    /// cover the shelf: an overlay unwinding on top of it reads as a leftover.
    func reset() {
        book = nil
        cardOrigin = .zero
        progress = 0
        growth = 1
        isArmed = false
    }
}
