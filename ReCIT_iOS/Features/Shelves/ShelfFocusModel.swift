//
//  ShelfFocusModel.swift
//  ReCIT_iOS
//
//  What the focus overlay needs to draw: which book is under the finger, where it sits on
//  screen, and how far the press has come. `MainTabView` owns it, because the overlay has to
//  reach over the nav bar and the tab bar, which nothing inside the shelves screen can do.
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
        /// Where the book sits on screen at rest, unscaled, exactly as the shelf draws it.
        /// It grows about this frame's centre.
        let frame: CGRect
        let presentation: Presentation
        /// The last standing book on a shelf leans; the copy has to lean with it.
        let leaning: Bool
    }

    /// The book under the finger. Nil between presses, and while the finger is off the shelf.
    var book: Book?
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
        progress = 0
        growth = 1
        isArmed = false
    }
}
