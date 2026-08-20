//
//  ShelfRowView.swift
//  ReCIT_iOS
//
//  One étagère: the watercolour wash, the books (spines or pile), the wooden plank,
//  and a paper label stuck onto the plank's bottom edge carrying the shelf's name.
//
//  Gesture: pressing a book starts growing it; lift early and it peeks and settles back,
//  which is how the gesture advertises itself to someone who only tapped. Hold and selection
//  mode arms (haptic, and the screen blurs around this shelf), after which sliding anywhere
//  moves the growth to the book nearest the finger and lifting opens it. Wander off the card
//  and nothing is selected, so lifting there does nothing. The shelf's own list is reached by
//  pressing its label — which, drawing above the plank, takes the narrow band it overlaps out
//  of the press gesture. Accepted: books stand above the plank. See PRD 0003.
//
//  While a press is on, the pressed book is handed to `ShelfFocusModel` and drawn by
//  `ShelfFocusOverlayView` over the whole app — the card leaves its own copy out. See ADR 0006.
//
//  Sizing is driven entirely by the `width` passed in (the grid cell width) so the
//  view returns a deterministic size — self-measuring here caused a UICollectionView
//  update loop when hosted in a List. See ADR 0003.
//

import SwiftUI

struct ShelfRowView: View {
    let shelf: Shelf
    let width: CGFloat
    @Binding var path: NavigationPath

    @Environment(ShelfFocusModel.self) private var focus

    /// The book under the finger, grown. Nil when nothing is pressed, or when the finger has
    /// wandered off the card.
    @State private var grownIndex: Int?
    /// This card's frame on screen, so the overlay can place the book it redraws. Published
    /// on every layout pass, not only while pressing — otherwise the first press has none.
    @State private var cardFrame: CGRect = .zero
    /// When the finger landed — a short press is a tap, and gets a peek instead of a plain
    /// settle so the press-to-select gesture shows itself.
    @State private var pressStarted: ContinuousClock.Instant?

    /// Size a book reaches once selection mode is on.
    private let fullGrowth: CGFloat = 2
    /// Floor on the exit, so the very briefest tap still reads as a movement.
    private let minimumExit: TimeInterval = 0.12
    /// The book's springiness. Sprung rather than eased so a tap answers at once; an eased
    /// curve starts so slowly that a tap looked like nothing had happened.
    private let bounce: Double = 0.35
    /// The cell's own arrival and departure, softer than the book's.
    private let cellDuration: TimeInterval = 0.3
    private let cellBounce: Double = 0.2

    private var metrics: ShelfCardMetrics { .init(width: width) }
    private var books: [InventoryItem] { ShelfDrawnBooks.from(shelf.items) }
    private var layout: ShelfBooksLayout { .init(books: books, metrics: metrics) }

    /// How far the wash extends below the plank (kept small), so the wash isn't cropped.
    private let washBelow: CGFloat = 16
    /// How far the label's *top* rides up over the plank's bottom edge. Anchored from the
    /// top so a taller label simply extends further down and the inset still holds.
    private let labelOverlap: CGFloat = 14
    /// Room under the label for what it draws outside its own bounds: the shadow reaches
    /// about 5pt below it, and the tilt drops a corner a little further.
    ///
    /// This is not decoration, it is what stops the carousel clipping the paper's lower
    /// edge. A negative top padding shortens the row by exactly what it lifts, so the
    /// label's bottom always lands flush against the card's bottom — raising the overlap
    /// moves that boundary up with it and never opens a gap. Only real height does.
    private let labelBleed: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            shelfStack
                .padding(.top, metrics.topRoom)
            // Inside the stack rather than an overlay: the stack then reserves the label's
            // height at any Dynamic Type size, so planks stay aligned card to card and the
            // carousel's scroll view cannot clip the label's lower half. Self-measuring
            // shelf cards are what caused the collection-view update loop in ADR 0003.
            NavigationLink(value: NavigationDestination.shelf(id: shelf._id)) {
                ShelfLabelView(text: shelf.name, maxWidth: metrics.booksWidth)
            }
            .buttonStyle(.plain)
            .padding(.top, -labelOverlap)
            .padding(.bottom, labelBleed)
            .zIndex(1)
        }
        .frame(width: width)
        // A firmer tick for entering selection mode than for crossing a book.
        .sensoryFeedback(trigger: focus.isArmed) { _, armed in
            armed ? .impact(weight: .medium) : nil
        }
        .sensoryFeedback(.selection, trigger: focus.isArmed ? grownIndex : nil)
    }

    private var shelfStack: some View {
        ZStack(alignment: .bottom) {
            // Wash centred vertically on the plank: constrained to a plank-height box
            // pinned to the bottom, so the (taller) blob overflows equally above the
            // books and below the shelf, with its centre on the plank.
            Image("ShelfWash")
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .offset(y: washBelow)
                .opacity(0.92)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                ShelfBooksView(
                    books: books,
                    metrics: metrics,
                    layout: layout
                )
                // Books always render in FRONT of the plank so they sit on top of the
                // shelf (and a zoomed book stays above it, never behind/under).
                .zIndex(1)
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: metrics.cardHeight)
        // The overlay redraws the pressed book at these screen coordinates.
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            cardFrame = frame
        }
        .overlay(alignment: .bottom) {
            ShelfPressGestureView(
                onPressBegan: startPress,
                onFocusing: focusShelf,
                onArmed: arm,
                onMoved: moveTo,
                onEnded: openGrownBook,
                onCancelled: releasePress
            )
            .frame(width: width, height: metrics.cardHeight)
        }
    }

    /// The book nearest `location` (the card's coordinates), or nil once the finger has
    /// left the étagère.
    private func book(at location: CGPoint) -> Int? {
        guard metrics.touchBox.contains(location) else { return nil }
        let point: CGPoint = .init(
            x: location.x - ShelfCardMetrics.horizontalMargin,
            y: location.y
        )
        guard let index = layout.nearestIndex(to: point), books.indices.contains(index) else { return nil }
        return index
    }

    /// Hands the book at `index` to the overlay, in screen coordinates, dressed the way this
    /// shelf draws it.
    private func publish(_ index: Int?) {
        guard let index, books.indices.contains(index) else {
            focus.book = nil
            return
        }
        let inCard: CGRect = layout.bookFrame(at: index)
            .offsetBy(dx: ShelfCardMetrics.horizontalMargin, dy: ShelfBooksView.booksOffset)
        focus.book = .init(
            item: books[index],
            frame: inCard.offsetBy(dx: cardFrame.minX, dy: cardFrame.minY),
            presentation: presentation(at: index),
            leaning: layout.isLeaning(at: index)
        )
    }

    private func presentation(at index: Int) -> ShelfFocusModel.Presentation {
        switch layout.mode {
        case .singleCover: .cover
        case .allVertical: .standing
        case .mixed(let verticalCount): index < verticalCount ? .standing : .lying
        }
    }

    // MARK: - Press lifecycle

    /// The touch landed: the book under it grows towards full size over the hold, so how
    /// big it is says how close selection mode is.
    private func startPress(at location: CGPoint) {
        pressStarted = .now
        grownIndex = book(at: location)
        focus.growth = 1
        focus.progress = 0
        publish(grownIndex)
        guard grownIndex != nil else { return }
        growUp()
    }

    /// Grows the copy to full size. Deliberately a frame late: a view inserted in the same
    /// transaction as its own animation has no earlier value to travel from, so SwiftUI draws
    /// it at the target — the book snapped straight to ×2 and read as a flash. Publishing
    /// first, animating next frame, is what makes the curve visible at all.
    private func growUp() {
        onNextFrame {
            withAnimation(.spring(duration: ShelfPressRecognizer.holdDuration, bounce: bounce)) {
                focus.growth = fullGrowth
            }
        }
    }

    private func onNextFrame(_ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in work() }
    }

    /// Halfway through the hold: the veil starts coming in, over the rest of the hold. Any
    /// earlier and a single tap would flash the screen.
    private func focusShelf() {
        withAnimation(.easeIn(duration: ShelfPressRecognizer.holdDuration / 2)) {
            focus.progress = 1
        }
    }

    /// The hold completed: selection mode is on and the book's cell slides in above it. The
    /// book itself needs nothing here — the spring started at touch-down lands on full size at
    /// exactly this moment.
    private func arm() {
        withAnimation(.spring(duration: cellDuration, bounce: cellBounce)) { focus.isArmed = true }
    }

    /// The finger came back onto the shelf mid-press: wind selection mode up again. The copy
    /// was handed back when it left, so it is being inserted afresh — hence the same
    /// publish-then-animate order as a new press.
    private func enterFocus() {
        withAnimation(.easeIn(duration: ShelfPressRecognizer.holdDuration / 2)) {
            focus.progress = 1
        }
        growUp()
        withAnimation(.spring(duration: cellDuration, bounce: cellBounce)) { focus.isArmed = true }
    }

    /// Selection mode ends — the finger wandered off the shelf, or lifted. Unwind the way
    /// entering wound up, over `duration`: the mirror of how far the entrance actually got, so
    /// a book that had only begun to grow drops straight back instead of taking the long way.
    private func exitFocus(over duration: TimeInterval) {
        withAnimation(.easeOut(duration: duration / 2)) { focus.progress = 0 }
        withAnimation(.spring(duration: cellDuration, bounce: cellBounce)) { focus.isArmed = false }
        withAnimation(.spring(duration: duration, bounce: bounce)) {
            focus.growth = 1
        } completion: {
            // Unless the finger came back, or moved to another book, in the meantime.
            if grownIndex == nil { focus.book = nil }
        }
    }

    /// Selection mode: the finger moved, so the growth follows it onto another book — or off
    /// the shelf entirely, where nothing is selected.
    private func moveTo(_ location: CGPoint) {
        let index: Int? = book(at: location)
        guard index != grownIndex else { return }
        let wasOnShelf: Bool = grownIndex != nil
        grownIndex = index

        switch (wasOnShelf, index != nil) {
        case (true, true):
            // Book to book. Deliberately unanimated: the finger is picking, and morphing one
            // book's cover and title into the next one's reads as a glitch.
            publish(index)
        case (true, false):
            // Off the shelf: nothing is selected any more, so selection mode unwinds. It was
            // fully wound up, so it unwinds over the whole hold.
            exitFocus(over: ShelfPressRecognizer.holdDuration)
        case (false, true):
            publish(index)
            enterFocus()
        case (false, false):
            break
        }
    }

    /// The finger lifted in selection mode: open whatever it was on, if anything.
    private func openGrownBook() {
        let index: Int? = grownIndex
        pressStarted = nil
        grownIndex = nil
        // Dropped outright rather than animated away: the book detail screen is about to cover
        // this one, and an overlay unwinding on top of it reads as a leftover.
        focus.reset()
        guard let index, books.indices.contains(index) else { return }
        path.append(NavigationDestination.book(anchor: .item(books[index])))
    }

    /// The press ended without opening anything. The exit mirrors how far the entrance got: a
    /// tap that barely started growing settles back just as quickly.
    private func releasePress() {
        let held: Duration = pressStarted.map { ContinuousClock.now - $0 } ?? .zero
        pressStarted = nil
        grownIndex = nil
        exitFocus(over: mirroredExit(of: held))
    }

    /// How long the exit should take: as long as the press lasted, capped at the hold it was
    /// heading for and floored so the briefest tap still reads as a movement.
    private func mirroredExit(of held: Duration) -> TimeInterval {
        let seconds: TimeInterval = .init(held.components.seconds)
            + .init(held.components.attoseconds) / 1e18
        return min(max(seconds, minimumExit), ShelfPressRecognizer.holdDuration)
    }
}
